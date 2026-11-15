"""仅处理视频切片预览，保留最新请求、几何抗锯齿和昼夜结束行为。"""

import time
import traceback

import numpy as np
from lite_output import LiteOutputController
from media import time_map
from model import BY_ID
from PySide6.QtCore import Slot


class LitePreviewController(LiteOutputController):
    @Slot(float, float, float)
    def setPreviewViewport(self, width, height, scale):
        """按显示密度计算几何预览，并限制连续交互时的显示开销。"""
        factor = min(float(scale), 1920 / max(1, width, height))
        viewport = (max(64, round(width * factor)), max(64, round(height * factor)))
        if viewport != self.viewport:
            self.viewport = viewport
            self.preview_serial += 1
            self.debounce.start()

    @Slot()
    def request_preview(self):
        """直接以零调色参数合成，只接收最新版本，不做曝光或色彩分析。"""
        if self.cache is None or self._state["loading"] or not hasattr(self, "preview_renderer"):
            return
        if self.preview_pending:
            self.preview_dirty = True
            return
        self.preview_pending, self.preview_dirty = True, False
        serial, cache = self.preview_serial, self.cache
        settings = dict(
            self._state["settings"],
            outputWidth=self._state["width"],
            outputHeight=self._state["height"],
        )
        width, height = self.info["width"], self.info["height"]
        scale = min(self.viewport[0] / width, self.viewport[1] / height, 1)
        size = (max(2, round(width * scale)), max(2, round(height * scale)))
        effect, u, view = BY_ID[self.active], self._state["progress"], self._state["viewMode"]
        engine = self.gpu if self.gpu and settings["engine"] != "cpu" else self.cpu

        def work():
            """合成后投递版本号，即使失败也释放预览任务占用状态。"""
            image, error = None, ""
            try:
                mapping = None
                if settings.get("customMap") and settings.get("mapPath"):
                    mapping, bits = time_map(settings["mapPath"], *size, settings["mapMode"] == 1)
                    settings["mapBits"] = bits
                image = self.preview_renderer.frame(
                    engine,
                    cache,
                    effect,
                    settings,
                    u,
                    size,
                    np.zeros(16, np.float32),
                    mapping,
                    view,
                )
            except Exception as caught:
                error = str(caught)
                self.log(traceback.format_exc())
            self.event.emit("lite_preview", (serial, image, error))

        self.preview.submit(work)

    @Slot(str, object)
    def receive(self, kind, data):
        """过期结果不覆盖新参数；有更新时立即补算，避免主画面卡住。"""
        if kind != "lite_preview":
            return super().receive(kind, data)
        serial, image, error = data
        self.preview_pending = False
        if serial == self.preview_serial:
            if image is not None:
                self.provider.set(image)
                self._state["imageVersion"] += 1
                self._state["hasImage"] = True
            elif error:
                self._state["status"] = "预览未完成：" + error
            self.changed.emit()
        if self.preview_dirty or serial != self.preview_serial:
            self.preview_dirty = False
            self.request_preview()

    @Slot()
    def togglePlay(self):
        """昼夜冻结结束后允许从头再播放。"""
        if self.freeze_split and BY_ID[self.active]["family"] == 0 and self._state["progress"] >= 1:
            self._state["progress"] = 0
        super().togglePlay()

    def tick(self):
        """昼夜分割在展开完成时停止，其他效果维持循环播放。"""
        if not self.freeze_split or BY_ID[self.active]["family"] != 0:
            return super().tick()
        now = time.monotonic()
        self._state["progress"] = min(
            1, self._state["progress"] + (now - self.last_tick) / max(0.01, self._state["duration"])
        )
        self.last_tick = now
        self._state["elapsed"] = self.format_time(self._state["progress"] * self._state["duration"])
        if self._state["progress"] >= 1:
            self.pause()
        self.changed.emit()
        self.request_preview()
