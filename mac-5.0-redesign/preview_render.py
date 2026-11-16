"""Viewport-sized geometry over a small source texture, with live source-time grading."""

import ctypes
from collections import OrderedDict

import numpy as np
from model import params
from video_color import color_settings


class PreviewRenderer:
    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self):
        self.tiles = OrderedDict()
        self.bytes = 0

    # 关闭当前对象持有的资源，避免重复占用文件、线程或设备。
    def close(self):
        for buffer, _ in self.tiles.values():
            buffer.destroy()
        self.tiles.clear()
        self.bytes = 0

    # 按当前时间与效果生成一帧画面。
    def frame(self, engine, cache, e, s, u, size, grade, map_data=None, view=0):
        w, h = size
        n = len(cache.data)
        sw, sh = cache.width, cache.height
        # 源纹理按真实RGB10/PQ/HLG解读，视口始终输出可显示的SDR RGBA8。
        s = color_settings(cache, dict(s, _exportFormat="h264"))
        p = params(e, s, w, h, u, cache.duration * cache.fps, n, view)
        out = np.empty((h, w, 4), np.uint8)
        if engine.kind == "cpu":
            fn = engine.lib.render_preview
            P = ctypes.c_void_p
            CInt = ctypes.c_int
            fn.argtypes = [P, CInt, CInt, CInt, CInt, P, P, CInt, CInt, P, P]
            mp = None if map_data is None else map_data.ctypes.data
            rows = max(8, (h + engine.workers * 2 - 1) // (engine.workers * 2))
            jobs = [
                engine.pool.submit(
                    fn,
                    p.ctypes.data,
                    w,
                    h,
                    y,
                    min(rows, h - y),
                    mp,
                    cache.data.ctypes.data,
                    sw,
                    sh,
                    grade.ctypes.data,
                    out[y:].ctypes.data,
                )
                for y in range(0, h, rows)
            ]
            for job in jobs:
                job.result()
            return out
        flags = p.view(np.uint32)
        flags[31] |= 64 | (128 if grade[0] else 0)
        # Tiles reuse their GPU source upload across effects, grading and playback.
        source_rows = max(2, min(sh, engine.max_buffer // (n * sw * 4)))
        rows = max(1, int((source_rows - 2) * h / sh))
        denominator = 1000000
        with engine.lock:
            for y in range(0, h, rows):
                hh = min(rows, h - y)
                sy = max(0, int(np.floor((y + 0.5) * sh / h - 0.5)))
                bottom = min(sh, int(np.floor((y + hh - 0.5) * sh / h - 0.5)) + 2)
                height = bottom - sy
                key = (id(engine), str(cache.folder), sy, height)
                if key in self.tiles:
                    buffer, used = self.tiles.pop(key)
                    self.tiles[key] = (buffer, used)
                else:
                    data = np.ascontiguousarray(cache.data[:, sy:bottom])
                    used = data.nbytes
                    while self.tiles and self.bytes + used > 384 * 1024**2:
                        old, amount = self.tiles.popitem(last=False)[1]
                        old.destroy()
                        self.bytes -= amount
                    buffer = engine.buffer(data)
                    self.tiles[key] = (buffer, used)
                    self.bytes += used
                mapping = None if map_data is None else np.ascontiguousarray(map_data[y : y + hh])
                cfg = [
                    0,
                    y,
                    w,
                    hh,
                    w,
                    h,
                    n,
                    round(u * denominator),
                    1,
                    denominator,
                    sw,
                    sh,
                    0,
                    sy,
                    sw,
                    height,
                ]
                raw = engine.run(
                    "render",
                    p,
                    cfg,
                    None,
                    mapping,
                    w * hh * 4,
                    grade_data=grade,
                    source_buffer=buffer,
                )
                out[y : y + hh] = np.frombuffer(raw, np.uint8).reshape(hh, w, 4)
        return out
