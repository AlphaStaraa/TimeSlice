import ctypes
import json
import os
import sys
import threading
import zlib
from concurrent.futures import ThreadPoolExecutor

import numpy as np
from model import MAC42, ROOT, params
from video_color import color_settings

P = ctypes.c_void_p
CInt = ctypes.c_int


class CPUEngine:
    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self):
        name = {"win32": "timefield.dll", "darwin": "libtimefield.dylib"}.get(
            sys.platform, "libtimefield.so"
        )
        self.lib = ctypes.CDLL(str(ROOT / "native" / name))
        self.lib.fields.argtypes = [P, CInt, CInt, CInt, CInt, P, P]
        self.lib.render_cpu.argtypes = [P, CInt, CInt, CInt, CInt, P, P, P]
        assert self.lib.params_size() == (176 if MAC42 else 128)
        available = getattr(os, "process_cpu_count", os.cpu_count)() or 1
        self.workers = max(1, min(32, available))
        self.pool = ThreadPoolExecutor(self.workers)
        self.label = f"CPU · {self.workers} 线程"
        self.kind = "cpu"

    # 计算逐像素的时间、混合权重与采样坐标。
    def field(self, p, w, h, map_data=None):
        out = np.empty((h, w, 8), np.float32)
        mp = map_data.ctypes.data if map_data is not None else None
        jobs = [
            self.pool.submit(
                self.lib.fields, p.ctypes.data, w, h, y, min(32, h - y), mp, out[y:].ctypes.data
            )
            for y in range(0, h, 32)
        ]
        for j in jobs:
            j.result()
        return out

    # 按当前时间与效果生成一帧画面。
    def frame(self, cache, e, s, u, map_data=None, view=0):
        w, h = cache.width, cache.height
        s = color_settings(cache, s)
        p = params(e, s, w, h, u, cache.duration * cache.fps, len(cache.data), view)
        out = np.empty((h, w, 4), np.uint8)
        mp = map_data.ctypes.data if map_data is not None else None
        grade = getattr(cache, "live_grade", None)
        if grade is not None and grade[0] and hasattr(self.lib, "render_preview"):
            fn = self.lib.render_preview
            fn.argtypes = [P, CInt, CInt, CInt, CInt, P, P, CInt, CInt, P, P]
            rows = max(8, (h + self.workers * 2 - 1) // (self.workers * 2))
            jobs = [
                self.pool.submit(
                    fn,
                    p.ctypes.data,
                    w,
                    h,
                    y,
                    min(rows, h - y),
                    mp,
                    cache.data.ctypes.data,
                    w,
                    h,
                    grade.ctypes.data,
                    out[y:].ctypes.data,
                )
                for y in range(0, h, rows)
            ]
            for job in jobs:
                job.result()
            return out
        rows = max(16, (h + self.workers * 2 - 1) // (self.workers * 2)) if MAC42 else 32
        jobs = [
            self.pool.submit(
                self.lib.render_cpu,
                p.ctypes.data,
                w,
                h,
                y,
                min(rows, h - y),
                mp,
                cache.data.ctypes.data,
                out[y:].ctypes.data,
            )
            for y in range(0, h, rows)
        ]
        for j in jobs:
            j.result()
        return out

    # 关闭当前对象持有的资源，避免重复占用文件、线程或设备。
    def close(self):
        self.pool.shutdown(wait=True)


class GPUEngine:
    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self):
        if os.environ.get("TIMESLICE_FORCE_CPU") == "1":
            raise RuntimeError("已选择 CPU 兼容模式")
        import wgpu

        self.wgpu = wgpu
        adapter = wgpu.gpu.request_adapter_sync(power_preference="high-performance")
        self.info = dict(adapter.info)
        if self.info.get("adapter_type", "").lower() in ("cpu", "software"):
            raise RuntimeError("检测到软件图形适配器，使用多核 CPU")
        self.device = adapter.request_device_sync(
            required_limits={
                "max-storage-buffer-binding-size": min(
                    adapter.limits["max-storage-buffer-binding-size"], 512 * 1024 * 1024
                ),
                "max-buffer-size": min(adapter.limits["max-buffer-size"], 1024 * 1024 * 1024),
            }
        )
        self.max_buffer = self.device.limits["max-storage-buffer-binding-size"]
        self.label = f"GPU · {self.info.get('device', self.info.get('description', '未知显卡'))}"
        self.kind = "gpu"
        self.pipelines = {}
        for entry in ["render", "fields"]:
            packed_shader = ROOT / "core" / f"{entry}.shader"
            code = (
                zlib.decompress(packed_shader.read_bytes()).decode("utf8")
                if packed_shader.is_file()
                else packed_shader.with_suffix(".wgsl").read_text(encoding="utf-8")
            )
            shader = self.device.create_shader_module(code=code)
            self.pipelines[entry] = self.device.create_compute_pipeline(
                layout="auto", compute={"module": shader, "entry_point": entry}
            )
        self.lock = threading.Lock()
        self.resident = None
        self.live_grade = json.loads(
            (ROOT / "resources/release.json").read_text(encoding="utf-8")
        ).get("gpuGrade", False)

    # 把参数或像素数据上传到合适的 GPU 缓冲区。
    def buffer(self, data, uniform=False):
        W = self.wgpu
        return self.device.create_buffer_with_data(
            data=data,
            usage=(W.BufferUsage.UNIFORM if uniform else W.BufferUsage.STORAGE)
            | W.BufferUsage.COPY_DST,
        )

    # 执行当前任务的主流程并把结果或失败交给调用方。
    def run(
        self,
        entry,
        p,
        cfg,
        src,
        map_data,
        output_size,
        resident_key=None,
        grade_data=None,
        source_buffer=None,
    ):
        # Upload only a spatial tile across time. The device's binding limit is enforced by caller.
        W = self.wgpu
        d = self.device
        bufs = []
        try:
            b0 = self.buffer(p, True)
            b1 = self.buffer(np.array(cfg, np.uint32))
            b3 = self.buffer(
                map_data if map_data is not None else np.zeros(cfg[2] * cfg[3], np.float32)
            )
            bufs = [b0, b1, b3]
            out = d.create_buffer(
                size=output_size, usage=W.BufferUsage.STORAGE | W.BufferUsage.COPY_SRC
            )
            bufs.append(out)
            entries = [
                {"binding": 0, "resource": {"buffer": b0}},
                {"binding": 1, "resource": {"buffer": b1}},
                {"binding": 3, "resource": {"buffer": b3}},
            ]
            if entry == "render":
                if source_buffer is not None:
                    b2 = source_buffer
                elif resident_key is not None:
                    if self.resident is None or self.resident[0] != resident_key:
                        if self.resident:
                            self.resident[1].destroy()
                        self.resident = (resident_key, self.buffer(src))
                    b2 = self.resident[1]
                else:
                    b2 = self.buffer(src)
                    bufs.append(b2)
                entries.extend(
                    [
                        {"binding": 2, "resource": {"buffer": b2}},
                        {"binding": 4, "resource": {"buffer": out}},
                    ]
                )
                if self.live_grade:
                    b6 = self.buffer(
                        grade_data if grade_data is not None else np.zeros(16, np.float32)
                    )
                    bufs.append(b6)
                    entries.append({"binding": 6, "resource": {"buffer": b6}})
            else:
                entries.append({"binding": 5, "resource": {"buffer": out}})
            pipe = self.pipelines[entry]
            group = d.create_bind_group(layout=pipe.get_bind_group_layout(0), entries=entries)
            enc = d.create_command_encoder()
            pas = enc.begin_compute_pass()
            pas.set_pipeline(pipe)
            pas.set_bind_group(0, group)
            pas.dispatch_workgroups(
                (cfg[2] + 7) // 8, (cfg[3] + 7) // 8, cfg[8] if entry == "render" else 1
            )
            pas.end()
            d.queue.submit([enc.finish()])
            raw = d.queue.read_buffer(out)
            return raw if MAC42 else bytes(raw)
        finally:
            for b in bufs:
                b.destroy()

    # 计算逐像素的时间、混合权重与采样坐标。
    def field(self, p, w, h, map_data=None):
        out = np.empty((h, w, 8), np.float32)
        rows = max(1, min(h, self.max_buffer // (w * 32)))
        with self.lock:
            for y in range(0, h, rows):
                hh = min(rows, h - y)
                m = None if map_data is None else np.ascontiguousarray(map_data[y : y + hh])
                raw = self.run(
                    "fields", p, [0, y, w, hh, w, h, 1, 0, 1, 1, 0, 0], None, m, w * hh * 32
                )
                out[y : y + hh] = np.frombuffer(raw, np.float32).reshape(hh, w, 8)
        return out

    # 按当前时间与效果生成一帧画面。
    def frame(self, cache, e, s, u, map_data=None, view=0):
        # 单帧预览使用独立上传；正式导出按分块批处理复用源数据。
        if e["id"] == 406 and view == 0:
            p = params(
                e,
                s,
                cache.width,
                cache.height,
                u,
                cache.duration * cache.fps,
                len(cache.data),
                view,
            )
            return sample_fields(cache, self.field(p, cache.width, cache.height, map_data))
        w, h = cache.width, cache.height
        s = color_settings(cache, s)
        p = params(e, s, w, h, u, cache.duration * cache.fps, len(cache.data), view)
        grade = getattr(cache, "live_grade", None)
        if grade is not None and grade[0]:
            p.view(np.uint32)[31] |= 128
        out = np.empty((h, w, 4), np.uint8)
        rows = max(1, min(h, self.max_buffer // max(1, len(cache.data) * w * 4)))
        # u must not be overwritten by a low-resolution frame index.
        denom = 1000000
        frame = int(round(u * denom))
        with self.lock:
            for y in range(0, h, rows):
                hh = min(rows, h - y)
                key = (str(cache.folder), y, hh)
                src = (
                    None
                    if MAC42 and self.resident and self.resident[0] == key
                    else np.ascontiguousarray(cache.data[:, y : y + hh])
                )
                m = None if map_data is None else np.ascontiguousarray(map_data[y : y + hh])
                raw = self.run(
                    "render",
                    p,
                    [0, y, w, hh, w, h, len(cache.data), frame, 1, denom, 0, 0],
                    src,
                    m,
                    w * hh * 4,
                    key,
                    grade_data=grade,
                )
                out[y : y + hh] = np.frombuffer(raw, np.uint8).reshape(hh, w, 4)
        return out

    def export_batch(
        self,
        cache,
        e,
        s,
        x,
        y,
        w,
        h,
        first,
        count,
        total,
        map_data=None,
        view=0,
        source_buffer=None,
    ):
        """对一段输出帧范围进行空间分块合成，复用实时调色方程。"""
        s = color_settings(cache, s)
        p = params(
            e, s, cache.width, cache.height, 0, cache.duration * cache.fps, len(cache.data), view
        )
        grade = getattr(cache, "live_grade", None)
        if grade is not None and grade[0]:
            p.view(np.uint32)[31] |= 128
        src = (
            None
            if source_buffer is not None
            else np.ascontiguousarray(cache.data[:, y : y + h, x : x + w])
        )
        m = None if map_data is None else np.ascontiguousarray(map_data[y : y + h, x : x + w])
        with self.lock:
            raw = self.run(
                "render",
                p,
                [
                    x,
                    y,
                    w,
                    h,
                    cache.width,
                    cache.height,
                    len(cache.data),
                    first,
                    count,
                    max(1, total - 1) if s.get("dayNightSplit") and e["family"] == 0 else total,
                    0,
                    0,
                ],
                src,
                m,
                count * w * h * 4,
                grade_data=grade,
                source_buffer=source_buffer,
            )
        return np.frombuffer(raw, np.uint8).reshape(count, h, w, 4)

    def export_tile(self, cache, e, s, x, y, w, h, frame_count, map_data=None, view=0):
        """保留既有全时段接口，统一委托给可分批的 GPU 合成实现。"""
        return self.export_batch(
            cache, e, s, x, y, w, h, 0, frame_count, frame_count, map_data, view
        )

    # 关闭当前对象持有的资源，避免重复占用文件、线程或设备。
    def close(self):
        if self.resident:
            self.resident[1].destroy()
            self.resident = None
        self.device.destroy()


# 根据时间场进行空间和时间插值，合成最终像素。
def sample_fields(cache, field):
    # 折页使用空间坐标变换，GPU 继续求解对应的透视和时间场。
    n, h, w, _ = cache.data.shape

    # 获取所需输入或数据片段，交给后续处理。
    def fetch(t, uv):
        f = np.clip(t * cache.duration * cache.fps, 0, n - 1)
        lo = f.astype(np.int32)
        hi = np.minimum(lo + 1, n - 1)
        a = (f - lo)[..., None]
        xx = np.clip(uv[..., 0] * w - 0.5, 0, w - 1)
        yy = np.clip(uv[..., 1] * h - 0.5, 0, h - 1)
        x = xx.astype(np.int32)
        y = yy.astype(np.int32)
        x1 = np.minimum(x + 1, w - 1)
        y1 = np.minimum(y + 1, h - 1)
        fx = (xx - x)[..., None]
        fy = (yy - y)[..., None]

        # 读取指定位置的数据或中间值。
        def at(i):
            return (cache.data[i, y, x] * (1 - fx) + cache.data[i, y, x1] * fx) * (1 - fy) + (
                cache.data[i, y1, x] * (1 - fx) + cache.data[i, y1, x1] * fx
            ) * fy

        return at(lo) * (1 - a) + at(hi) * a

    a = fetch(field[..., 0], field[..., 4:6])
    b = fetch(field[..., 1], field[..., 6:8])
    b[..., :3] *= field[..., 3:4]
    t = field[..., 2:3]
    out = np.rint(np.clip(a * (1 - t) + b * t, 0, 255)).astype(np.uint8)
    out[..., 3] = 255
    return out
