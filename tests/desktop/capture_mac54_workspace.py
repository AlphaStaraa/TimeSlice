"""用真实上海中心代理素材保存最新版界面验收图，不进入发布程序。"""

import os
import sys
import time
from pathlib import Path

R = Path(__file__).resolve().parents[2]
W = R / "build/mac54/workspace-capture"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
import shiboken6
from controller import PreviewProvider
from next_controller import NextController
from PySide6.QtCore import QSettings, QUrl
from PySide6.QtGui import QFontDatabase, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

app = QGuiApplication([])
app.setApplicationName("TimeSliceWorkspaceCapture")
app.setFont(QFontDatabase.systemFont(QFontDatabase.GeneralFont))
prefs = QSettings(str(W / "prefs.ini"), QSettings.IniFormat)
prefs.clear()
c = NextController(PreviewProvider(), prefs)
engine = QQmlApplicationEngine()
engine.addImageProvider("preview", c.provider)
engine.rootContext().setContextProperty("studio", c)
engine.load(QUrl.fromLocalFile(str(R / "build/open-source/stage/app/ui/Main.qml")))
root = engine.rootObjects()[0]


# 等待后台读取与预览完成，避免把旧画面保存成验收图。
def wait(test):
    end = time.monotonic() + 80
    while time.monotonic() < end:
        app.processEvents()
        if test():
            return
        time.sleep(0.01)
    raise AssertionError(c.state["status"])


try:
    c.checked = {100, 102, 104}
    c.sync()
    c.setFreezeSplit(True)
    c.setSourceOption("dayNight", "day_to_night")
    c.setSourceOption("grade", True)
    c.importSource(str(R / "build/mac-next/demo/Shanghai-proxy.mp4"))
    wait(lambda: c.state["hasImage"] and not c.state["loading"])
    previous = c.state["imageVersion"]
    c.seek(1.0)
    wait(lambda: c.state["imageVersion"] > previous)
    root.setProperty("inspectorPage", 1)
    root.setProperty("dark", True)
    for _ in range(20):
        app.processEvents()
        time.sleep(0.01)
    root.grabWindow().save(str(W / "TimeSlice-5.4-workspace.png"))
    root.setProperty("inspectorPage", 2)
    app.processEvents()
    root.grabWindow().save(str(W / "TimeSlice-5.4-shadows.png"))
    print(W, flush=True)
finally:
    c.shutdown()
    shiboken6.delete(root)
    shiboken6.delete(engine)
