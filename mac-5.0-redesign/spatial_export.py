"""长源按空间块完成时间轴，避免每批输出重新整理和上传整段原片。"""

import math
import mmap
import os
import shutil
import struct
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np
from media import check
from model import dimensions, duration
from render import gpu_tile

STAGING_GROUP_BYTES = 256 * 1024**2
SOURCE_PARALLEL_BYTES = 64 * 1024**2


def pack_source_tile(cache, x, y, width, height, pool, workers, cancel):
    """大源块按互不重叠的时间段并行整理，保持帧序与原始像素不变。"""
    view = cache.data[:, y : y + height, x : x + width]
    if workers < 2 or view.nbytes < SOURCE_PARALLEL_BYTES:
        return np.ascontiguousarray(view)
    output = np.empty(view.shape, dtype=view.dtype)
    step = math.ceil(len(view) / workers)
    pending = [
        pool.submit(np.copyto, output[first : first + step], view[first : first + step])
        for first in range(0, len(view), step)
    ]
    for future in pending:
        future.result()
        check(cancel)
    return output


def workspace_root(job):
    """优先系统缓存目录；长片空间不足时使用用户已选的输出盘，保留源文件。"""
    first = job.jobs[0][1]
    width, height = dimensions(job.info, first["longEdge"])
    fps = job.info["fps"] if first["quality"] == "full" else min(30, job.info["fps"])
    source_bytes = math.ceil(job.info["duration"] * max(1, fps)) * width * height * 4
    output_bytes = max(
        0
        if settings["engine"] == "cpu" or settings.get("reference")
        else round(duration(effect, settings) * settings["fps"]) * width * height * 4
        for effect, settings in job.jobs
    )
    candidates = (job.cache_root, job.output)
    for required in (source_bytes + output_bytes, source_bytes):
        for folder in candidates:
            if shutil.disk_usage(folder).free > required + 512 * 1024**2:
                return folder
    return job.cache_root


