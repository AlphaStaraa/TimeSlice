"""共享切片与流式编码，在小源上批量提交 GPU 帧并复用源上传。"""

import json
import math
import time
from collections import defaultdict

import numpy as np
from export_pipeline import StreamingExport
from media import check
from model import params
from render import RenderJob, gpu_tile
from render_budget import source_cache_budget
from source_tiles import source_tiles
from spatial_export import spatial_frames, use_spatial_cache


class LiteRenderJob(StreamingExport, RenderJob):
    report_encoding = True

    def __init__(self, *args, store, order=(), profiling=False, **kwargs):
        """按可视化顺序输出，持有解码缓存管理器而非照片处理流水线。"""
        super().__init__(*args, **kwargs)
        self.profiling = profiling
        self.timings = defaultdict(float)
        self.store = store
        self.cache_reused = False
        rank = {eid: index for index, eid in enumerate(order)}
        self.jobs.sort(key=lambda item: rank.get(item[0]["id"], len(rank)))

    def prepare_cache(self, first, workspace, root):
        """只做视频解码，不执行完整版本的曝光、稳定或颜色分析。"""
        started = time.perf_counter()
        cache, self.cache_reused = self.store.acquire(
            self.info, first, self.cancel, self.update, folder_root=self.working_cache_root
        )
        self.timings["sourcePreparation"] += time.perf_counter() - started
        return cache

    def create_engine(self, first):
        """性能分析按阶段计时，正常导出不安装分析包装。"""
        started = time.perf_counter()
        engine = super().create_engine(first)
        self.timings["engineInitialization"] += time.perf_counter() - started
        if self.profiling and engine.kind == "gpu":
            original_run, original_buffer = engine.run, engine.buffer

            def measured_run(*args, **kwargs):
                """记录GPU提交与回读的合计时间，不误报为纯核函数耗时。"""
                start = time.perf_counter()
                try:
                    return original_run(*args, **kwargs)
                finally:
                    self.timings["gpuRunIncludingUploadAndReadback"] += time.perf_counter() - start
                    self.timings["gpuDispatchCalls"] += 1

            def measured_buffer(data, uniform=False):
                """独立记录时域RGBA源块上传调用的耗时与次数。"""
                source = getattr(data, "ndim", 0) == 4
                start = time.perf_counter()
                try:
                    return original_buffer(data, uniform)
                finally:
                    if source:
                        self.timings["sourceBufferCreation"] += time.perf_counter() - start
                        self.timings["sourceUploadCalls"] += 1
                        self.timings["sourceUploadBytes"] += data.nbytes

            engine.run, engine.buffer = measured_run, measured_buffer
        return engine

    def run(self):
        """分析仅在显式启用时写旁路JSON，不改变参数或输出精度。"""
        started = time.perf_counter()
        output = super().run()
        if self.profiling:
            self.timings["total"] = time.perf_counter() - started
            (output / "性能分解.json").write_text(
                json.dumps(dict(self.timings), indent=2), encoding="utf-8"
            )
        return output

    def stream_frames(self, *args):
        """区分合成生成器与编码管道等待，不把它们混成一个速度数字。"""
        if not self.profiling:
            yield from self.render_frames(*args)
            return
        frames = iter(self.render_frames(*args))
        while True:
            started = time.perf_counter()
            try:
                image = next(frames)
            except StopIteration:
                return
            self.timings["frameGeneration"] += time.perf_counter() - started
            started = time.perf_counter()
            yield image
            self.timings["encodingPipeConsumer"] += time.perf_counter() - started

    def frame_data(self, image):
        """连续 RGBA 帧直接交给管道，省去逐帧 tobytes 的整帧内存复制。"""
        return memoryview(image if image.flags.c_contiguous else np.ascontiguousarray(image))

    def render_frames(self, engine, cache, effect, settings, total, mapping, index, detail):
        """显存允许时批量合成并只上传一次；大素材沿用经过验证的分块路径。"""
        if engine.kind != "gpu":
            yield from super().stream_frames(
                engine, cache, effect, settings, total, mapping, index, detail
            )
            return
        if cache.data.nbytes > engine.max_buffer * 0.8:
            yield from self.tiled_frames(
                engine, cache, effect, settings, total, mapping, index, detail
            )
            return
        width, height = cache.width, cache.height
        budget = min(64 * 1024**2, int(engine.max_buffer * 0.5))
        batch = max(1, min(16, budget // (width * height * 4)))
        denominator = (
            max(1, total - 1) if settings.get("dayNightSplit") and effect["family"] == 0 else total
        )
        p = params(effect, settings, width, height, 0, cache.duration * cache.fps, len(cache.data))
        key = ("lite-resident", str(cache.folder), width, height)
        for first in range(0, total, batch):
            check(self.cancel)
            count = min(batch, total - first)
            with engine.lock:
                source = None if engine.resident and engine.resident[0] == key else cache.data
                raw = engine.run(
                    "render",
                    p,
                    [
                        0,
                        0,
                        width,
                        height,
                        width,
                        height,
                        len(cache.data),
                        first,
                        count,
                        denominator,
                        0,
                        0,
                    ],
                    source,
                    mapping,
                    count * width * height * 4,
                    resident_key=key,
                )
            images = np.frombuffer(raw, np.uint8).reshape(count, height, width, 4)
            for offset, image in enumerate(images):
                check(self.cancel)
                yield image
                self.update(index, "合成与编码", 0.96 * (first + offset + 1) / total, detail)

    def tiled_frames(self, engine, cache, effect, settings, total, mapping, index, detail):
        """保持既有分块尺寸；有可靠设备预算时，源块只上传一次并按时间批次复用。"""
        batch = max(1, min(total, 120, (512 * 1024**2) // (cache.width * cache.height * 4)))
        columns, rows = gpu_tile(
            cache.width, cache.height, max(batch, len(cache.data)), engine.max_buffer
        )
        tile_count = math.ceil(cache.width / columns) * math.ceil(cache.height / rows)
        budget = source_cache_budget()
        if use_spatial_cache(
            cache, total, getattr(self, "working_cache_root", self.cache_root), budget
        ):
            yield from spatial_frames(
                self, engine, cache, effect, settings, total, mapping, index, detail
            )
            return
        with source_tiles(engine, cache, columns, rows, budget, self.cancel) as cached:
            if self.profiling:
                self.timings["sourceCacheBudgetBytes"] = budget
                self.timings["cachedSourceTiles"] = len(cached)
                self.timings["outputBatchFrames"] = batch
                self.timings["tileColumns"], self.timings["tileRows"] = columns, rows
            for first in range(0, total, batch):
                check(self.cancel)
                count = min(batch, total - first)
                frames = np.empty((count, cache.height, cache.width, 4), np.uint8)
                done = 0
                for y in range(0, cache.height, rows):
                    for x in range(0, cache.width, columns):
                        check(self.cancel)
                        width, height = min(columns, cache.width - x), min(rows, cache.height - y)
                        frames[:, y : y + height, x : x + width] = engine.export_batch(
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
                            source_buffer=cached.get((x, y)),
                        )
                        done += 1
                        self.update(
                            index,
                            "切片合成",
                            0.96 * (first + count * 0.85 * done / tile_count) / total,
                            detail,
                        )
                for frame, image in enumerate(frames, first + 1):
                    check(self.cancel)
                    yield image
                    self.update(index, "合成与编码", 0.96 * frame / total, detail)
