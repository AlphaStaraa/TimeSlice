"""管理预览图像、播放节奏与最新请求。"""

import threading
import time
import traceback

from controller_media import SourceController
from media import time_map
from model import BY_ID, duration
from PySide6.QtCore import Slot
from PySide6.QtGui import QImage
from PySide6.QtQuick import QQuickImageProvider


class PreviewProvider(QQuickImageProvider):
    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self):
        super().__init__(QQuickImageProvider.Image)
        self.image = QImage()
        self.lock = threading.Lock()

    # 保存新的图像或属性供后续界面读取。
    def set(self, array):
        h, w, _ = array.shape
        im = QImage(array.data, w, h, w * 4, QImage.Format_RGBA8888).copy()
        with self.lock:
            self.image = im

    # 向 QML 图像提供器返回当前预览帧。
    def requestImage(self, id, size, requestedSize):
        with self.lock:
            im = self.image.copy()
        size.setWidth(im.width())
        size.setHeight(im.height())
        return im


class PreviewController(SourceController):
    # 按用户指定位置更新预览时间。
    @Slot(float)
    def seek(self, u):
        self._state["progress"] = max(0, min(0.999999, u))
        self._state["elapsed"] = self.format_time(self._state["progress"] * self._state["duration"])
        self.preview_serial += 1
        self.changed.emit()
        self.debounce.start()

    # 在效果、原素材和时间图之间切换预览。
    @Slot(int)
    def setView(self, mode):
        self._state["viewMode"] = mode
        self.preview_serial += 1
        self.changed.emit()
        self.debounce.start()

    # 切换预览播放或暂停。
    @Slot()
    def togglePlay(self):
        self._state["playing"] = not self._state["playing"]
        self.last_tick = time.monotonic()
        if self._state["playing"]:
            self.timer.start()
        else:
            self.timer.stop()
        self.changed.emit()

    # 停止预览计时器，保留当前时间位置。
    def pause(self):
        self.timer.stop()
        self._state["playing"] = False

    # 依据经过的时间推进预览，而非依赖固定帧计数。
    def tick(self):
        now = time.monotonic()
        dt = now - self.last_tick
        self.last_tick = now
        self._state["progress"] = (self._state["progress"] + dt / self._state["duration"]) % 1
        self._state["elapsed"] = self.format_time(self._state["progress"] * self._state["duration"])
        self.changed.emit()
        self.request_preview()

    # 合并预览请求，后台计算后仅采用最新版本的结果。
    @Slot()
    def request_preview(self):
        if not self.cache or self._state["loading"]:
            return
        if self.preview_pending:
            self.preview_dirty = True
            return
        self.preview_pending = True
        serial = self.preview_serial
        e = BY_ID[self.active]
        s = dict(self._state["settings"])
        u = self._state["progress"]
        view = self._state["viewMode"]
        cache = self.cache
        s.update(outputWidth=self._state["width"], outputHeight=self._state["height"])

        # 在线程池中执行耗时工作，并向界面线程投递结果或异常。
        def work():
            try:
                mp = None
                if s.get("customMap") and s.get("mapPath"):
                    mp, bits = time_map(s["mapPath"], cache.width, cache.height, s["mapMode"] == 1)
                    s["mapBits"] = bits
                engine = self.gpu if self.gpu and s["engine"] != "cpu" else self.cpu
                if s.get("reference") and e["reference"] and view in (0, 2):
                    from core.reference import ReferenceRenderer

                    if self.reference is None:
                        self.reference = ReferenceRenderer(cache)
                    im = self.reference.frame(e["id"], u * duration(e, s), s, view)
                else:
                    im = engine.frame(cache, e, s, u, mp, view)
                self.event.emit("image", (serial, im))
            except Exception as err:
                self.log(traceback.format_exc())
                self.event.emit("preview_error", "预览未完成：" + str(err))

        self.preview.submit(work)
