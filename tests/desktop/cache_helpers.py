"""仅供回归测试复制缓存；不进入发布应用。"""

import json
import shutil
from copy import deepcopy
from pathlib import Path

import numpy as np
from media import FrameCache, check


# 仅在测试中复制帧缓存，保持被测原始缓存不变。
def copy_cache(cache, folder, cancel=None):
    folder = Path(folder)
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / "frames.rgba"
    needed = cache.data.nbytes
    if shutil.disk_usage(folder).free < needed + 256 * 1024**2:
        raise ValueError("素材处理缓存空间不足")
    dest = np.memmap(path, mode="w+", dtype=np.uint8, shape=cache.data.shape)
    try:
        for i in range(len(cache.data)):
            check(cancel)
            dest[i] = cache.data[i]
        dest.flush()
    finally:
        dest._mmap.close()
    meta = deepcopy(cache.meta)
    (folder / "cache.json").write_text(json.dumps(meta, ensure_ascii=False))
    return FrameCache(folder, meta)
