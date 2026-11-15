"""可分享的切片参数文件：固定格式、参数白名单，不含素材路径或可执行内容。"""

import json
import math
from pathlib import Path

from effect_models import mac_defaults
from model import BY_ID

RANGES = {
    "duration": (0, 120),
    "sliceMode": (0, 2),
    "sliceCount": (2, 33554432),
    "origin": (-1, 4),
    "direction": (0, 3),
    "playback": (0, 2),
    "build": (0.1, 0.9),
    "ending": (0, 4),
    "angle": (-360, 360),
    "turns": (-1, 60),
    "cycles": (0, 60),
    "span": (0, 1),
    "softness": (0, 1),
    "density": (0, 1),
    "centerX": (0, 1),
    "centerY": (0, 1),
    "sourceStart": (0, 0.999),
    "sourceEnd": (0.001, 1),
    "waveSources": (2, 4),
    "shadowStrength": (0, 1),
    "shadowWidth": (0.02, 0.75),
    "shadowSoftness": (0, 1),
    "shadowSide": (0, 1),
    "rotationStartAngle": (0, 360),
}
BOOLEANS = {"sourceReverse", "shadowEnabled"}
INTEGER_KEYS = {
    "sliceMode",
    "sliceCount",
    "origin",
    "direction",
    "playback",
    "ending",
    "waveSources",
    "shadowSide",
}


def save(path, order, settings, split, discard):
    """只分享选中效果与切片参数，去掉素材、输出路径、编码器及外部时间图。"""
    payload = dict(
        format="timeslice.preset/v1",
        dayNightSplit=bool(split),
        discardRatio=discard,
        effects=[
            dict(
                id=eid,
                settings={
                    key: value
                    for key, value in settings[eid].items()
                    if key in RANGES or key in BOOLEANS
                },
            )
            for eid in order
        ],
    )
    Path(path).write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def load(path):
    """严格校验文件大小、效果数量、参数类型和范围，拒绝未知字段与非法数值。"""
    path = Path(path)
    if path.stat().st_size > 128 * 1024:
        raise ValueError("参数文件过大")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or data.get("format") != "timeslice.preset/v1":
        raise ValueError("不是受支持的切片参数文件")
    effects = data.get("effects")
    if not isinstance(effects, list) or not 1 <= len(effects) <= len(BY_ID):
        raise ValueError("效果数量无效")
    split, discard = data.get("dayNightSplit", False), data.get("discardRatio", 0.6)
    if (
        type(split) is not bool
        or type(discard) not in (int, float)
        or not math.isfinite(discard)
        or not 0 <= discard <= 1
    ):
        raise ValueError("昼夜参数无效")
    values, order = {}, []
    for entry in effects:
        if (
            not isinstance(entry, dict)
            or type(entry.get("id")) is not int
            or entry["id"] not in BY_ID
        ):
            raise ValueError("包含未知效果")
        eid = entry["id"]
        if eid in values or not isinstance(entry.get("settings"), dict):
            raise ValueError("效果重复或参数格式无效")
        current = mac_defaults(BY_ID[eid])
        for key, value in entry["settings"].items():
            if key in BOOLEANS:
                if type(value) is not bool:
                    raise ValueError("布尔参数类型无效：" + key)
            elif key in RANGES:
                low, high = RANGES[key]
                if (
                    type(value) not in (int, float)
                    or not math.isfinite(value)
                    or not low <= value <= high
                ):
                    raise ValueError("参数超出范围：" + key)
                if key in INTEGER_KEYS:
                    if int(value) != value:
                        raise ValueError("此参数必须为整数：" + key)
                    value = int(value)
            else:
                raise ValueError("不支持的参数：" + key)
            current[key] = value
        if current["sourceStart"] >= current["sourceEnd"]:
            raise ValueError("素材入点必须早于出点")
        if BY_ID[eid]["family"] == 0:
            current.update(dayNightSplit=split, discardRatio=discard)
        values[eid] = current
        order.append(eid)
    return order, values, split, discard
