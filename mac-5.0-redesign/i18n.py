"""Chinese source strings with a runtime-switchable English Qt translator."""

import json
import sys
from functools import lru_cache
from pathlib import Path

from PySide6.QtCore import QTranslator

ROOT = (
    Path(sys._MEIPASS) / "app" if getattr(sys, "frozen", False) else Path(__file__).resolve().parent
)
EN = json.loads((ROOT / "resources/en.json").read_text(encoding="utf-8"))
EFFECTS_EN = {
    "base_vertical": "Vertical strips",
    "base_horizontal": "Horizontal strips",
    "base_diagonal": "Diagonal strips",
    "base_fan": "Fan slices",
    "base_circle": "Ring slices",
    "base_diamond": "Diamond slices",
    "base_rotate": "Rotating slices",
    "base_box": "Nested frames",
    "base_grid": "Checkerboard",
    "base_triangle": "Triangles",
    "base_blinds": "Alternating blinds",
    "base_zigzag": "Zigzag slices",
    "freeze_vertical": "Vertical freeze",
    "freeze_horizontal": "Horizontal freeze",
    "freeze_diagonal": "Diagonal freeze",
    "freeze_fan": "Fan freeze",
    "freeze_rotate": "Rotating freeze",
    "freeze_circle": "Ring freeze",
    "freeze_diamond": "Diamond freeze",
    "freeze_box": "Frame freeze",
    "freeze_grid": "Checkerboard freeze",
    "freeze_spiral": "Spiral freeze",
    "wave_circle": "Circular ripples",
    "wave_arc": "Arc ripples",
    "wave_fan": "Fan ripples",
    "wave_horizontal": "Horizontal ripples",
    "wave_vertical": "Vertical ripples",
    "wave_diagonal": "Diagonal ripples",
    "wave_diamond": "Diamond ripples",
    "wave_box": "Frame ripples",
    "wave_zigzag": "Zigzag ripples",
    "wave_star": "Star ripples",
}
DESCRIPTIONS = {}


# 翻译动态状态文本并缓存重复的查找结果。
@lru_cache(maxsize=4096)
def translate_text(text):
    if not isinstance(text, str):
        return text
    if text in EN:
        return EN[text]
    if text.startswith("/") or "://" in text:
        return text
    result = text
    for source, target in sorted(EN.items(), key=lambda item: len(item[0]), reverse=True):
        if len(source) >= 3 and source in result:
            result = result.replace(source, target)
    return result


class Translator(QTranslator):
    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self, language="zh", parent=None):
        super().__init__(parent)
        self.language = language

    # 告知 Qt 翻译器是否应参与当前语言查找。
    def isEmpty(self):
        return False

    # 查找中英文界面译文，未匹配时保留源文本。
    def translate(self, context, sourceText, disambiguation=None, n=-1):
        if self.language == "en":
            return EN.get(sourceText, sourceText)
        return {
            "Close": "关闭",
            "Cancel": "取消",
            "Open": "打开",
            "Yes": "是",
            "No": "否",
            "OK": "确定",
        }.get(sourceText, sourceText)


# 对状态、效果名称和队列文案进行统一语言适配。
def localize_state(state, language):
    if language != "en":
        return dict(state, language="zh")
    out = dict(state, language="en")
    for key in (
        "title",
        "version",
        "status",
        "device",
        "error",
        "busyText",
        "batchStage",
        "processingStage",
        "processingError",
        "stabilizeStatus",
        "deflickerStatus",
        "cacheInfo",
    ):
        if key in out:
            out[key] = translate_text(out[key])
    out["effect"] = dict(state["effect"])
    effect = out["effect"]
    effect["name"] = EFFECTS_EN.get(effect["key"], translate_text(effect["name"]))
    effect["description"] = DESCRIPTIONS.get(effect["key"], translate_text(effect["description"]))
    out["effects"] = []
    for card in state["effects"]:
        item = dict(
            card,
            name=translate_text(card["name"]),
            subtitle=translate_text(card.get("subtitle", "")),
        )
        if card["family"] == 0:
            item["name"] = {
                "freeze_vertical": "Vertical",
                "freeze_horizontal": "Horizontal",
                "freeze_diagonal": "Diagonal",
                "freeze_fan": "Fan",
                "freeze_rotate": "Rotating",
                "freeze_circle": "Rings",
                "freeze_diamond": "Diamond",
                "freeze_box": "Frames",
                "freeze_grid": "Grid",
                "freeze_spiral": "Spiral",
            }.get(card["key"], item["name"])
        elif card["family"] == 3:
            item["name"] = {
                "silk": "Silk",
                "honeycomb": "Honeycomb",
                "binary": "Twin orbit",
                "film": "Filmstrip",
                "echo": "Echo",
                "zipper": "Zipper",
                "petals": "Petals",
                "iris": "Iris",
                "infinity": "Infinity",
                "spiral": "Spiral",
                "collision": "Collision",
                "weave": "Weave",
                "multiwave": "Multiwave",
                "lens": "Lens",
            }.get(card["key"], item["name"])
        out["effects"].append(item)
    for key in ("movementLabels", "orientationLabels"):
        if key in state:
            out[key] = [translate_text(value) for value in state[key]]
    out["queue"] = [
        dict(
            item, **{key: translate_text(item.get(key, "")) for key in ("name", "status", "detail")}
        )
        for item in state["queue"]
    ]
    return out
