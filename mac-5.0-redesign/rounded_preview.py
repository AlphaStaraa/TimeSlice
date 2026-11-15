"""用同一条抗锯齿圆角路径绘制静态图和悬停动图，兼容原生与软件预览。"""

from PySide6.QtCore import Property, QRectF, Qt, QUrl, Signal
from PySide6.QtGui import QBrush, QImage, QMovie, QPainter, QTransform
from PySide6.QtQml import qmlRegisterType
from PySide6.QtQuick import QQuickPaintedItem


class RoundedPreview(QQuickPaintedItem):
    sourceChanged = Signal()
    animationSourceChanged = Signal()
    playingChanged = Signal()
    radiusChanged = Signal()

    def __init__(self, parent=None):
        """初始化透明画布，图片只读本机资源，动图在悬停后才创建解码器。"""
        super().__init__(parent)
        self._source = QUrl()
        self._animation = QUrl()
        self._playing = False
        self._radius = 12.0
        self._still = QImage()
        self._frame = QImage()
        self._movie = None
        self.setAntialiasing(True)
        self.setFillColor(Qt.transparent)

    @Property(QUrl, notify=sourceChanged)
    def source(self):
        """返回静态缩略图地址。"""
        return self._source

    @source.setter
    def source(self, value):
        """加载本机静态图；地址变化时同步清理旧的动画帧。"""
        value = QUrl(value)
        if value == self._source:
            return
        self._source = value
        self._still = QImage(value.toLocalFile()) if value.isLocalFile() else QImage()
        if not self._playing:
            self._frame = self._still
        self.sourceChanged.emit()
        self.update()

    @Property(QUrl, notify=animationSourceChanged)
    def animationSource(self):
        """返回与静态图对应的悬停动画地址。"""
        return self._animation

    @animationSource.setter
    def animationSource(self, value):
        """切换动画资源并关闭旧解码器，避免卡片复用后播放错误效果。"""
        value = QUrl(value)
        if value == self._animation:
            return
        if self._movie:
            self._movie.stop()
            self._movie.deleteLater()
            self._movie = None
        self._animation = value
        self.animationSourceChanged.emit()
        if self._playing:
            self._start_movie()

    @Property(bool, notify=playingChanged)
    def playing(self):
        """指示卡片是否正处于悬停播放状态。"""
        return self._playing

    @playing.setter
    def playing(self, value):
        """离开卡片立即停止动画并恢复静态封面。"""
        value = bool(value)
        if value == self._playing:
            return
        self._playing = value
        if value:
            self._start_movie()
        else:
            if self._movie:
                self._movie.stop()
            self._frame = self._still
            self.update()
        self.playingChanged.emit()

    @Property(float, notify=radiusChanged)
    def radius(self):
        """返回由外框半径减去内边距得到的内层圆角。"""
        return self._radius

    @radius.setter
    def radius(self, value):
        """更新圆角并重绘，保持窗口缩放与选中状态下的几何一致。"""
        value = max(0.0, float(value))
        if value == self._radius:
            return
        self._radius = value
        self.radiusChanged.emit()
        self.update()

    def _start_movie(self):
        """按需建立动图解码器；不预解码整份效果库。"""
        if not self._animation.isLocalFile():
            return
        if self._movie is None:
            self._movie = QMovie(self._animation.toLocalFile(), parent=self)
            self._movie.setCacheMode(QMovie.CacheNone)
            self._movie.frameChanged.connect(self._advance)
        self._movie.start()

    def _advance(self, index):
        """接收新动画帧，并使用和静态封面相同的圆角绘制路径。"""
        if self._playing and self._movie:
            self._frame = self._movie.currentImage()
            self.update()

    def paint(self, painter):
        """以纹理画刷绘制抗锯齿圆角，避免矩形裁切造成的方角和白边。"""
        image = self._frame if not self._frame.isNull() else self._still
        w, h = self.width(), self.height()
        if image.isNull() or w <= 0 or h <= 0:
            return
        scale = max(w / image.width(), h / image.height())
        dx = (w - image.width() * scale) / 2
        dy = (h - image.height() * scale) / 2
        brush = QBrush(image)
        brush.setTransform(QTransform(scale, 0, 0, scale, dx, dy))
        painter.setRenderHint(QPainter.Antialiasing, True)
        painter.setRenderHint(QPainter.SmoothPixmapTransform, True)
        painter.setPen(Qt.NoPen)
        painter.setBrush(brush)
        radius = min(self._radius, w / 2, h / 2)
        painter.drawRoundedRect(QRectF(0, 0, w, h), radius, radius)


_registered = False


def register_components():
    """仅注册一次本机缩略图控件，供应用与离屏界面测试共同使用。"""
    global _registered
    if not _registered:
        qmlRegisterType(RoundedPreview, "TimeSlice.UI", 1, 0, "RoundedPreview")
        _registered = True
