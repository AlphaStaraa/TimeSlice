import json
import os
import sys
import threading
import time
from pathlib import Path

R = Path(__file__).resolve().parents[2]
W = R / "build/mac53/ui-tests"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
import next_controller as next_module
from controller import PreviewProvider
from i18n import Translator
from media import ffmpeg, run
from next_controller import NextController
from PySide6.QtCore import QObject, QSettings, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

app = QGuiApplication([])
app.setApplicationName("ShiRenMac53Check")
prefs = QSettings(str(W / "preferences.ini"), QSettings.IniFormat)
prefs.clear()
provider = PreviewProvider()
c = NextController(provider, prefs)
engine = QQmlApplicationEngine()
translator = Translator(c.language)
app.installTranslator(translator)
c.languageChanged.connect(
    lambda lang: (setattr(translator, "language", lang), engine.retranslate())
)
errors = []
engine.warnings.connect(lambda values: errors.extend(str(x) for x in values))
engine.addImageProvider("preview", provider)
engine.rootContext().setContextProperty("studio", c)
engine.load(QUrl.fromLocalFile(str(R / "build/open-source/stage/app/ui/Main.qml")))
assert engine.rootObjects(), errors
root = engine.rootObjects()[0]


# 轮询异步任务的完成条件并设置等待上限。
def wait(test, timeout=40):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        app.processEvents()
        if test():
            return
        time.sleep(0.01)
    raise AssertionError(
        {
            k: c.state.get(k)
            for k in (
                "status",
                "error",
                "loading",
                "processing",
                "processingError",
                "imageVersion",
                "previewWidth",
            )
        }
    )


# 让界面完成布局和绑定更新后再进行观察。
def settle(seconds=0.15):
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        app.processEvents()
        time.sleep(0.005)


# 收集界面中的可见文本用于语言与布局检查。
def texts():
    seen = set()
    values = []
    todo = [root, root.contentItem()]
    while todo:
        obj = todo.pop()
        if obj is None or obj in seen:
            continue
        seen.add(obj)
        value = obj.property("text")
        if value is not None and len(str(value)) < 200:
            values.append(str(value))
        todo.extend(obj.children())
        if hasattr(obj, "childItems"):
            todo.extend(obj.childItems())
        item = obj.property("contentItem")
        if isinstance(item, QObject):
            todo.append(item)
    return values


try:
    assert root.property("inspectorPage") == 0
    assert c.state["count"] == 60
    tabs = root.findChild(QObject, "inspectorSegments")
    assert tabs.property("labels").toVariant() == ["素材", "效果", "阴影", "导出"]
    grid = root.findChild(QObject, "effectGrid")
    assert grid
    root.setHeight(680)
    settle()
    grid.setProperty("contentY", 230.0)
    settle()
    before = grid.property("contentY")
    resets = []
    c.effect_model.modelReset.connect(lambda: resets.append(True))
    key = c.state["effects"][-1]["catalogueKey"]
    c.toggleCatalogue(key)
    settle()
    c.toggleCatalogue(key)
    settle()
    assert grid.property("contentY") == before, (before, grid.property("contentY"))
    assert not resets
    c.setLanguage("en")
    settle()
    assert root.property("inspectorPage") == 0
    assert "Freeze then slice" not in texts()
    c.setLanguage("zh")
    settle()
    c.setSetting("engine", "cpu")
    c.setSetting("longEdge", 360)
    c.setSetting("fps", 12)
    c.setSetting("encoder", "cpu")
    c.setSetting("duration", 0.8)
    c.setPreviewViewport(300, 450, 1)
    source = W / "source.mp4"
    run(
        [
            ffmpeg(),
            "-v",
            "error",
            "-y",
            "-f",
            "lavfi",
            "-i",
            "testsrc2=size=240x360:rate=12",
            "-t",
            "3",
            "-c:v",
            "libx264",
            "-pix_fmt",
            "yuv420p",
            str(source),
        ]
    )
    c.importSource(str(source))
    wait(lambda: c.state["hasImage"] and not c.state["loading"])
    old_version = c.state["imageVersion"]
    old_cache = c.cache.folder
    c.setSourceOption("dayNight", "day_to_night")
    c.setSourceOption("grade", True)
    wait(lambda: c.state["imageVersion"] > old_version)
    assert c.cache.folder == old_cache and not c.state["processing"]
    old_version = c.state["imageVersion"]
    c.setHsl(0, "hue", 50)
    c.setHsl(5, "luminance", -60)
    wait(lambda: c.state["imageVersion"] > old_version)
    assert c.cache.folder == old_cache and not c.state["processing"]
    gate = threading.Event()
    entered = threading.Event()
    actual_process = next_module.process_cache

    # 在测试中暂时门控后台任务，验证预览不会被其阻塞。
    def held(*args, **kwargs):
        entered.set()
        gate.wait(15)
        return actual_process(*args, **kwargs)

    next_module.process_cache = held
    c.setSourceOption("deflicker", "standard")
    assert c.state["processing"]
    wait(lambda: entered.is_set())
    old_version = c.state["imageVersion"]
    c.setActive(102)
    c.seek(0.72)
    wait(lambda: c.state["imageVersion"] > old_version)
    assert c.state["processing"] and c.active == 102
    gate.set()
    wait(lambda: not c.state["processing"])
    assert not c.state["processingError"], c.state["processingError"]
    assert c.state["deflickerStatus"] == "已完成"
    old_version = c.state["imageVersion"]
    c.setActive(101)
    wait(lambda: c.state["imageVersion"] > old_version)
    # Disable processing and return to the original cache without a stale preview.
    old_version = c.state["imageVersion"]
    c.setSourceOption("deflicker", "off")
    wait(lambda: not c.state["processing"] and c.state["imageVersion"] > old_version)
    assert c.cache is c.original_cache
    c.checked = {102}
    c.setActive(102)
    c.setSetting("duration", 0.6)
    c.sync()
    output = W / "exports"
    output.mkdir(exist_ok=True)
    c.setOutput(str(output.resolve()))
    c.startRender()
    wait(lambda: not c.state["rendering"], 60)
    assert c.state["result"] and all(q["status"] == "已完成" for q in c.state["queue"]), c.state[
        "queue"
    ]
    movie = next(Path(c.state["result"]).glob("*.mp4"))
    run([ffmpeg(), "-v", "error", "-i", str(movie), "-f", "null", "-"])
    old_version = c.state["imageVersion"]
    c.importSource(str(source))
    wait(lambda: not c.state["loading"] and c.state["imageVersion"] > old_version)
    old_version = c.state["imageVersion"]
    c.seek(0.5)
    wait(lambda: c.state["imageVersion"] > old_version)
    root.grabWindow().save(str(W / "mac53-ui.png"))
    assert not errors, errors
    report = dict(
        scrollStayedAt=before,
        modelResetsOnCheckbox=len(resets),
        inspectorOrder=["素材", "效果", "阴影", "导出"],
        liveGradeWithoutReprocessing=True,
        hsl=True,
        previewWhileProcessing=True,
        eagerDeflicker=True,
        reimport=True,
        exportDecoded=str(movie),
        qmlWarnings=errors,
    )
    (W / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2))
    print(json.dumps(report, ensure_ascii=False), flush=True)
finally:
    if "gate" in globals():
        gate.set()
    c.shutdown()
    root.close()
