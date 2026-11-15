"""检查缩略图的圆角透明度、动画按需解码以及离开后恢复静态图。"""

import json
import sys
import time
from pathlib import Path

R = Path(__file__).resolve().parents[2]
W = R / "build/mac54/rounding-tests"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
from PySide6.QtCore import Qt, QUrl
from PySide6.QtGui import QGuiApplication, QImage, QPainter
from rounded_preview import RoundedPreview

app = QGuiApplication([])
item = RoundedPreview()
item.setWidth(120)
item.setHeight(92)
item.radius = 12
assets = R / "build/open-source/stage/assets/thumbnails"
item.source = QUrl.fromLocalFile(str(assets / "freeze_vertical.jpg"))
item.animationSource = QUrl.fromLocalFile(str(assets / "freeze_vertical.gif"))


# 以 Retina 像素密度检查抗锯齿外边缘，确保没有方角或白边。
def render(name):
    image = QImage(240, 184, QImage.Format_RGBA8888_Premultiplied)
    image.setDevicePixelRatio(2)
    image.fill(Qt.transparent)
    painter = QPainter(image)
    item.paint(painter)
    painter.end()
    image.save(str(W / name))
    return image


image = render("still.png")
assert image.pixelColor(0, 0).alpha() == 0
assert image.pixelColor(120, 92).alpha() == 255
assert item._movie is None
item.playing = True
deadline = time.monotonic() + 2
while time.monotonic() < deadline:
    app.processEvents()
    time.sleep(0.01)
assert item._movie is not None and not item._frame.isNull()
animated = render("animated.png")
assert animated.pixelColor(0, 0).alpha() == 0
item.playing = False
assert item._frame == item._still
(W / "report.json").write_text(
    json.dumps(
        dict(
            retina=True, roundedStaticAndAnimation=True, noMovieUntilHover=True, stopsOnLeave=True
        ),
        indent=2,
    )
)
print("Rounded thumbnails passed.", flush=True)
