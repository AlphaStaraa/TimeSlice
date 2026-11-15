"""检查中英文布局、昼夜分割设置、全分辨率缓存复用和剩余时间显示。"""

import json
import os
import sys
import time
from pathlib import Path

R = Path(__file__).resolve().parents[2]
W = R / "build/mac54/ui54"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
import shiboken6
from controller import PreviewProvider
from i18n import Translator
from media import ffmpeg, run
from model import EFFECTS
from next_controller import NextController
from PySide6.QtCore import QObject, QPointF, QSettings, QUrl
from PySide6.QtGui import QFontDatabase, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

app = QGuiApplication([])
app.setFont(QFontDatabase.systemFont(QFontDatabase.GeneralFont))
app.setApplicationName("TimeSliceMac54Test")
prefs = QSettings(str(W / "prefs.ini"), QSettings.IniFormat)
prefs.clear()
c = NextController(PreviewProvider(), prefs)
engine = QQmlApplicationEngine()
translator = Translator(c.language)
app.installTranslator(translator)


# 在切换语言时同步刷新 QML 译文。
def change(language):
    translator.language = language
    engine.retranslate()


c.languageChanged.connect(change)
warnings = []
engine.warnings.connect(lambda items: warnings.extend(str(x) for x in items))
engine.addImageProvider("preview", c.provider)
engine.rootContext().setContextProperty("studio", c)
engine.load(QUrl.fromLocalFile(str(R / "build/open-source/stage/app/ui/Main.qml")))
assert engine.rootObjects(), warnings
root = engine.rootObjects()[0]


# 等待异步条件成立，同时维持 Qt 事件循环。
def wait(test, timeout=90):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        app.processEvents()
        if test():
            return
        time.sleep(0.01)
    raise AssertionError(
        {
            k: c.state.get(k)
            for k in (
                "status",
                "processing",
                "processingStage",
                "processingError",
                "imageVersion",
                "error",
            )
        }
    )


# 遍历实际可见的文本对象，检查英文是否越过窗口边界。
def overflow():
    todo = [root.contentItem()]
    bad = []
    while todo:
        item = todo.pop()
        todo.extend(item.childItems())
        if not item.isVisible() or item.opacity() == 0:
            continue
        text = item.property("text")
        if not isinstance(text, str) or not text:
            continue
        if item.inherits("QQuickTextInput") or item.inherits("QQuickTextEdit"):
            continue
        point = item.mapToItem(root.contentItem(), QPointF(0, 0))
        if point.y() < 0 or point.y() > root.height():
            continue
        painted = float(item.property("paintedWidth") or item.width())
        obj = engine.newQObject(item)
        painted = min(painted, item.width()) if obj.property("elide").toInt() else painted
        align = obj.property("horizontalAlignment").toInt() or 1
        offset = (
            (item.width() - painted) / 2
            if align & 4
            else item.width() - painted
            if align & 2
            else 0
        )
        if point.x() + offset + painted > root.width() + 2:
            bad.append((text[:65], point.x() + offset, painted, root.width()))
    return bad


