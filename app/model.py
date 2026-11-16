import json
import math
import sys
from pathlib import Path

import numpy as np

ROOT = (
    Path(sys._MEIPASS) / "app" if getattr(sys, "frozen", False) else Path(__file__).resolve().parent
)
EFFECTS = json.loads((ROOT / "resources/effects.json").read_text(encoding="utf8"))
MAC42 = (ROOT / "resources/mac42.json").is_file()
if MAC42:
    EFFECTS = [e for e in EFFECTS if e["id"] not in (405, 406)]
    for effect in EFFECTS:
        if effect["family"] == 2:
            effect["duration"] = 4
    EFFECTS.extend(json.loads((ROOT / "resources/mac42.json").read_text(encoding="utf8")))
BY_ID = {e["id"]: e for e in EFFECTS}
FAMILIES = ["冻结展开", "时间切片", "时间切片", "创意实验"]
TIME_GROUPS = json.loads((ROOT / "resources/catalogue.json").read_text(encoding="utf8"))
GROUP_BY_EFFECT = {v["effect"]: g for g in TIME_GROUPS for v in g["variants"]}


# 确定原始效果所属形状组，独立效果统一包装为单项。
def effect_group(effect):
    if effect["id"] in GROUP_BY_EFFECT:
        return GROUP_BY_EFFECT[effect["id"]]
    return dict(
        key=effect["key"],
        name=effect["name"],
        default=effect["id"],
        variants=[dict(effect=effect["id"], motion="", orientation="")],
    )


# 在形状组中查找指定原始效果的运动与方向配置。
def group_variant(group, eid):
    return next(v for v in group["variants"] if v["effect"] == eid)


# 按原始顺序返回当前形状支持的运动类型。
def group_motions(group):
    return list(dict.fromkeys(v["motion"] for v in group["variants"]))


# 返回指定运动下支持的排列方向。
def group_orientations(group, motion):
    return list(dict.fromkeys(v["orientation"] for v in group["variants"] if v["motion"] == motion))


# 按分类返回供效果库展示的形状组。
def library_groups(family):
    if family in (1, 2):
        return TIME_GROUPS
    return [effect_group(e) for e in EFFECTS if e["family"] == family]


DEFAULTS = dict(
    duration=0,
    fps=30,
    longEdge=1920,
    sliceMode=0,
    sliceCount=100,
    origin=-1,
    direction=0,
    playback=1,
    build=0.5,
    ending=0,
    angle=45,
    turns=-1,
    cycles=0,
    span=0,
    softness=0.15,
    density=0.42,
    centerX=0.5,
    centerY=0.5,
    sourceStart=0,
    sourceEnd=1,
    sourceReverse=False,
    waveSources=2,
    customMap=False,
    mapMode=0,
    mapBits=32,
    reference=False,
    engine="auto",
    quality="full",
    keepAudio=True,
    encoder="auto",
    bitrateMbps=0,
    gradientDither=True,
    exportFormat="h264",
    smooth=False,
)
if MAC42:
    DEFAULTS.update(
        shadowEnabled=False,
        shadowStrength=0.33,
        shadowWidth=0.20,
        shadowSoftness=0.82,
        shadowSide=0,
    )


# 为指定效果建立独立的默认设置副本。
def default_settings(effect):
    s = dict(DEFAULTS)
    if MAC42 and effect["family"] == 0:
        s.update(shadowEnabled=True, ending=3)
    return s


