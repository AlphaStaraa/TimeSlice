"""Original PR clip ranges and PNG alpha; never use the simplified project."""

import ctypes
import json

import numpy as np
from core.engine import CPUEngine
from model import BY_ID, MAC42, ROOT, params
from PIL import Image

D = json.loads((ROOT / "resources/PRReference.json").read_text(encoding="utf8"))
SEQ = D["sequences"]
MEDIA = D["media"]
INDEX = {k: {t["index"]: t for t in s["tracks"]} for k, s in SEQ.items()}


# 按原 PR 时间线查找当前素材片段。
def clip(seq, track, t):
    tr = INDEX[seq].get(track)
    if tr is None or tr["muted"]:
        return None
    return next((c for c in tr["clips"] if t >= c["start"] - 1e-8 and t < c["end"] - 1e-8), None)


# 依据时间重映射曲线查找对应源时间。
def mapped(c, t):
    if c["hold"] is not None:
        return c["hold"]
    dt = max(0, t - c["start"]) * c["speed"]
    return (
        max(c["inPoint"], c["outPoint"] - 1 / 60 - dt)
        if c["reverse"]
        else min(c["outPoint"], c["inPoint"] + dt)
    )


# 读取或定位首个有效片段。
def first(seq):
    return min(i for i, tr in INDEX[seq].items() if not tr["muted"] and tr["clips"])


# 把原时间线的时间值转换为归一化取样。
def normalized(c, t, depth=0):
    if not c or depth >= 12:
        return 0
    u = mapped(c, t)
    if c["sourceKind"] == "video":
        return float(np.clip(u / MEDIA[c["sourceID"]]["duration"], 0, 1))
    if c["sourceKind"] == "sequence":
        return normalized(clip(c["sourceID"], first(c["sourceID"]), u), u, depth + 1)
    return 0


# 生成原 PR 对照所需的图层参数。
def layers(seq, t, count, paired):
    result = np.zeros((count, 8), np.float32)
    for i in range(count):
        track = i * 2 if paired else i
        current = clip(seq, track, t)
        v = current or next(iter(INDEX[seq].get(track, {}).get("clips", [])), None)
        if v is None:
            continue
        matte = clip(seq, i * 2 + 1, t) if paired else None
        if paired and not matte:
            matte = next(iter(INDEX[seq].get(i * 2 + 1, {}).get("clips", [])), None)
        m = (
            matte["motion"]
            if matte
            else dict(position=[0.5, 0.5], anchor=[0.5, 0.5], scale=1, rotation=0, rotationKeys=[])
        )
        angle = m["rotation"]
        if m["rotationKeys"]:
            keys = m["rotationKeys"]
            angle = float(
                np.interp(t - matte["start"], [k["time"] for k in keys], [k["value"] for k in keys])
            )
        result[i] = [
            normalized(v, t if current else v["start"]),
            int(current is not None),
            angle,
            m["scale"],
            *m["position"],
            *m["anchor"],
        ]
    return result


# 读取原 PR 时间线结构并整理可用轨道。
def timeline(effect, t):
    key = {0: "rotation", 2: "stripes", 4: "fan", 5: "diamond"}[effect]
    root = D["entries"][key]
    t = min(max(0, t), SEQ[root]["duration"] - 1e-6)
    o = clip(root, 0, t)
    u = mapped(o, t)
    leaf = o["sourceID"]
    if effect == 0:
        return layers(leaf, u, 240, True), 0, 1
    if effect == 2:
        return layers(leaf, u, 100, False), 0, 4
    if effect == 5:
        return layers(leaf, u, 101, True), 0, 3
    base = normalized(clip(leaf, 0, u), u)
    top = clip(leaf, 1, u)
    if not top:
        return np.zeros((61, 8), np.float32), base, 2
    inner = top["sourceID"]
    clock = mapped(top, u)
    middle = clip(inner, first(inner), clock)
    if middle and middle["sourceKind"] == "sequence":
        inner, clock = middle["sourceID"], mapped(middle, clock)
    return layers(inner, clock, 61, True), float(base), 2


class ReferenceRenderer:
    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self, cache):
        self.cache = cache
        self.cpu = CPUEngine()
        self.lib = self.cpu.lib
        self.lib.reference_cpu.argtypes = (
            [ctypes.c_void_p] * 2
            + [ctypes.c_int] * 5
            + [ctypes.c_void_p] * 3
            + [ctypes.c_int] * 2
            + [ctypes.c_float] * 3
        )
        self.masks = {
            k: np.ascontiguousarray(
                Image.open(ROOT / f"resources/Masks/{k}_alpha.png"), dtype=np.uint8
            )
            for k in ("rotation", "fan", "diamond")
        }

    # 按当前时间与效果生成一帧画面。
    def frame(self, e, time, s, view=0):
        duration = 6 if e == 4 else 4
        ls, base, kind = timeline(e, time % duration)
        w, h = self.cache.width, self.cache.height
        key = {1: "rotation", 2: "fan", 3: "diamond"}.get(kind, "rotation")
        mask = self.masks[key]
        out = np.empty((h, w, 4), np.uint8)
        time_scale = self.cache.duration * self.cache.fps
        options = None
        if (
            MAC42
            and view == 0
            and s.get("shadowEnabled", BY_ID[e]["family"] == 0)
            and s.get("shadowStrength", 0.33) > 0
        ):
            options = params(
                BY_ID[e], s, w, h, time / duration, time_scale, len(self.cache.data), view
            )
        ptr = options.ctypes.data if options is not None else None
        jobs = [
            self.cpu.pool.submit(
                self.lib.reference_cpu,
                ls.ctypes.data,
                self.cache.data.ctypes.data,
                w,
                h,
                len(self.cache.data),
                y,
                min(24, h - y),
                mask.ctypes.data,
                out[y:].ctypes.data,
                ptr,
                mask.shape[1],
                mask.shape[0],
                base,
                float(kind + 100 if view == 2 else kind),
                time_scale,
            )
            for y in range(0, h, 24)
        ]
        for j in jobs:
            j.result()
        return out

    # 关闭当前对象持有的资源，避免重复占用文件、线程或设备。
    def close(self):
        self.cpu.close()
