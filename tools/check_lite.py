"""验证轻量版真实界面、单/多选、参数、缓存复用和可解码成片。"""

import importlib
import json
import os
import sys
import time
from pathlib import Path

from quality_ui import check_bitrate_controls


def main():
    """使用独立设置与缓存执行完整小规模工作流，并保存实际界面预览。"""
    root = Path(__file__).resolve().parents[1]
    stage = root / "build/lite/stage/app"
    work = root / "build/lite/verification"
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
    controller = importlib.import_module("lite_controller").LiteController
    provider = importlib.import_module("controller").PreviewProvider
    i18n = importlib.import_module("i18n")
    i18n.EN.update(json.loads((stage / "resources/lite-en.json").read_text()))
    app = gui.QGuiApplication([])
    app.setApplicationName("TimeSliceLiteVerification")
    app.setFont(gui.QFontDatabase.systemFont(gui.QFontDatabase.GeneralFont))
    original_location = qt.QStandardPaths.writableLocation
    qt.QStandardPaths.writableLocation = lambda key: (
        str(work / "cache") if key == qt.QStandardPaths.CacheLocation else original_location(key)
    )
    prefs = qt.QSettings(str(work / "prefs.ini"), qt.QSettings.IniFormat)
    prefs.clear()
    (work / "cache/usage.json").unlink(missing_ok=True)
    studio = controller(provider(), prefs)
    engine = qml.QQmlApplicationEngine()
    translator = i18n.Translator(studio.language)
    app.installTranslator(translator)

    def language_changed(language):
        """触发真实 QML 翻译绑定更新。"""
        translator.language = language
        engine.retranslate()

    studio.languageChanged.connect(language_changed)
    warnings = []
    engine.warnings.connect(lambda items: warnings.extend(str(item) for item in items))
    engine.addImageProvider("preview", studio.provider)
    engine.rootContext().setContextProperty("studio", studio)
    engine.load(qt.QUrl.fromLocalFile(str(stage / "ui/Main.qml")))
    window = engine.rootObjects()[0] if engine.rootObjects() else None

    def wait(condition, seconds=90):
        """处理 Qt 事件直至后台条件满足，失败附带用户可见错误。"""
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            app.processEvents()
            if condition():
                return
            time.sleep(0.01)
        raise AssertionError(
            {key: studio.state.get(key) for key in ("status", "error", "loading", "rendering")}
        )

    try:
        assert window, warnings
        app.processEvents()
        assert not hasattr(studio, "renderPhotos") and not hasattr(studio, "setSourceOption")
        assert not (
            {"cv2", "rawpy", "exifread", "source_processing", "photo_job"} & set(sys.modules)
        )
        assert not studio.state["output"] and not studio.batch
        studio.setActive(104)
        assert studio.checked == {104}
        studio.setSetting("rotationStartAngle", 90)
        assert studio.state["settings"]["rotationStartAngle"] == 90
        studio.setFreezeSplit(True)
        studio.setFreezeDiscard(0.7)
        studio.resetSettings()
        assert studio.state["settings"]["discardRatio"] == 0.7
        studio.setFreezeSplit(False)
        studio.importExample()
        wait(lambda: studio.state["hasImage"] and not studio.state["loading"])
        studio.setActive(100)
        studio.seek(0.6)
        version = studio.state["imageVersion"]
        wait(lambda: studio.state["imageVersion"] > version)
        window.grabWindow().save(str(work / "lite-zh.png"))
        studio.setLanguage("en")
        app.processEvents()
        window.grabWindow().save(str(work / "lite-en.png"))
        studio.setBatch(True)
        studio.toggleEffect(101)
        studio.toggleEffect(102)
        studio.moveSelection(102, 0)
        assert studio.selected_order == [102, 100, 101]
        studio.removeSelection(101)
        assert studio.checked == {100, 102}
        window.grabWindow().save(str(work / "lite-batch.png"))
        studio.setSetting("duration", 0.75)
        studio.setSetting("angle", 37.5)
        preset = work / "切片参数.json"
        source_before = studio.info["path"]
        studio.exportPreset(str(preset))
        studio.setBatch(False)
        studio.setActive(2)
        studio.importPreset(str(preset))
        assert studio.selected_order == [102, 100]
        assert studio.batch and studio.info["path"] == source_before
        assert studio.per_effect[100]["duration"] == 0.75
        assert studio.per_effect[100]["angle"] == 37.5
        packet = json.loads(preset.read_text(encoding="utf-8"))
        packet["effects"][0]["settings"]["mapPath"] = "unexpected-external-file"
        invalid = work / "invalid-preset.json"
        invalid.write_text(json.dumps(packet), encoding="utf-8")
        studio.importPreset(str(invalid))
        assert studio.state["error"] and studio.selected_order == [102, 100]
        studio.dismissError()
        studio.setBatch(False)
        studio.setActive(2)
        for key, value in {
            "longEdge": 160,
            "fps": 12,
            "duration": 0.5,
            "encoder": "cpu",
            "engine": "cpu",
        }.items():
            studio.setSetting(key, value)
        output = work / "exports"
        output.mkdir(exist_ok=True)
        studio.setOutput(str(output))
        check_bitrate_controls(window, studio, qt, app, 1)
        studio.setActive(2)
        reused = []
        for _ in range(2):
            studio.startRender()
            wait(lambda: not studio.state["rendering"])
            assert not studio.state["error"], studio.state["error"]
            folder = Path(studio.state["result"])
            report = json.loads((folder / "渲染记录.json").read_text())[0]
            reused.append(report["cacheReused"])
            assert report["encoding"]["targetMbps"] == 73.5
            assert report["settings"]["_exportDither"]
            movie = next(folder.glob("*.mp4"))
            media.run([media.ffmpeg(), "-v", "error", "-i", str(movie), "-f", "null", "-"])
        assert reused == [False, True], reused
        assert not studio.metrics.rows(), "Metrics must stay disabled by default"
        studio.setMetricsEnabled(True)
        studio.startRender()
        wait(lambda: not studio.state["rendering"])
        metrics_path = work / "metrics-export.json"
        studio.exportMetrics(str(metrics_path))
        metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
        assert metrics["exports"] == 1 and metrics["successes"] == 1
        assert studio.info["path"] not in metrics_path.read_text(encoding="utf-8")
        studio.setMetricsEnabled(False)
        assert not warnings, warnings
        result = dict(
            singleAndBatch=True,
            rotation=True,
            dayNight=True,
            sourceCacheReused=reused,
            presetsRoundTrip=True,
            invalidPresetRejected=True,
            optInLocalMetrics=True,
            exportsDecoded=True,
            noHeavyImports=True,
            qmlWarnings=warnings,
        )
        (work / "report.json").write_text(json.dumps(result, ensure_ascii=False, indent=2))
        print(json.dumps(result, ensure_ascii=False))
    finally:
        studio.shutdown()
        if window:
            shiboken.delete(window)
        shiboken.delete(engine)
        qt.QStandardPaths.writableLocation = original_location


if __name__ == "__main__":
    main()
