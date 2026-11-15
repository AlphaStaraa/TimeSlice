"""有界复用时域源块，取消、提前关闭或内存不足时释放已申请的显存。"""

from contextlib import contextmanager

import numpy as np
from media import check


@contextmanager
def source_tiles(engine, cache, columns, rows, budget, cancel):
    """预算可容纳完整源时才预上传；内存不足回到原分块路径，设备错误仍上报。"""
    buffers = {}
    try:
        if cache.data.nbytes <= budget:
            try:
                for y in range(0, cache.height, rows):
                    for x in range(0, cache.width, columns):
                        check(cancel)
                        width = min(columns, cache.width - x)
                        height = min(rows, cache.height - y)
                        with engine.lock:
                            buffers[(x, y)] = engine.buffer(
                                np.ascontiguousarray(cache.data[:, y : y + height, x : x + width])
                            )
            except (MemoryError, engine.wgpu.GPUOutOfMemoryError):
                for buffer in buffers.values():
                    buffer.destroy()
                buffers.clear()
        check(cancel)
        yield buffers
    finally:
        for buffer in buffers.values():
            buffer.destroy()
