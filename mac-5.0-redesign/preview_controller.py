"""播放与预览请求调度，过期结果不覆盖当前画面。"""

import time
import traceback

import numpy as np
from media import time_map
from model import BY_ID
from PySide6.QtCore import Slot
from source_controller import SourceController
from source_processing import grade_config


class PreviewController(SourceController):
    # 接收视口像素密度和尺寸，按实际显示尺寸请求几何预览。
    @Slot()
    def togglePlay(self):
        """昼夜展开播完后再次点击播放时，从头重新开始。"""
        if (
            self.freeze_split
            and BY_ID[self.active]["family"] == 0
            and self._state["progress"] >= 1
            and not self._state["playing"]
        ):
            self._state.update(progress=0.0, elapsed=self.format_time(0.0))
        super().togglePlay()

    def tick(self):
        """昼夜模式到最后一片即暂停，普通效果保留既有循环预览。"""
        if not self.freeze_split or BY_ID[self.active]["family"] != 0:
            return super().tick()
        now = time.monotonic()
        elapsed = now - self.last_tick
        self.last_tick = now
        self._state["progress"] = min(
            1.0, self._state["progress"] + elapsed / max(0.01, self._state["duration"])
        )
        self._state["elapsed"] = self.format_time(self._state["progress"] * self._state["duration"])
        if self._state["progress"] >= 1:
            self.pause()
        self.changed.emit()
        self.request_preview()

    # 接收视口像素密度和尺寸，按实际显示尺寸请求几何预览。
    @Slot(float, float, float)
    def setPreviewViewport(self, width, height, scale):
        size = (max(64, round(width * scale)), max(64, round(height * scale)))
        if size == self.viewport:
            return
        self.viewport = size
        self.preview_serial += 1
        self.debounce.start()

    # 按源宽高比计算当前视口可用的预览尺寸。
    def preview_size(self):
        sw, sh = (self.info["width"], self.info["height"]) if self.info else (1920, 1080)
        scale = min(self.viewport[0] / sw, self.viewport[1] / sh, 1.0)
        return max(2, round(sw * scale)), max(2, round(sh * scale))

    # 合并预览请求，后台计算后仅采用最新版本的结果。
    @Slot()
    def request_preview(self):
        if self.cache is None or self._state["loading"] or not hasattr(self, "preview_renderer"):
            return
        if self.preview_pending:
            self.preview_dirty = True
            return
        self.preview_pending = True
        self.preview_dirty = False
        serial = self.preview_serial
        effect = BY_ID[self.active]
        settings = dict(self._state["settings"])
        settings.update(outputWidth=self._state["width"], outputHeight=self._state["height"])
        u = self._state["progress"]
        view = self._state["viewMode"]
        cache = self.cache
        size = self.preview_size()
        curve = self.color_curve
        if curve is None or len(curve) != len(cache.data):
            curve = np.linspace(0, 1, len(cache.data), dtype=np.float32)
        grade = grade_config(self.source_options, curve)
        engine = self.gpu if self.gpu and settings["engine"] != "cpu" else self.cpu

        # 在线程池中执行耗时工作，并向界面线程投递结果或异常。
        def work():
            image = None
            error = ""
            try:
                mapping = None
                if settings.get("customMap") and settings.get("mapPath"):
                    mapping, bits = time_map(settings["mapPath"], *size, settings["mapMode"] == 1)
                    settings["mapBits"] = bits
                image = self.preview_renderer.frame(
                    engine, cache, effect, settings, u, size, grade, mapping, view
                )
            except Exception as caught:
                error = str(caught)
                try:
                    self.log(traceback.format_exc())
                except OSError:
                    pass
            finally:
                self.event.emit("preview_complete", (serial, image, error))

        self.preview.submit(work)