# 按长边缩放并保持宽高比，输出适合编码的偶数尺寸。
def dimensions(info, edge):
    w, h = info["width"], info["height"]
    s = min(1, edge / max(w, h)) if edge else 1
    return max(2, int(w * s) // 2 * 2), max(2, int(h * s) // 2 * 2)


# 将中心偏移与几何原点组合为实际取样中心。
def center(e, s):
    o = s["origin"] if s["origin"] >= 0 else e["origin"]
    # Mac 旋转用角度控制起点，旧平台未设置此参数时保留原语义。
    if e["id"] in (0, 104) and "rotationStartAngle" in s:
        o = 4
    x, y = [(0.5, 1), (0.5, 0), (0, 0.5), (1, 0.5), (0.5, 0.5)][o]
    return x + s["centerX"] - 0.5, y + s["centerY"] - 0.5, o


# 按几何形状和输出像素尺寸计算切片数量上限。
def limit(e, s, w, h):
    cx, cy, _ = center(e, s)
    rx = max(abs(cx), abs(1 - cx)) * w
    ry = max(abs(cy), abs(1 - cy)) * h
    r = math.hypot(rx, ry)
    shape = e["shape"]
    if s.get("customMap") or e["id"] in (405, 408):
        return w * h
    if e["id"] == 410:
        return min(3, h) * w
    if e["id"] == 13:
        return 1
    if shape in (0, 11):
        return w
    if shape == 1:
        return h
    if shape in (2, 12):
        a = math.radians(s["angle"])
        return max(2, int((w - 1) * abs(math.cos(a)) + (h - 1) * abs(math.sin(a))) + 1)
    if shape in (5, 14, 13):
        return max(2, math.ceil(r - math.hypot(max(0, -cx, cx - 1) * w, max(0, -cy, cy - 1) * h)))
    if shape == 6:
        return max(2, math.ceil(rx + ry))
    if shape == 7:
        return max(2, math.ceil(min(rx, ry)))
    if shape in (3, 4, 9):
        return max(2, min(w * h, math.ceil(math.pi * r * (1 if shape == 3 else 2))))
    return w * h


# 解析推荐、自定或像素细分模式并限制有效切片数量。
def density(e, s, w, h):
    if s.get("reference") and e["reference"]:
        return e["slices"], False, e["slices"]
    cap = limit(e, s, w, h)
    pixel = s["sliceMode"] == 2 or (s["sliceMode"] == 0 and e["pixel"])
    n = (
        cap
        if pixel
        else s["sliceCount"]
        if s["sliceMode"] == 1
        else s.get("recommendedSlices", e["slices"])
    )
    return (
        min(
            cap,
            max(3 if e["id"] == 403 or (s.get("customMap") and s["mapMode"] == 1) else 2, int(n)),
        ),
        pixel,
        cap,
    )


# 获取效果显式时长，未设置时使用效果推荐值。
def duration(e, s):
    return s["duration"] or e["duration"]


# 把效果与设置编码为 CPU/GPU 共用参数布局。
def params(e, s, w, h, u, source_duration, frames, view=0):
    sample_w, sample_h = w, h
    w = s.get("outputWidth", w)
    h = s.get("outputHeight", h)
    n, pixel, _ = density(e, s, w, h)
    cx, cy, o = center(e, s)
    floats = [
        u,
        u,
        source_duration,
        w / h,
        n,
        float(pixel),
        s["span"] or e["span"],
        s["cycles"] or e["cycles"],
        cx,
        cy,
        s["angle"]
        if e["shape"] in (2, 12)
        else s.get("rotationStartAngle", 0.0)
        if e["shape"] == 4
        else 0,
        e["turns"] if s["turns"] < 0 else s["turns"],
        s["build"],
        s["softness"],
        s["density"],
        float(s["sourceReverse"]),
        s["sourceStart"],
        s["sourceEnd"],
        w,
        h,
    ]
    split = MAC42 and e["family"] == 0 and bool(s.get("dayNightSplit", False))
    if split:
        floats[1] = min(s["build"], max(0.0, u) * s["build"])
    flags = (
        int(s.get("smooth", False))
        | (2 if s["mapMode"] == 1 else 0)
        | (4 if s.get("mapBits") == 8 else 8 if s.get("mapBits") == 16 else 0)
    )
    if split:
        flags |= 1024
    if s.get("_exportDither", False):
        flags |= 4096
    flags |= int(s.get("_colorFlags", 0))
    ints = [
        e["family"],
        e["shape"],
        e["id"],
        0 if split else s["ending"],
        s["direction"],
        s["playback"],
        o,
        view,
        frames,
        int(s.get("customMap", False) and e["family"] != 3),
        s["waveSources"],
        flags,
    ]
    raw = np.array(floats, dtype=np.float32).tobytes() + np.array(ints, dtype=np.uint32).tobytes()
    if MAC42:
        enabled = s.get("shadowEnabled", e["family"] == 0)
        strength = s.get("shadowStrength", 0.33) if enabled and view == 0 else 0
        shadow = [
            strength,
            s.get("shadowWidth", 0.20),
            s.get("shadowSoftness", 0.82),
            s.get("shadowSide", 0),
            sample_w,
            sample_h,
            0,
            float(s.get("discardRatio", 0.60)) if split else 0,
            float(s.get("_sourcePeak", 1000)),
            203.0,
            1000.0,
            0.0,
        ]
        raw += np.array(shadow, dtype=np.float32).tobytes()
    return np.frombuffer(raw, dtype=np.uint8).copy()
