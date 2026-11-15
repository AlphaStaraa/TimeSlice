"""检查真实指针拖动排序、横竖屏队列位置，以及输出文件编号与进度顺序。"""

import json
import os
import sys
import time
from pathlib import Path

R = Path(__file__).resolve().parents[2]
W = R / "build/mac54/order-tests"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
import shiboken6
from controller import PreviewProvider
from media import ffmpeg, run
from next_controller import NextController
from PySide6.QtCore import QObject, QPointF, QSettings, Qt, QUrl
from PySide6.QtGui import QFontDatabase, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtTest import QTest

app = QGuiApplication([])
app.setApplicationName("TimeSliceOrderTest")
app.setFont(QFontDatabase.systemFont(QFontDatabase.GeneralFont))
prefs = QSettings(str(W / "prefs.ini"), QSettings.IniFormat)
prefs.clear()
c = NextController(PreviewProvider(), prefs)
engine = QQmlApplicationEngine()
warnings = []
engine.warnings.connect(lambda xs: warnings.extend(str(x) for x in xs))
engine.addImageProvider("preview", c.provider)
engine.rootContext().setContextProperty("studio", c)
engine.load(QUrl.fromLocalFile(str(R / "build/open-source/stage/app/ui/Main.qml")))
assert engine.rootObjects(), warnings
root = engine.rootObjects()[0]


# 等待布局、异步预览或导出完成，并限定测试等待时间。
def wait(test, timeout=60):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        app.processEvents()
        if test():
            return
        time.sleep(0.01)
    raise AssertionError(
        {k: c.state.get(k) for k in ("selectedOrder", "rendering", "status", "error")}
    )


# 为拖动选取当前可见方向的卡片，忽略另一方向隐藏视图中的委托。
def card(eid):
    todo = [root.contentItem()]
    while todo:
        item = todo.pop()
        todo.extend(item.childItems())
        if item.objectName() == "selectedCard_" + str(eid) and item.isVisible():
            return item
    raise AssertionError("Missing visible card " + str(eid))


try:
    c.checked = {100, 101, 102}
    c.sync()
    QTest.qWait(250)
    assert c.selected_order == [100, 101, 102]
    moved = []
    c.selection_model.rowsMoved.connect(lambda *args: moved.append(True))
    a = card(100)
    b = card(102)
    start = a.mapToScene(QPointF(a.width() / 2, a.height() / 2))
    end = b.mapToScene(QPointF(b.width() / 2, b.height() / 2))
    QTest.mousePress(root, Qt.LeftButton, Qt.NoModifier, start.toPoint())
    for step in range(1, 17):
        point = start + (end - start) * (step / 16)
        QTest.mouseMove(root, point.toPoint(), 20)
        QTest.qWait(25)
    QTest.mouseRelease(root, Qt.LeftButton, Qt.NoModifier, end.toPoint())
    QTest.qWait(220)
    assert c.selected_order == [101, 102, 100], c.selected_order
    assert abs(card(100).x()) < 0.1 and abs(card(100).y()) < 0.1, (card(100).x(), card(100).y())
    assert moved and [row["id"] for row in c.selection_model.rows] == c.selected_order
    root.grabWindow().save(str(W / "horizontal-order.png"))
    # 点击队列卡片的移除区域，应同步取消左侧勾选。
    item = card(102)
    point = item.mapToScene(QPointF(item.width() - 15, 15))
    QTest.mouseClick(root, Qt.LeftButton, Qt.NoModifier, point.toPoint())
    QTest.qWait(160)
    assert c.selected_order == [101, 100] and 102 not in c.checked, c.selected_order
    c.toggleCatalogue("freeze_diagonal")
    QTest.qWait(160)
    assert c.selected_order == [101, 100, 102]
    source = R / "build/mac53/ui-tests/source.mp4"
    c.setSetting("engine", "cpu")
    c.setSetting("encoder", "cpu")
    c.setSetting("fps", 12)
    c.setSetting("longEdge", 360)
    c.importSource(str(source))
    wait(lambda: c.state["hasImage"] and not c.state["loading"])
    assert root.property("portraitSource") and root.findChild(QObject, "selectedSide").isVisible()
    assert not root.findChild(QObject, "selectedBottom").isVisible()
    root.grabWindow().save(str(W / "portrait-order.png"))
    for eid in c.selected_order:
        c.per_effect[eid]["duration"] = 0.25
    c.sync()
    out = W / "exports"
    out.mkdir(exist_ok=True)
    c.setOutput(str(out.resolve()))
    c.startRender()
    assert [entry["id"] for entry in c.state["queue"]] == [101, 100, 102]
    wait(lambda: not c.state["rendering"])
    folder = Path(c.state["result"])
    report = json.loads((folder / "渲染记录.json").read_text())
    assert [row["effect"]["id"] for row in report] == [101, 100, 102], report
    for row in report:
        run([ffmpeg(), "-v", "error", "-i", row["output"], "-f", "null", "-"], check=True)
    assert not warnings, warnings
    result = dict(
        pointerDragReordered=True,
        modelMoveEvents=len(moved),
        removeUnchecksLibrary=True,
        portraitSide=True,
        landscapeBottom=True,
        separateExportOrder=[101, 100, 102],
        outputsDecoded=True,
        qmlWarnings=warnings,
    )
    (W / "report.json").write_text(json.dumps(result, indent=2))
    print(json.dumps(result), flush=True)
finally:
    c.shutdown()
    shiboken6.delete(root)
    shiboken6.delete(engine)
