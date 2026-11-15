"""持续状态更新时，错误弹窗一次确定必须关闭且不能残留空白遮罩。"""

import argparse
import os
import sys
import time
from pathlib import Path

os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--profile", choices=("full", "lite"), required=True)
args = parser.parse_args()
stage = ROOT / ("build/check/stage/app" if args.profile == "full" else "build/lite/stage/app")
sys.path.insert(0, str(stage))
from controller import PreviewProvider
from PySide6.QtCore import QMetaObject, QObject, QSettings, QTimer
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from rounded_preview import register_components

if args.profile == "full":
    from next_controller import NextController as Controller
else:
    from lite_controller import LiteController as Controller

app = QGuiApplication([])
register_components()
work = ROOT / "build/video-only-104"
prefs = QSettings(str(work / (args.profile + "-close.ini")), QSettings.IniFormat)
prefs.clear()
studio = Controller(PreviewProvider(), prefs)
engine = QQmlApplicationEngine()
engine.addImageProvider("preview", studio.provider)
engine.rootContext().setContextProperty("studio", studio)
engine.load(str(stage / "ui/Main.qml"))
assert engine.rootObjects()
window = engine.rootObjects()[0]
dialog = window.findChild(QObject, "errorDialog")
assert dialog
pulse = QTimer()
pulse.setInterval(8)
pulse.timeout.connect(studio.changed.emit)
pulse.start()


def advance(seconds):
    """等待真实Qt弹窗动画和连续状态信号完成。"""
    until = time.monotonic() + seconds
    while time.monotonic() < until:
        app.processEvents()
        time.sleep(0.004)


try:
    for attempt in range(3):
        studio._state["error"] = "UI close regression"
        studio.changed.emit()
        advance(0.35)
        assert dialog.property("visible")
        footer = dialog.property("footer")
        button = next(x for x in footer.findChildren(QObject) if x.inherits("QQuickAbstractButton"))
        assert QMetaObject.invokeMethod(button, "clicked")
        advance(0.45)
        assert not dialog.property("visible"), "A single OK click left a blank popup"
        assert not studio.state["error"]
    print(args.profile, "three single-click closes passed under 8ms status updates")
finally:
    pulse.stop()
    studio.shutdown()
    import shiboken6

    shiboken6.delete(engine)