def use_spatial_cache(cache, total, folder, resident_budget=0):
    """重复搬运显著大于临时成片读写且空间足够时启用，短源保留流式路径。"""
    if cache.data.nbytes <= resident_budget:
        return False
    frame_bytes = cache.width * cache.height * 4
    batch = max(1, min(120, (512 * 1024**2) // frame_bytes))
    repeated = cache.data.nbytes * max(0, math.ceil(total / batch) - 1)
    output_bytes = total * frame_bytes
    return repeated > output_bytes * 4 and shutil.disk_usage(folder).free > (
        output_bytes + 512 * 1024**2
    )


def spatial_frames(job, engine, cache, effect, settings, total, mapping, index, detail):
    """按有界时间组存放空间块，源只上传一次，编码连续读取最多256MiB。"""
    max_frames = min(total, engine.device.limits["max-compute-workgroups-per-dimension"])
    columns, rows = gpu_tile(
        cache.width, cache.height, max(max_frames, len(cache.data)), engine.max_buffer
    )
    tiles = math.ceil(cache.width / columns) * math.ceil(cache.height / rows)
    job.effect_pipeline = "spatial-cache"
    frame_bytes = cache.width * cache.height * 4
    slab_frames = max(1, min(16, STAGING_GROUP_BYTES // frame_bytes))
    job.output_staging_bytes = total * frame_bytes
    if getattr(job, "profiling", False):
        job.timings["outputStagingBytes"] += job.output_staging_bytes
    workers = max(1, min(4, os.cpu_count() or 1, getattr(job, "source_pack_workers", 4)))
    with (
        ThreadPoolExecutor(max_workers=workers) as source_pool,
        tempfile.TemporaryDirectory(
            prefix="spatial_", dir=getattr(job, "working_cache_root", job.cache_root)
        ) as folder,
    ):
        pieces = []
        try:
            path = Path(folder) / "output.rgba"
            with path.open("w+b") as stream:
                allocate_output(stream, job.output_staging_bytes)
                done = 0
                tile_offset = 0
                for y in range(0, cache.height, rows):
                    for x in range(0, cache.width, columns):
                        check(job.cancel)
                        width, height = min(columns, cache.width - x), min(rows, cache.height - y)
                        started = time.perf_counter()
                        data = pack_source_tile(
                            cache,
                            x,
                            y,
                            width,
                            height,
                            source_pool,
                            workers,
                            job.cancel,
                        )
                        if getattr(job, "profiling", False):
                            job.timings["sourcePacking"] += time.perf_counter() - started
                        with engine.lock:
                            source = engine.buffer(data)
                        del data
                        if job.output_staging_bytes > 4 * 1024**3:
                            started = time.perf_counter()
                            release_source_tile(cache, x, y, width, height)
                            if getattr(job, "profiling", False):
                                job.timings["sourcePageRelease"] += time.perf_counter() - started
                        try:
                            for first in range(0, total, max_frames):
                                check(job.cancel)
                                count = min(max_frames, total - first)
                                frames = engine.export_batch(
                                    cache,
                                    effect,
                                    settings,
                                    x,
                                    y,
                                    width,
                                    height,
                                    first,
                                    count,
                                    total,
                                    mapping,
                                    source_buffer=source,
                                )
                                started = time.perf_counter()
                                position = first
                                tile_bytes = width * height * 4
                                while position < first + count:
                                    check(job.cancel)
                                    slab_start = position // slab_frames * slab_frames
                                    slab_count = min(slab_frames, total - slab_start)
                                    length = min(
                                        first + count - position, slab_start + slab_count - position
                                    )
                                    stream.seek(
                                        slab_start * frame_bytes
                                        + slab_count * tile_offset
                                        + (position - slab_start) * tile_bytes
                                    )
                                    stream.write(
                                        memoryview(
                                            frames[position - first : position - first + length]
                                        )
                                    )
                                    position += length
                                if getattr(job, "profiling", False):
                                    job.timings["outputTileWrite"] += time.perf_counter() - started
                                del frames
                        finally:
                            source.destroy()
                        done += 1
                        pieces.append((x, y, width, height, tile_offset))
                        tile_offset += width * height * 4
                        job.update(index, "切片合成", 0.85 * done / tiles, detail)
            assert path.stat().st_size == job.output_staging_bytes
            release_source_pages(cache)
            with path.open("rb") as stream:
                for first in range(0, total, slab_frames):
                    check(job.cancel)
                    count = min(slab_frames, total - first)
                    started = time.perf_counter()
                    data = stream.read(count * frame_bytes)
                    if len(data) != count * frame_bytes:
                        raise ValueError("成片工作缓存不完整")
                    if getattr(job, "profiling", False):
                        job.timings["outputSlabRead"] += time.perf_counter() - started
                    views = [
                        (x, y, np.ndarray((count, h, w, 4), np.uint8, data, count * offset))
                        for x, y, w, h, offset in pieces
                    ]
                    for frame in range(count):
                        check(job.cancel)
                        started = time.perf_counter()
                        image = np.empty((cache.height, cache.width, 4), np.uint8)
                        for x, y, tile in views:
                            image[y : y + tile.shape[1], x : x + tile.shape[2]] = tile[frame]
                        del tile
                        if getattr(job, "profiling", False):
                            job.timings["outputFrameAssemble"] += time.perf_counter() - started
                        yield image
                        job.update(
                            index, "合成与编码", 0.85 + 0.11 * (first + frame + 1) / total, detail
                        )
                    views.clear()
                    del data
        finally:
            pieces.clear()


def allocate_output(stream, size):
    """可用时提前分配临时文件空间，减少大文件随机写入时的反复扩展。"""
    try:
        if sys.platform == "darwin":
            import fcntl

            # fstore_t: 分配所有所需空间，从文件末尾开始；不申请系统权限。
            fcntl.fcntl(stream.fileno(), 42, struct.pack("=Iiqqq", 4, 3, 0, size, 0))
        elif hasattr(os, "posix_fallocate"):
            os.posix_fallocate(stream.fileno(), 0, size)
    except OSError:
        pass
    stream.truncate(size)


def release_source_pages(cache):
    """计算结束后允许系统回收源映射的只读页面；文件和解码缓存仍保留。"""
    source_map = getattr(cache.data, "_mmap", None)
    if source_map is not None and hasattr(source_map, "madvise"):
        try:
            source_map.madvise(mmap.MADV_DONTNEED)
        except (OSError, ValueError, AttributeError):
            pass


def release_source_tile(cache, x, y, width, height):
    """源块上传后降低已读只读页面的驻留，给临时成片留出文件缓存空间。"""
    data = cache.data
    source_map = getattr(data, "_mmap", None)
    if (
        x != 0
        or width != cache.width
        or getattr(data, "mode", None) != "r"
        or getattr(data, "offset", 0) != 0
        or not data.flags.c_contiguous
        or source_map is None
        or not hasattr(source_map, "madvise")
    ):
        return
    page = mmap.PAGESIZE
    frame_bytes = cache.width * cache.height * 4
    start = y * cache.width * 4
    length = height * cache.width * 4
    size = len(source_map)
    try:
        for frame in range(len(data)):
            offset = frame * frame_bytes + start
            low = offset // page * page
            high = min(size, (offset + length + page - 1) // page * page)
            source_map.madvise(mmap.MADV_DONTNEED, low, high - low)
    except (OSError, ValueError, AttributeError):
        return
