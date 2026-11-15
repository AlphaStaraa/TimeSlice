"""在构建后的真实 QML 窗口验证控制器连接、操作权重、语言与短片导出。"""

import importlib
import json
import os
import sys
import time
from pathlib import Path


def main():
    """使用独立设置、合成视频和临时输出，不改用户素材或个人偏好。"""
    root_dir = Path(__file__).resolve().parents[1]
    stage = root_dir / "build/check/stage/app"
    work = root_dir / "build/check/ui"
    work.mkdir(parents=True, exist_ok=True)
    sys.path.insert(0, str(stage))
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    os.environ["TIMESLICE_FORCE_CPU"] = "1"
    qt = importlib.import_module("PySide6.QtCore")
    gui = importlib.import_module("PySide6.QtGui")
    qml = importlib.import_module("PySide6.QtQml")
    shiboken = importlib.import_module("shiboken6")
    media = importlib.import_module("media")
    effects = importlib.import_module("model").EFFECTS
    provider = importlib.import_module("controller").PreviewProvider()
    controller_type = importlib.import_module("next_controller").NextController
    translator_type = importlib.import_module("i18n").Translator
    app = gui.QGuiApplication([])
    app.setFont(gui.QFontDatabase.systemFont(gui.QFontDatabase.GeneralFont))
    app.setApplicationName("TimeSlice-maintenance-smoke")
    prefs = qt.QSettings(str(work / "preferences.ini"), qt.QSettings.IniFormat)
    prefs.clear()
    # 隔离测试缓存，避免写入用户自己的 Library/Caches 或其他系统目录。
    original_location = qt.QStandardPaths.writableLocation
    qt.QStandardPaths.writableLocation = lambda location: (
        str(work / "cache")
        if location == qt.QStandardPaths.CacheLocation
        else original_location(location)
    )
    controller = controller_type(provider, prefs)
    engine = qml.QQmlApplicationEngine()
    translator = translator_type(controller.language)
    app.installTranslator(translator)

    def retranslate(language):
        """真实调用语言切换和 QML 重新翻译。"""
        translator.language = language
        engine.retranslate()

    controller.languageChanged.connect(retranslate)
    warnings = []
    engine.warnings.connect(lambda items: warnings.extend(str(item) for item in items))
    engine.addImageProvider("preview", provider)
    engine.rootContext().setContextProperty("studio", controller)
    engine.load(qt.QUrl.fromLocalFile(str(stage / "ui/Main.qml")))
    window = engine.rootObjects()[0] if engine.rootObjects() else None

    def wait(condition, seconds=60):
        """等待后台任务的同时处理界面信号，失败时输出当前状态。"""
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            app.processEvents()
            if condition():
                return
            time.sleep(0.01)
        raise AssertionError(controller.uiState)

    try:
        assert window is not None, warnings
        app.processEvents()
        meta = controller.metaObject()
        for signature in (
            "importSource(QString)",
            "setHsl(int,QString,double)",
            "setPreviewViewport(double,double,double)",
            "startRender()",
            "moveSelection(int,int)",
            "setLanguage(QString)",
        ):
            assert meta.indexOfMethod(signature) >= 0, signature
        import_button = window.findChild(qt.QObject, "importVideoAction")
        export_button = window.findChild(qt.QObject, "exportVideoAction")
        assert import_button.property("primary")
        assert not export_button.property("primary") and not export_button.property("enabled")
        source = work / "source.mp4"
        media.run(
            [
                media.ffmpeg(),
                "-v",
                "error",
                "-y",
                "-f",
                "lavfi",
                "-i",
                "testsrc2=size=160x96:rate=12:duration=1",
                "-c:v",
                "libx264",
                "-pix_fmt",
                "yuv420p",
                str(source),
            ]
        )
        controller.importSource(str(source))
        wait(lambda: not controller.state["loading"] and controller.state["hasImage"])
        assert export_button.property("primary") and export_button.property("enabled")
        assert not import_button.property("primary")
        for language in ("en", "zh"):
            controller.setLanguage(language)
            for page in range(4):
                window.setProperty("inspectorPage", page)
                app.processEvents()
        controller.setLanguage("en")
        export_text = export_button.findChild(qt.QObject, "actionText")
        assert export_text is not None
        for width in (1320, 1120):
            window.setWidth(width)
            for count in (1, 2, 46):
                controller.checked = {effect["id"] for effect in effects[:count]}
                controller.sync()
                for _ in range(5):
                    app.processEvents()
                assert not export_text.property("truncated"), (
                    width,
                    count,
                    export_text.property("text"),
                )
                assert export_button.x() + export_button.width() <= window.width()
        window.setWidth(1320)
        controller.setLanguage("zh")
        controller.checked = {2}
        controller.setActive(2)
        for key, value in {
            "duration": 0.5,
            "fps": 12,
            "longEdge": 160,
            "engine": "cpu",
            "quality": "full",
        }.items():
            controller.setSetting(key, value)
        output = work / "output"
        output.mkdir(exist_ok=True)
        controller.setOutput(str(output))
        wait(lambda: not controller.source_timer.isActive() and not controller.state["processing"])
        controller.startRender()
        assert controller.state["rendering"], controller.state
        wait(lambda: not controller.state["rendering"], seconds=90)
        assert not controller.state["error"], controller.state
        videos = sorted(output.rglob("*.mp4"))
        assert videos, controller.state
        media.run([media.ffmpeg(), "-v", "error", "-i", str(videos[-1]), "-f", "null", "-"])
        assert not warnings, warnings
        report = dict(
            qtSlots=True,
            primaryActions=True,
            languagePages=8,
            englishExportButton="1/2/46 items at 1320/1120px, no elision",
            shortCpuExport=True,
            decodedFile=str(videos[-1]),
            qmlWarnings=warnings,
        )
        (work / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2))
        print(json.dumps(report, ensure_ascii=False))
    finally:
        controller.shutdown()
        if window is not None:
            shiboken.delete(window)
        shiboken.delete(engine)
        qt.QStandardPaths.writableLocation = original_location


if __name__ == "__main__":
    main()
