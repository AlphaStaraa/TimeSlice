"""轻量工作台：视频、切片参数、可选批量与输出，复用同一渲染内核。"""

from pathlib import Path

import numpy as np
import sharing
from effect_models import EffectListModel, SelectionListModel, mac_defaults
from i18n import EFFECTS_EN, localize_state, translate_text
from lite_preview import LitePreviewController
from local_metrics import LocalMetrics
from model import BY_ID, EFFECTS, ROOT, duration
from preview_render import PreviewRenderer
from progress_estimator import ProgressEstimator
from PySide6.QtCore import Property, QObject, QSettings, QUrl, Signal, Slot
from PySide6.QtGui import QFontDatabase
from rounded_preview import register_components
from video_cache import VideoCache


class LiteController(LitePreviewController):
    languageChanged = Signal(str)
    uiChanged = Signal()

    def __init__(self, provider, preferences=None):
        """使用独立偏好及缓存，默认单选，所有冻结沿用已确认的默认参数。"""
        super().__init__(provider)
        self.changed.connect(self.uiChanged.emit)
        register_components()
        self.preferences = (
            preferences if preferences is not None else QSettings("AlphaStar", "TimeSliceLite")
        )
        self._language = self.preferences.value("interface/language", "zh", str)
        if self._language not in ("zh", "en"):
            self._language = "zh"
        self.picker_open = self.resume_export = False
        self.batch = False
        self.freeze_split, self.freeze_discard = False, 0.6
        self.effect_model = EffectListModel(self)
        self.selection_model = SelectionListModel(self)
        self.selected_order = [self.active]
        self.per_effect = {effect["id"]: mac_defaults(effect) for effect in EFFECTS}
        self.source_store = VideoCache(self.cache_root)
        self.metrics = LocalMetrics(
            self.cache_root / "usage.json", self.preferences.value("metrics/enabled", False, bool)
        )
        self.preview_renderer = PreviewRenderer()
        self.viewport = (960, 540)
        self.export_eta = ProgressEstimator()
        self.debounce.setInterval(16)
        output = self.preferences.value("export/folder", "", str)
        self._state.update(
            output=output if output and Path(output).is_dir() else "",
            language=self._language,
            batchProgress=0.0,
            batchStage="",
            finishedCount=0,
            author="AlphaStar",
            metricsEnabled=self.metrics.enabled,
            batch=False,
            freezeSplit=False,
            freezeDiscard=0.6,
            selectionDuration=6.0,
            status="导入延时视频，选择切片，然后导出。",
        )
        self.sync()

    @Property("QVariantMap", notify=uiChanged)
    def uiState(self):
        """提供精简界面状态和导出剩余时间，品牌不使用拼音。"""
        state = localize_state(self._state, getattr(self, "_language", "zh"))
        state["title"] = "TimeSlice Lite" if state["language"] == "en" else "时刃 Lite"
        state["exportEta"] = (
            self.export_eta.text(self._language) if self._state["rendering"] else ""
        )
        return state

    @Property(str, constant=True)
    def interfaceFont(self):
        """使用系统界面字体，不额外打包字体。"""
        return QFontDatabase.systemFont(QFontDatabase.GeneralFont).family()

    @Property(str, constant=True)
    def monoFont(self):
        """使用系统等宽字体显示时间码。"""
        return QFontDatabase.systemFont(QFontDatabase.FixedFont).family()

    @Property(QObject, constant=True)
    def effectModel(self):
        """保持效果模型实例不变，点击选项时不重置滚动位置。"""
        return self.effect_model

    @Property(QObject, constant=True)
    def selectionModel(self):
        """提供可拖动的已选队列，仅在批量模式显示。"""
        return self.selection_model

    @Property(str, notify=languageChanged)
    def language(self):
        """返回界面语言。"""
        return self._language

    @Property(str, notify=languageChanged)
    def localizedLicense(self):
        """显示作者、免费声明和 AGPL 全文。"""
        name = "LICENSE.en.txt" if self._language == "en" else "许可与免责声明.txt"
        return (ROOT / "resources" / name).read_text(encoding="utf-8")

    @Slot(str)
    def setLanguage(self, value):
        """切换语言时保留选中效果和参数。"""
        if value not in ("zh", "en") or value == self._language:
            return
        self._language = value
        self.preferences.setValue("interface/language", value)
        self.languageChanged.emit(value)
        self.sync()

    def sync(self):
        """刷新既有模型，单选始终导出当前效果，多选保留用户顺序。"""
        super().sync()
        if not hasattr(self, "effect_model"):
            return
        self._state.update(
            batch=self.batch, freezeSplit=self.freeze_split, freezeDiscard=self.freeze_discard
        )
        localized = localize_state(self._state, self._language)
        self.effect_model.update(localized["effects"])
        self.selected_order = [eid for eid in self.selected_order if eid in self.checked]
        self.selected_order.extend(
            e["id"]
            for e in EFFECTS
            if e["id"] in self.checked and e["id"] not in self.selected_order
        )
        rows = []
        for rank, eid in enumerate(self.selected_order, 1):
            effect = BY_ID[eid]
            name = (
                effect["name"]
                if self._language == "zh"
                else EFFECTS_EN.get(effect["key"], translate_text(effect["name"]))
            )
            rows.append(
                dict(
                    effect,
                    name=name,
                    rank=rank,
                    seconds=duration(effect, self.per_effect[eid]),
                    catalogueKey=f"selected_{eid}",
                )
            )
        self.selection_model.update(rows)
        self._state.update(
            selectedOrder=list(self.selected_order),
            selectionDuration=sum(r["seconds"] for r in rows),
        )
        self.changed.emit()

    @Slot(int)
    def setActive(self, eid):
        """单击即可选择要导出的效果，批量模式仅改变当前预览。"""
        if self._state["rendering"] or eid not in BY_ID:
            return
        if not self.batch:
            self.checked = {eid}
            self.selected_order = [eid]
        super().setActive(eid)

    @Slot(bool)
    def setBatch(self, enabled):
        """按需展开多选，关闭后回到当前效果的单项导出。"""
        if self._state["rendering"]:
            return
        self.batch = bool(enabled)
        if not self.batch:
            self.checked, self.selected_order = {self.active}, [self.active]
        self.sync()

    @Slot(int)
    def toggleEffect(self, eid):
        """多选按点击顺序追加，取消选择不触发无关预览。"""
        if self._state["rendering"] or eid not in BY_ID:
            return
        if not self.batch:
            return self.setActive(eid)
        if eid not in self.checked:
            self.selected_order.append(eid)
        super().toggleEffect(eid)

    @Slot(int, int)
    def moveSelection(self, eid, target):
        """拖动后保持展示和分别导出的次序一致。"""
        if self._state["rendering"] or eid not in self.selected_order:
            return
        target = max(0, min(len(self.selected_order) - 1, int(target)))
        self.selected_order.remove(eid)
        self.selected_order.insert(target, eid)
        self.sync()

    @Slot(int)
    def removeSelection(self, eid):
        """从队列移除，同时取消库中勾选。"""
        if not self._state["rendering"]:
            self.checked.discard(eid)
            self.sync()

    @Slot(int)
    def activateSelection(self, eid):
        """从队列切换回对应形状。"""
        if eid in self.checked:
            self.family = 1 if BY_ID[eid]["family"] == 2 else BY_ID[eid]["family"]
            self.setActive(eid)

    @Slot(str, "QVariant")
    def setSetting(self, key, value):
        """保留切片核心调整；旋转使用角度，禁止打开旧 PR 对照渲染分支。"""
        if self._state["rendering"] or key == "reference":
            return
        if isinstance(value, (int, float)) and not np.isfinite(value):
            return
        if key == "rotationStartAngle":
            if self.active in (0, 104):
                self.per_effect[self.active].update(
                    rotationStartAngle=max(0, min(360, float(value))), origin=-1
                )
                self.preview_serial += 1
                self.sync()
                self.debounce.start()
            return
        if key == "origin" and self.active in (0, 104):
            return
        super().setSetting(key, value)

    @Slot(bool)
    def setFreezeSplit(self, enabled):
        """全局切换昼夜冻结；未冻结底片仍连续播放。"""
        if self._state["rendering"]:
            return
        self.pause()
        self.freeze_split = bool(enabled)
        for effect in EFFECTS:
            if effect["family"] == 0:
                self.per_effect[effect["id"]].update(
                    dayNightSplit=self.freeze_split, discardRatio=self.freeze_discard
                )
        self._state["progress"] = 0
        self.preview_serial += 1
        self.sync()
        self.debounce.start()

    @Slot(float)
    def setFreezeDiscard(self, ratio):
        """调整冻结层跳过的中段比例，不对原素材做额外处理。"""
        if not np.isfinite(ratio) or self._state["rendering"]:
            return
        self.freeze_discard = max(0, min(1, float(ratio)))
        self.setFreezeSplit(self.freeze_split)

    @Slot()
    def resetSettings(self):
        """恢复当前形状默认值，保留当前昼夜分割选择。"""
        self.per_effect[self.active] = mac_defaults(BY_ID[self.active])
        if BY_ID[self.active]["family"] == 0:
            self.per_effect[self.active].update(
                dayNightSplit=self.freeze_split, discardRatio=self.freeze_discard
            )
        self.preview_serial += 1
        self.sync()
        self.debounce.start()

    @Slot()
    def importExample(self):
        """导入随包示例，与用户导入视频共用完整渲染流程。"""
        self.importSource(str(ROOT.parent / "assets/example.mp4"))

    @Slot(str)
    def importPreset(self, url):
        """导入可分享参数，保留原视频和输出规格。"""
        if self._state["rendering"]:
            return
        try:
            path = QUrl(url).toLocalFile() if url.startswith("file:") else url
            order, settings, split, discard = sharing.load(path)
            self.per_effect.update(settings)
            self.batch = len(order) > 1
            self.checked, self.selected_order = set(order), order
            self.freeze_split, self.freeze_discard = split, discard
            for effect in EFFECTS:
                if effect["family"] == 0:
                    self.per_effect[effect["id"]].update(dayNightSplit=split, discardRatio=discard)
            self.active = order[0]
            self.family = 1 if BY_ID[self.active]["family"] == 2 else BY_ID[self.active]["family"]
            self._state.update(progress=0, status="切片参数已导入")
            self.preview_serial += 1
            self.sync()
            self.debounce.start()
        except (OSError, ValueError, TypeError, KeyError) as error:
            self.receive("error", str(error))

    @Slot(str)
    def exportPreset(self, url):
        """将当前选择保存为 JSON；不包含视频或外部时间图。"""
        path = QUrl(url).toLocalFile() if url.startswith("file:") else url
        try:
            sharing.save(
                path, self.selected_order, self.per_effect, self.freeze_split, self.freeze_discard
            )
            self._state["status"] = "切片参数已保存"
            self.changed.emit()
        except (OSError, ValueError) as error:
            self.receive("error", str(error))

    @Slot(bool)
    def setMetricsEnabled(self, enabled):
        """仅在用户明确开启后记录本地统计，偏好与完整版独立。"""
        self.metrics.enabled = bool(enabled)
        self.preferences.setValue("metrics/enabled", bool(enabled))
        self._state["metricsEnabled"] = bool(enabled)
        self.changed.emit()

    @Slot(str)
    def exportMetrics(self, url):
        """主动导出本地记录，不进行网络上传。"""
        path = QUrl(url).toLocalFile() if url.startswith("file:") else url
        try:
            self.metrics.export(path)
            self._state["status"] = "本地统计已导出"
            self.changed.emit()
        except OSError as error:
            self.receive("error", str(error))

    def shutdown(self):
        """先结束后台任务，再释放预览显存与视频缓存。"""
        self.preview.submit(self.preview_renderer.close)
        super().shutdown()
        self.source_store.close()
