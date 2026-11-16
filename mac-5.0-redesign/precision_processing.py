"""稳定/去闪仅用SDR代理分析，实际变换与曝光始终写入RGB10。"""

import ctypes
import json
from pathlib import Path

import numpy as np
from core.engine import CPUEngine
from media import FrameCache, check
from model import BY_ID, default_settings, params
from video_color import color_settings


def is_precision(cache):
    """判断真实缓存布局，不以文件扩展名或编码标签猜测。"""
    return cache.meta.get("pixelFormat") == "x2rgb10le"


def transformed(engine, cache, index, width, height, inverse=None, gains=None, preserve=True):
    """按行并行处理单帧，源和目标分离，防止原位稳像覆盖尚未采样的像素。"""
    source = np.ascontiguousarray(cache.data[index])
    output = np.empty((height, width, 4), np.uint8)
    matrix = np.ascontiguousarray(
        inverse
        if inverse is not None
        else [
            [cache.width / width, 0, (cache.width / width - 1) / 2],
            [0, cache.height / height, (cache.height / height - 1) / 2],
        ],
        dtype=np.float32,
    )
    gain = np.ascontiguousarray(np.ones(3) if gains is None else gains, dtype=np.float32)
    settings = color_settings(cache, default_settings(BY_ID[100]))
    p = params(BY_ID[100], settings, cache.width, cache.height, 0, 1, 2)
    fn = engine.lib.transform_precision
    pointer, integer = ctypes.c_void_p, ctypes.c_int
    fn.argtypes = [
        pointer,
        integer,
        integer,
        integer,
        integer,
        integer,
        integer,
        pointer,
        pointer,
        pointer,
        pointer,
        integer,
    ]
    rows = max(8, (height + engine.workers - 1) // engine.workers)
    jobs = [
        engine.pool.submit(
            fn,
            p.ctypes.data,
            cache.width,
            cache.height,
            width,
            height,
            y,
            min(rows, height - y),
            matrix.ctypes.data,
            gain.ctypes.data,
            source.ctypes.data,
            output[y:].ctypes.data,
            int(preserve),
        )
        for y in range(0, height, rows)
    ]
    for job in jobs:
        job.result()
    return output


def analysis_cache(cache, cancel=None):
    """建立低分辨率分析代理；不将代理像素送入正式导出。"""
    existing = getattr(cache, "analysis_proxy", None)
    if existing is not None:
        return existing
    ratio = min(1, 640 / max(cache.width, cache.height))
    width, height = max(2, round(cache.width * ratio)), max(2, round(cache.height * ratio))
    folder = Path(cache.folder) / "precision-analysis"
    folder.mkdir(exist_ok=True)
    metadata = folder / "cache.json"
    if metadata.is_file() and (folder / "frames.rgba").is_file():
        proxy = FrameCache(folder, json.loads(metadata.read_text(encoding="utf-8")))
        cache.analysis_proxy = proxy
        return proxy
    target = np.memmap(
        folder / "frames.rgba", mode="w+", dtype=np.uint8, shape=(len(cache.data), height, width, 4)
    )
    engine = CPUEngine()
    try:
        for i in range(len(cache.data)):
            check(cancel)
            target[i] = transformed(engine, cache, i, width, height, preserve=False)
        target.flush()
    finally:
        engine.close()
        target._mmap.close()
    meta = dict(
        cache.meta,
        width=width,
        height=height,
        pixelFormat="rgba",
        color={"transfer": "bt709", "primaries": "bt709"},
    )
    (folder / "cache.json").write_text(json.dumps(meta, ensure_ascii=False), encoding="utf-8")
    proxy = FrameCache(folder, meta)
    cache.analysis_proxy = proxy
    return proxy


def analysis_pixels(cache, cancel=None):
    """日夜和颜色进度只读代理，正常8位数据沿用原路径。"""
    return analysis_cache(cache, cancel).data if is_precision(cache) else cache.data


def process_precision(cache, options, cancel, notify, process):
    """由原算法取得归一化运动与曝光计划，再应用到真实高精度帧。"""
    proxy = analysis_cache(cache, cancel)
    proxy.capture_precision_plan = True
    report = process(proxy, dict(options, grade=False), cancel, notify)
    if options["stabilize"] == "off" and options["deflicker"] == "off":
        report["precision"] = dict(cacheBits=10, analysisProxyBits=8, formalPixelsFromProxy=False)
        cache.meta["sourceProcessing"] = report
        return report
    plan, correction, chroma, _ = proxy.precision_plan
    target = np.memmap(
        cache.folder / "frames.rgba", mode="r+", dtype=np.uint8, shape=cache.data.shape
    )
    engine = CPUEngine()
    sx, sy = cache.width / proxy.width, cache.height / proxy.height
    scale = np.array([[sx, 0, (sx - 1) / 2], [0, sy, (sy - 1) / 2], [0, 0, 1]], float)
    inv_scale = np.linalg.inv(scale)
    try:
        for i in range(len(cache.data)):
            check(cancel)
            matrix = (
                np.eye(3)
                if plan is None
                else scale @ np.vstack((plan.transforms[i], [0, 0, 1])) @ inv_scale
            )
            inverse = np.linalg.inv(matrix)[:2]
            target[i] = transformed(
                engine,
                cache,
                i,
                cache.width,
                cache.height,
                inverse,
                np.exp2(correction[i] + chroma[i]),
                True,
            )
            notify("应用高精度处理", 0.72 + 0.28 * (i + 1) / len(cache.data))
        target.flush()
    finally:
        engine.close()
        target._mmap.close()
    report["precision"] = dict(cacheBits=10, analysisProxyBits=8, formalPixelsFromProxy=False)
    cache.meta["sourceProcessing"] = report
    (cache.folder / "processing.json").write_text(
        json.dumps(report, ensure_ascii=False), encoding="utf-8"
    )
    return report
