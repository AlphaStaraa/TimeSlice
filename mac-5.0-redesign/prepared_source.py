"""准备能够直接交给正式导出的全分辨率源缓存；预览只生成轻量副本。"""

import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from media import FrameCache, check
from model import dimensions


def source_key(info, settings, options):
    """把文件身份、输出尺寸、采样精度和稳定去闪档位组合成缓存身份。"""
    path = Path(info["path"]).resolve()
    stat = path.stat()
    w, h = dimensions(info, settings["longEdge"])
    fps = info["fps"] if settings["quality"] == "full" else min(30, info["fps"])
    identity = dict(
        path=str(path),
        size=stat.st_size,
        mtime=stat.st_mtime_ns,
        width=w,
        height=h,
        fps=fps,
        stabilize=options["stabilize"],
        deflicker=options["deflicker"],
        algorithm=54,
    )
    return hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest()


def preview_copy(cache, folder, cancel=None, notify=lambda *_: None):
    """从已处理的正式源缓存缩小预览纹理，绝不再运行稳定或去闪分析。"""
    folder = Path(folder)
    folder.mkdir(parents=True, exist_ok=True)
    scale = min(1.0, 480 / max(cache.width, cache.height))
    w = max(2, round(cache.width * scale))
    h = max(2, round(cache.height * scale))
    n = len(cache.data)
    data = np.memmap(folder / "frames.rgba", mode="w+", dtype=np.uint8, shape=(n, h, w, 4))
    try:
        for i in range(n):
            check(cancel)
            data[i] = cv2.resize(cache.data[i], (w, h), interpolation=cv2.INTER_AREA)
            if i % 12 == 0 or i == n - 1:
                notify("更新预览", (i + 1) / n)
        data.flush()
    finally:
        data._mmap.close()
    meta = dict(cache.meta, width=w, height=h)
    (folder / "cache.json").write_text(json.dumps(meta, ensure_ascii=False), encoding="utf-8")
    return FrameCache(folder, meta)


def reopen(descriptor, key):
    """仅当缓存身份与当前请求完全相同时，打开独立的只读租约供导出使用。"""
    if not descriptor or descriptor.get("key") != key:
        return None
    folder = Path(descriptor["folder"])
    if not (folder / "cache.json").is_file():
        return None
    meta = json.loads((folder / "cache.json").read_text(encoding="utf-8"))
    if meta.get("preparedKey") != key:
        return None
    expected = meta["width"] * meta["height"] * meta["frames"] * 4
    if (
        not (folder / "frames.rgba").is_file()
        or (folder / "frames.rgba").stat().st_size != expected
    ):
        return None
    return FrameCache(folder, meta)