try:
    for e in EFFECTS:
        s = c.per_effect[e["id"]]
        assert s["shadowStrength"] == 0.25 and s["shadowWidth"] == 0.50
        assert s["shadowEnabled"] == (e["family"] == 0)
    c.setFreezeSplit(True)
    c.setFreezeDiscard(0.70)
    c.resetSettings()
    assert (
        c.state["freezeSplit"]
        and c.state["settings"]["dayNightSplit"]
        and c.state["settings"]["discardRatio"] == 0.70
    )
    assert all(c.per_effect[e["id"]]["dayNightSplit"] for e in EFFECTS if e["family"] == 0)
    c.setSourceOption("grade", True)
    c.setLanguage("en")
    root.setWidth(1120)
    root.setHeight(760)
    assert (
        "Non-Resale License 1.0" in c.localizedLicense
        and "Commercial output is permitted" in c.localizedLicense
    )
    assert "Licensed under GNU GPL" not in c.localizedLicense
    images = []
    for page in range(4):
        root.setProperty("inspectorPage", page)
        for _ in range(12):
            app.processEvents()
            time.sleep(0.01)
        image = W / f"English-page-{page}.png"
        root.grabWindow().save(str(image))
        images.append(str(image))
        bad = overflow()
        assert not bad, (page, bad)
    root.setProperty("dark", True)
    app.processEvents()
    root.grabWindow().save(str(W / "English-dark.png"))
    root.setProperty("dark", False)
    assert root.title().startswith("TimeSlice"), root.title()
    # 展开 HSL 下方的滚动区域，核对控件仍在有效面板宽度内。
    root.setProperty("inspectorPage", 0)
    app.processEvents()
    view = root.findChild(QObject, "inspectorScroll")
    flick = view.property("contentItem")
    flick.setProperty("contentY", max(0, flick.property("contentHeight") - flick.height()))
    app.processEvents()
    assert not overflow(), overflow()
    root.grabWindow().save(str(W / "English-HSL.png"))
    c.setLanguage("zh")
    c.setFreezeSplit(False)
    c.setSetting("engine", "cpu")
    c.setSetting("longEdge", 360)
    c.setSetting("quality", "standard")
    c.setSetting("encoder", "cpu")
    c.setSetting("fps", 12)
    c.setSetting("duration", 0.5)
    c.setSourceOption("dayNight", "day_to_night")
    source = R / "build/mac53/ui-tests/source.mp4"
    c.importSource(str(source))
    wait(lambda: c.state["hasImage"] and not c.state["loading"])
    c.setSourceOption("deflicker", "standard")
    assert c.state["processing"]
    assert c.uiState["processingEta"]
    wait(lambda: c.state["preparedReady"] and not c.state["processing"])
    assert (
        c.prepared_cache is not None
        and c.prepared_cache.width == 240
        and c.prepared_cache.height == 360
    )
    descriptor = c.prepared_key
    version = c.state["imageVersion"]
    c.setFreezeSplit(True)
    c.setFreezeDiscard(0.60)
    wait(lambda: c.state["imageVersion"] > version)
    assert c.prepared_key == descriptor and not c.state["processing"]
    c._state.update(progress=0.99, playing=True)
    c.last_tick = time.monotonic() - 1
    c.tick()
    assert c.state["progress"] == 1.0 and not c.state["playing"]
    c.togglePlay()
    assert c.state["progress"] == 0.0 and c.state["playing"]
    c.pause()
    out = W / "exports"
    out.mkdir(exist_ok=True)
    c.setOutput(str(out.resolve()))
    c.checked = {100}
    c.sync()
    c.startRender()
    assert c.uiState["exportEta"]
    wait(lambda: not c.state["rendering"])
    assert c.state["result"] and c.state["queue"][0]["status"] == "已完成", c.state["queue"]
    report = json.loads((Path(c.state["result"]) / "渲染记录.json").read_text())[0]
    assert report["cacheReused"] and report["settings"]["dayNightSplit"]
    movie = next(Path(c.state["result"]).glob("*.mp4"))
    run([ffmpeg(), "-v", "error", "-i", str(movie), "-f", "null", "-"], check=True)
    assert not warnings, warnings
    result = dict(
        englishBrand="TimeSlice",
        englishPagesChecked=4,
        hslFits=True,
        defaultShadowStrength=0.25,
        defaultShadowWidth=0.50,
        freezeSplit=True,
        resetPreservesSplit=True,
        sourcePreparedAtOutputSize=True,
        exportReusesCache=True,
        sourceAndExportEta=True,
        qmlWarnings=warnings,
        englishScreenshots=images,
    )
    (W / "report.json").write_text(json.dumps(result, ensure_ascii=False, indent=2))
    print(json.dumps(result, ensure_ascii=False), flush=True)
finally:
    c.shutdown()
    shiboken6.delete(root)
    shiboken6.delete(engine)
