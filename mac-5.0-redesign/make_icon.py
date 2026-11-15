import sys
from io import BytesIO
from pathlib import Path

from PIL import Image
from PySide6.QtCore import QBuffer, QIODevice, QRectF, Qt
from PySide6.QtGui import QGuiApplication, QImage, QPainter, QPainterPath
from PySide6.QtSvg import QSvgRenderer

art, png, icns = map(Path, sys.argv[1:4])
app = QGuiApplication([])
renderer = QSvgRenderer(str(art))
if not renderer.isValid():
    raise ValueError(f"Invalid icon artwork {art}")


# 执行当前渲染步骤并生成目标图像或资源。
def render(side):
    image = QImage(side, side, QImage.Format_ARGB32_Premultiplied)
    image.fill(Qt.transparent)
    painter = QPainter(image)
    painter.setRenderHint(QPainter.Antialiasing)
    scale = side / 1024
    tile = QPainterPath()
    tile.addRoundedRect(
        QRectF(83 * scale, 82 * scale, 858 * scale, 858 * scale), 215 * scale, 215 * scale
    )
    painter.setClipPath(tile)
    renderer.render(painter)
    painter.end()
    buffer = QBuffer()
    buffer.open(QIODevice.WriteOnly)
    image.save(buffer, "PNG")
    return Image.open(BytesIO(bytes(buffer.data()))).convert("RGBA")


assets = [render(side) for side in (32, 64, 128, 256, 512, 1024)]
assets[-2].save(png)
assets[-1].save(icns, format="ICNS", append_images=assets[:-1])
