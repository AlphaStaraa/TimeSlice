"""检查玻璃菜单、标签居中、原素材一致性，以及悬停没有提示浮框。"""

import hashlib
import json
import os
import sys
from pathlib import Path

R = Path(__file__).resolve().parents[2]
W = R / "build/mac541/glass-tests"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
import shiboken6
from controller import PreviewProvider
from i18n import Translator
from next_controller import NextController
from PySide6.QtCore import QPointF, QSettings, Qt, QUrl
from PySide6.QtGui import QFontDatabase, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtTest import QTest

app = QGuiApplication([])
app.setFont(QFontDatabase.systemFont(QFontDatabase.GeneralFont))
app.setApplicationName("TimeSlice541GlassCheck")
prefs = QSettings(str(W / "prefs.ini"), QSettings.IniFormat)
prefs.clear()
c = NextController(PreviewProvider(), prefs)
engine = QQmlApplicationEngine()
translator = Translator(c.language)
app.installTranslator(translator)


# 同步 QML 翻译并保持检查器所处页面。
def change(language):
    translator.language = language
    engine.retranslate()


c.languageChanged.connect(change)
warnings = []
engine.warnings.connect(lambda values: warnings.extend(str(x) for x in values))
engine.addImageProvider("preview", c.provider)
engine.rootContext().setContextProperty("studio", c)
engine.load(QUrl.fromLocalFile(str(R / "build/open-source/stage/app/ui/Main.qml")))
assert engine.rootObjects(), warnings
root = engine.rootObjects()[0]


# 遍历视觉树，包含 ListView 动态创建的选项和卡片。
def visual_items():
    todo = [root.contentItem()]
    result = []
    while todo:
        item = todo.pop()
        result.append(item)
        todo.extend(item.childItems())
    return result


# 用 Qt 指针事件点击控件中心，走正常菜单激活流程。
def click(item):
    point = item.mapToScene(QPointF(item.width() / 2, item.height() / 2))
    QTest.mouseClick(root, Qt.LeftButton, Qt.NoModifier, point.toPoint())
    QTest.qWait(120)


try:
    QTest.qWait(200)
    original = json.loads((R / "build/mac541/restored-previews.json").read_text())["files"]
    for name, digest in original.items():
        assert (
            hashlib.sha256(
                (R / "build/open-source/stage/assets/thumbnails" / name).read_bytes()
            ).hexdigest()
            == digest
        ), name
    assert len(original) == 92
    for split in (False, True):
        c.setFreezeSplit(split)
        QTest.qWait(100)
        for item in visual_items():
            if item.objectName() == "effectThumbnail":
                assert "_daynight" not in item.property("source").toString()
    centered = 0
    for language in ("zh", "en"):
        c.setLanguage(language)
        QTest.qWait(300)
        for dark in (False, True):
            root.setProperty("dark", dark)
            QTest.qWait(250)
            groups = [
                item
                for item in visual_items()
                if item.isVisible()
                and item.objectName() in ("actionContentGroup", "segmentContentGroup")
            ]
            for item in groups:
                parent = item.parentItem()
                assert abs(item.x() + item.width() / 2 - parent.width() / 2) < 0.6, (
                    item.objectName(),
                    item.x(),
                    item.width(),
                    parent.width(),
                    language,
                    dark,
                )
                assert abs(item.y() + item.height() / 2 - parent.height() / 2) < 0.6, (
                    item.objectName()
                )
                centered += 1
            controls = [
                item
                for item in visual_items()
                if item.isVisible() and item.property("glassChoiceControl")
            ]
            source_choices = [
                item
                for item in controls
                if item.property("displayText") in ("关闭", "Off", "固定机位锁定", "Camera lock")
            ]
            control = min(source_choices, key=lambda item: item.mapToScene(QPointF()).y())
            click(control)
            popup = engine.newQObject(control).property("popup").toQObject()
            assert popup.property("visible")
            options = [
                item
                for item in visual_items()
                if item.isVisible() and item.objectName() == "glassChoiceOption"
            ]
            assert len(options) == 3, [(item.property("text")) for item in options]
            for item in options:
                content = item.property("contentItem")
                js = engine.newQObject(content)
                assert js.property("horizontalAlignment").toInt() == int(Qt.AlignHCenter)
                assert js.property("verticalAlignment").toInt() == int(Qt.AlignVCenter)
            root.grabWindow().save(
                str(W / f"glass-menu-{language}-{'dark' if dark else 'light'}.png")
            )
            if language == "zh" and not dark:
                chosen = next(item for item in options if item.property("index") == 1)
                click(chosen)
                assert c.source_options["stabilize"] == "lock" and not popup.property("visible")
            else:
                QTest.keyClick(root, Qt.Key_Escape)
                QTest.qWait(80)
    # 菜单只在点击时出现，普通悬停不创建 Tooltip。
    point = control.mapToScene(QPointF(control.width() / 2, control.height() / 2))
    QTest.mouseMove(root, point.toPoint())
    QTest.qWait(900)
    visible_tips = [
        item for item in visual_items() if item.isVisible() and item.inherits("QQuickToolTip")
    ]
    assert not visible_tips
    assert "ToolTip." not in (R / "build/open-source/stage/app/ui/Main.qml").read_text()
    assert not warnings, warnings
    result = dict(
        originalPreviewFiles=92,
        assetsByteIdentical=True,
        dayNightUsesOriginalThumbnails=True,
        centeredGroupsChecked=centered,
        glassMenusChineseEnglish=True,
        lightAndDark=True,
        normalMenuActivation=True,
        noHoverTooltips=True,
        qmlWarnings=warnings,
    )
    (W / "report.json").write_text(json.dumps(result, indent=2))
    print(json.dumps(result), flush=True)
finally:
    c.shutdown()
    shiboken6.delete(root)
    shiboken6.delete(engine)
