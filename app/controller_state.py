"""管理效果选择、参数与可观察状态。"""

import json
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from core.engine import CPUEngine
from export_quality import recommended_bitrate, target_bitrate, validate_bitrate
from model import (
    BY_ID,
    DEFAULTS,
    EFFECTS,
    ROOT,
    default_settings,
    density,
    dimensions,
    duration,
    effect_group,
    group_motions,
    group_orientations,
    group_variant,
    library_groups,
)
from PySide6.QtCore import Property, QObject, QStandardPaths, Qt, QTimer, QUrl, Signal, Slot
from render import RenderJob


class ControllerState(QObject):
    changed = Signal()
    event = Signal(str, object)

    render_job_type = RenderJob

    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self, provider):
        super().__init__()
        self.provider = provider
        self.cpu = CPUEngine()
        self.gpu = None
        self.cache = None
        self.info = None
        self.stop = threading.Event()
        self.load_stop = threading.Event()
        self.import_generation = 0
        self.io = ThreadPoolExecutor(1)
        self.preview = ThreadPoolExecutor(1)
        self.export = ThreadPoolExecutor(1)
        self.preview_pending = False
        self.preview_dirty = False
        self.preview_serial = 0
        self.map_data = None
        self.reference = None
        self.per_effect = {e["id"]: default_settings(e) for e in EFFECTS}
        self.checked = {100}
        self.active = 100
        self.family = 0
        self.search = ""
        self.global_settings = dict(DEFAULTS)
        self.catalogue_active = {
            g["key"]: g["default"] for f in (0, 1, 3) for g in library_groups(f)
        }
        self.cache_root = Path(QStandardPaths.writableLocation(QStandardPaths.CacheLocation))
        self.cache_root.mkdir(parents=True, exist_ok=True)
        output = Path(QStandardPaths.writableLocation(QStandardPaths.MoviesLocation)) / "时刃输出"
        release = json.loads((ROOT.parent / "release.json").read_text(encoding="utf-8"))
        self._state = dict(
            title="时刃",
            version=release["displayVersion"],
            family=0,
            active=100,
            selectedCount=1,
            effects=[],
            effect=BY_ID[100],
            settings=dict(DEFAULTS),
            source=None,
            loading=False,
            rendering=False,
            playing=False,
            progress=0.0,
            imageVersion=0,
            hasImage=False,
            viewMode=0,
            status="导入一段视频，选择你想要的时间切片。",
            device="正在检测渲染设备…",
            gpuAvailable=False,
            error="",
            queue=[],
            output=str(output),
            limit=1920,
            count=100,
            pixel=False,
            width=1080,
            height=1920,
            duration=6.0,
            elapsed="00:00.00",
            total="00:06.00",
            cacheInfo="预览与正式输出分开计算",
            busyText="",
            result="",
        )
        self.event.connect(self.receive, Qt.QueuedConnection)
        self.debounce = QTimer(self)
        self.debounce.setSingleShot(True)
        self.debounce.setInterval(70)
        self.debounce.timeout.connect(self.request_preview)
        self.timer = QTimer(self)
        self.timer.setInterval(33)
        self.timer.timeout.connect(self.tick)
        self.last_tick = time.monotonic()
        self.sync()
        self.io.submit(self.detect)

    # 返回控制器当前状态供界面绑定。
    @Property("QVariantMap", notify=changed)
    def state(self):
        return self._state

    # 返回界面资源所在的本机 URL。
    @Property(str, constant=True)
    def assets(self):
        return QUrl.fromLocalFile(str(ROOT.parent / "assets") + "/").toString()

    # 从当前选择与参数重建界面状态，保持底层效果配置一致。
    def sync(self):
        e = BY_ID[self.active]
        s = dict(self.per_effect[self.active])
        s.update(
            {
                k: self.global_settings[k]
                for k in [
                    "fps",
                    "longEdge",
                    "engine",
                    "quality",
                    "keepAudio",
                    "encoder",
                    "bitrateMbps",
                    "gradientDither",
                ]
            }
        )
        w, h = dimensions(self.info, s["longEdge"]) if self.info else (1080, 1920)
        self._state["recommendedBitrateMbps"] = recommended_bitrate(w, h, s["fps"])
        self._state["exportBitrateMbps"] = target_bitrate(w, h, s["fps"], s["bitrateMbps"]) / 1e6
        n, pix, cap = density(e, s, w, h)
        group = effect_group(e)
        variant = group_variant(group, self.active)
        motions = group_motions(group)
        orientations = group_orientations(group, variant["motion"])
        cards = []
        for entry in library_groups(self.family):
            variants = entry["variants"]
            current = BY_ID[self.catalogue_active[entry["key"]]]
            if (
                self.search
                and self.search not in entry["name"]
                and not any(
                    self.search in BY_ID[v["effect"]]["name"]
                    or self.search in BY_ID[v["effect"]]["description"]
                    or self.search in v["motion"]
                    for v in variants
                )
            ):
                continue
            chosen = group_variant(entry, current["id"])
            count = sum(v["effect"] in self.checked for v in variants)
            cards.append(
                dict(
                    current,
                    name=entry["name"],
                    catalogueKey=entry["key"],
                    checked=count > 0,
                    checkedCount=count,
                    subtitle=" · ".join(x for x in (chosen["motion"], chosen["orientation"]) if x),
                )
            )
        self._state.update(
            effect=e,
            active=self.active,
            family=self.family,
            settings=s,
            selectedCount=len(self.checked),
            effects=cards,
            activeCatalogue=group["key"],
            movementLabels=motions,
            movementIndex=motions.index(variant["motion"]),
            orientationLabels=orientations,
            orientationIndex=orientations.index(variant["orientation"]),
            activeChecked=self.active in self.checked,
            catalogueCount=sum(len(library_groups(f)) for f in (0, 1, 3)),
            limit=cap,
            count=n,
            pixel=pix,
            width=w,
            height=h,
            duration=duration(e, s),
            total=self.format_time(duration(e, s)),
        )
        self.changed.emit()

    # 把秒数格式化为时间码。
    def format_time(self, t):
        return f"{int(t) // 60:02d}:{t % 60:05.2f}"

    # 切换效果分类并更新可见卡片。
    @Slot(int)
    def setFamily(self, v):
        if v not in (0, 1, 2, 3):
            return
        self.family = 1 if v == 2 else v
        self.sync()

    # 按查询文本筛选效果库。
    @Slot(str)
    def searchEffects(self, text):
        self.search = text
        self.sync()

    # 切换当前效果并请求与新参数对应的预览。
    @Slot(int)
    def setActive(self, eid):
        if eid not in BY_ID:
            return
        self.active = eid
        self.catalogue_active[effect_group(BY_ID[eid])["key"]] = eid
        self._state["progress"] = 0
        self.preview_serial += 1
        self.sync()
        self.debounce.start()

    # 在当前形状内切换流动方式并保留可用方向。
    @Slot(int)
    def setMovement(self, index):
        group = effect_group(BY_ID[self.active])
        motions = group_motions(group)
        if index < 0 or index >= len(motions):
            return
        orientation = group_variant(group, self.active)["orientation"]
        variants = [v for v in group["variants"] if v["motion"] == motions[index]]
        self.setActive(
            next(
                (v["effect"] for v in variants if v["orientation"] == orientation),
                variants[0]["effect"],
            )
        )

    # 切换当前形状内的方向或排列。
    @Slot(int)
    def setOrientation(self, index):
        group = effect_group(BY_ID[self.active])
        motion = group_variant(group, self.active)["motion"]
        variants = [v for v in group["variants"] if v["motion"] == motion]
        if 0 <= index < len(variants):
            self.setActive(variants[index]["effect"])

    # 勾选或取消当前形状的导出组合。
    @Slot(str)
    def toggleCatalogue(self, key):
        group = next((g for g in library_groups(self.family) if g["key"] == key), None)
        if group is None:
            return
        ids = {v["effect"] for v in group["variants"]}
        if ids & self.checked:
            self.checked -= ids
        else:
            self.checked.add(self.catalogue_active[key])
        self.sync()

    # 切换一个原始效果是否加入批量导出。
    @Slot(int)
    def toggleEffect(self, eid):
        if eid in self.checked:
            self.checked.remove(eid)
        else:
            self.checked.add(eid)
        self.sync()

    # 切换当前系列的整体选择状态。
    @Slot()
    def selectFamily(self):
        groups = library_groups(self.family)
        all_ids = {v["effect"] for g in groups for v in g["variants"]}
        if all(any(v["effect"] in self.checked for v in g["variants"]) for g in groups):
            self.checked -= all_ids
        else:
            self.checked |= {self.catalogue_active[g["key"]] for g in groups}
        self.sync()

    # 校验并更新参数，仅对相关的预览或缓存发起刷新。
    @Slot(str, "QVariant")
    def setSetting(self, key, value):
        if key not in DEFAULTS and key != "mapPath":
            return
        if key == "bitrateMbps":
            try:
                value = validate_bitrate(value)
            except (ValueError, TypeError):
                return
        if key in (
            "sliceCount",
            "sliceMode",
            "fps",
            "longEdge",
            "origin",
            "direction",
            "playback",
            "ending",
            "mapMode",
            "waveSources",
        ):
            value = int(value)
        if key == "sliceCount":
            value = max(2, min(self._state["limit"], value))
        if key == "shadowSide":
            value = max(0, min(1, int(value)))
        if key in ("shadowStrength", "shadowSoftness"):
            value = max(0.0, min(1.0, float(value)))
        if key == "shadowWidth":
            value = max(0.02, min(0.75, float(value)))
        if key in ("sourceStart", "sourceEnd"):
            s = self.per_effect[self.active]
            if key == "sourceStart":
                value = min(float(value), s["sourceEnd"] - 0.001)
            else:
                value = max(float(value), s["sourceStart"] + 0.001)
        if key in [
            "fps",
            "longEdge",
            "engine",
            "quality",
            "keepAudio",
            "encoder",
            "bitrateMbps",
            "gradientDither",
        ]:
            self.global_settings[key] = value
        else:
            self.per_effect[self.active][key] = value
        if key in ("bitrateMbps", "gradientDither"):
            self.sync()
            return
        self.preview_serial += 1
        self.sync()
        self.debounce.start()

    # 恢复当前效果的默认配置并刷新画面。
    @Slot()
    def resetSettings(self):
        self.per_effect[self.active] = default_settings(BY_ID[self.active])
        self.preview_serial += 1
        self.sync()
        self.debounce.start()

    # 清除界面当前错误提示。
    @Slot()
    def dismissError(self):
        self._state["error"] = ""
        self.changed.emit()
