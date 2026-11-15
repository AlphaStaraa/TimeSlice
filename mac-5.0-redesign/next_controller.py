"""桌面公共入口：语言、可视化队列、冻结设置及导出协调。"""

import sys
import threading
from copy import deepcopy
from functools import partial
from pathlib import Path

import numpy as np
from effect_models import EffectListModel, SelectionListModel
from effect_models import mac_defaults as mac_defaults
from i18n import EFFECTS_EN, localize_state, translate_text
from model import BY_ID, EFFECTS, duration
from preview_controller import PreviewController
from preview_render import PreviewRenderer
from processed_render import ProcessedRenderJob as ProcessedRenderJob
from progress_estimator import ProgressEstimator
from PySide6.QtCore import Property, QObject, QTimer, Signal, Slot
from PySide6.QtGui import QFontDatabase
from rounded_preview import register_components
from source_processing import DEFAULT_OPTIONS
from source_video_cache import VideoCache


class NextController(PreviewController):
    languageChanged = Signal(str)

    languageChanging = Signal()

    uiChanged = Signal()

    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self, provider, preferences=None):
        super().__init__(provider, preferences)
        register_components()
        self.changed.connect(self.uiChanged.emit)
        self.original_cache = None
        self.source_store = VideoCache(self.cache_root)
        self.source_options = deepcopy(DEFAULT_OPTIONS)
        self.shutting_down = False
        self.processing_stop = threading.Event()
        self.processing_version = 0
        self.freeze_split = False
        self.freeze_discard = 0.60
        self.prepared_cache = None
        self.prepared_key = None
        self.source_eta = ProgressEstimator()
        self.export_eta = ProgressEstimator()
        self.color_curve = None
        self.viewport = (960, 540)
        self.preview_renderer = PreviewRenderer()
        self.effect_model = EffectListModel(self)
        self.selection_model = SelectionListModel(self)
        self.selected_order = list(self.checked)
        self._language = self.preferences.value("interface/language", "zh", str)
        if self._language not in ("zh", "en"):
            self._language = "zh"
        self.source_timer = QTimer(self)
        self.source_timer.setSingleShot(True)
        self.source_timer.setInterval(0)
        self.source_timer.timeout.connect(self.prepare_source_preview)
        self.debounce.setInterval(16)
        self.per_effect = {e["id"]: mac_defaults(e) for e in EFFECTS}
        self._state.update(
            processing=False,
            processingProgress=0.0,
            processingStage="",
            processingError="",
            stabilizeStatus="",
            deflickerStatus="",
            dayNightDetected="",
            dayNightConfidence=0.0,
            language=self._language,
            sourceOptions=deepcopy(self.source_options),
            sourceReport={},
            processingEta="",
            exportEta="",
            preparedReady=False,
        )
        self.sync()

    # 生成带语言适配和剩余时间的界面状态。
    @Property("QVariantMap", notify=uiChanged)
    def uiState(self):
        out = localize_state(self._state, getattr(self, "_language", "zh"))
        if hasattr(self, "source_eta"):
            out["processingEta"] = (
                self.source_eta.text(self._language) if self._state.get("processing") else ""
            )
            out["exportEta"] = (
                self.export_eta.text(self._language) if self._state.get("rendering") else ""
            )
        return out

    @Property(str, constant=True)
    def interfaceFont(self):
        """调用操作系统的界面字体，不复制或打包系统字体文件。"""
        return QFontDatabase.systemFont(QFontDatabase.GeneralFont).family()

    @Property(str, constant=True)
    def monoFont(self):
        """取得系统等宽字体，用于时间码与数值，避免字体别名匹配。"""
        return QFontDatabase.systemFont(QFontDatabase.FixedFont).family()

    # 返回持久效果列表模型，避免勾选引起滚动重置。
    @Property(QObject, constant=True)
    def effectModel(self):
        return self.effect_model

    # 读取当前界面语言。
    @Property(QObject, constant=True)
    def selectionModel(self):
        """供预览旁的可视化排列使用的持久队列模型。"""
        return self.selection_model

    @Slot(int, int)
    def moveSelection(self, effect_id, target):
        """按拖放位置移动一个效果，并把相同顺序交给实际导出任务。"""
        if self._state["rendering"] or effect_id not in self.selected_order:
            return
        target = max(0, min(len(self.selected_order) - 1, int(target)))
        source = self.selected_order.index(effect_id)
        if source == target:
            return
        self.selected_order.pop(source)
        self.selected_order.insert(target, effect_id)
        self.sync()

    @Slot(int)
    def removeSelection(self, effect_id):
        """从可视化队列移除效果，同时取消左侧对应的勾选。"""
        if self._state["rendering"]:
            return
        self.checked.discard(effect_id)
        self.sync()

    @Slot(int)
    def activateSelection(self, effect_id):
        """点击已选卡片时切换主预览，并显示该效果所属分类。"""
        if effect_id not in self.checked:
            return
        family = BY_ID[effect_id]["family"]
        self.family = 1 if family == 2 else family
        self.setActive(effect_id)

    # 读取当前界面语言。
    @Property(str, notify=languageChanged)
    def language(self):
        return self._language

    # 按语言提供许可与免责声明。
    @Property(str, notify=languageChanged)
    def localizedLicense(self):
        root = (
            Path(sys._MEIPASS) / "app"
            if getattr(sys, "frozen", False)
            else Path(__file__).resolve().parent
        )
        if getattr(self, "_language", "zh") == "en":
            return "TimeSlice · Free and open source\n\n" + (
                root / "resources/LICENSE.en.txt"
            ).read_text(encoding="utf-8")
        return (root / "resources/许可与免责声明.txt").read_text(encoding="utf-8")

    # 切换语言并保留用户当前页和选中配置。
    @Slot(str)
    def setLanguage(self, value):
        if value not in ("zh", "en") or value == self._language:
            return
        self.languageChanging.emit()
        self._language = value
        self._state["language"] = value
        self.preferences.setValue("interface/language", value)
        self.preferences.sync()
        self.languageChanged.emit(value)
        self.sync()

    # 从当前选择与参数重建界面状态，保持底层效果配置一致。
    def sync(self):
        query = self.search
        english = getattr(self, "_language", "zh") == "en"
        if english:
            self.search = ""
        super().sync()
        self.search = query
        if not hasattr(self, "source_options"):
            return
        if english and query:
            needle = query.casefold()
            self._state["effects"] = [
                c
                for c in self._state["effects"]
                if needle
                in (
                    " ".join(
                        [
                            c["key"],
                            c["name"],
                            translate_text(c["name"]),
                            translate_text(c.get("subtitle", "")),
                        ]
                    )
                ).casefold()
            ]
        self._state["sourceOptions"] = deepcopy(self.source_options)
        self._state.update(freezeSplit=self.freeze_split, freezeDiscard=self.freeze_discard)
        self.effect_model.update(localize_state(self._state, self._language)["effects"])
        self.selected_order = [eid for eid in self.selected_order if eid in self.checked]
        self.selected_order.extend(
            effect["id"]
            for effect in EFFECTS
            if effect["id"] in self.checked and effect["id"] not in self.selected_order
        )
        entries = []
        for index, eid in enumerate(self.selected_order):
            effect = BY_ID[eid]
            name = (
                effect["name"]
                if self._language == "zh"
                else EFFECTS_EN.get(effect["key"], translate_text(effect["name"]))
            )
            entries.append(
                dict(
                    effect,
                    name=name,
                    rank=index + 1,
                    catalogueKey="selected_" + str(eid),
                    seconds=duration(effect, self.per_effect[eid]),
                )
            )
        self.selection_model.update(entries)
        self._state.update(
            selectedOrder=list(self.selected_order),
            selectionDuration=sum(row["seconds"] for row in entries),
        )
        self.changed.emit()

    # 恢复当前效果的默认配置并刷新画面。
    @Slot()
    def resetSettings(self):
        self.per_effect[self.active] = mac_defaults(BY_ID[self.active])
        if BY_ID[self.active]["family"] == 0:
            self.per_effect[self.active].update(
                dayNightSplit=self.freeze_split, discardRatio=self.freeze_discard
            )
        self.preview_serial += 1
        self.sync()
        self.debounce.start()

    # 为全部冻结形状切换同一昼夜分割选项。
    @Slot(bool)
    def setFreezeSplit(self, enabled):
        """统一切换全部冻结形状的昼夜分割模式，不改动已经准备好的素材缓存。"""
        if self._state["rendering"]:
            return
        self.pause()
        self.freeze_split = bool(enabled)
        for effect in EFFECTS:
            if effect["family"] == 0:
                self.per_effect[effect["id"]].update(
                    dayNightSplit=self.freeze_split, discardRatio=self.freeze_discard
                )
        if self.freeze_split and BY_ID[self.active]["family"] != 0:
            self.active = 100
        self._state["progress"] = 0.0
        self.preview_serial += 1
        self.sync()
        self.debounce.start()

    @Slot(float)
    def setFreezeDiscard(self, ratio):
        """调整冻结片跳过的中段比例，首尾均分剩余长度；底片时间连续，所有冻结形状实时刷新。"""
        if self._state["rendering"]:
            return
        if not np.isfinite(ratio):
            return
        self.freeze_discard = max(0.0, min(1.0, float(ratio)))
        for effect in EFFECTS:
            if effect["family"] == 0:
                self.per_effect[effect["id"]]["discardRatio"] = self.freeze_discard
        self.preview_serial += 1
        self.sync()
        self.debounce.start()

    # 冻结当前导出配置并返回对应的任务构造器。
    def render_factory(self):
        prepared = (
            None
            if self.prepared_cache is None
            else dict(folder=str(self.prepared_cache.folder), key=self.prepared_key)
        )
        self.export_eta.reset()
        return partial(
            ProcessedRenderJob,
            source_options=deepcopy(self.source_options),
            prepared=prepared,
            order=list(self.selected_order),
            source_store=self.source_store,
        )

    # 检查素材与目标位置后启动批量导出。
    @Slot()
    def startRender(self):
        if self._state.get("processing") or self.source_timer.isActive():
            self._state["status"] = "请等待素材预览处理完成"
            self.changed.emit()
            return
        if self._state.get("processingError"):
            self._state["error"] = self._state["processingError"]
            self.changed.emit()
            return
        super().startRender()
        if self._state["rendering"]:
            rank = {eid: index for index, eid in enumerate(self.selected_order)}
            self._state["queue"].sort(key=lambda entry: rank.get(entry["id"], len(rank)))
            self.changed.emit()

    # 停止后台任务并依次关闭缓存、线程和渲染设备。
    def shutdown(self):
        self.shutting_down = True
        self.source_timer.stop()
        self.processing_stop.set()
        self.preview.submit(self.preview_renderer.close)
        super().shutdown()
        self.source_store.close()
        if self.original_cache is not None and self.original_cache is not self.cache:
            self.original_cache.discard()
        if self.prepared_cache is not None:
            self.prepared_cache.discard()
