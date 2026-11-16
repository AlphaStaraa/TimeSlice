"""真实QML导入原生HDR并逐个导出四种格式，验证预览与缓存身份。"""

import argparse
import importlib
import json
import os
import sys
import time
from pathlib import Path


def main():
    """使用独立偏好和缓存，不改用户工作会话。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--profile", choices=("full", "lite"), required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    stage = root / ("build/check/stage/app" if args.profile == "full" else "build/lite/stage/app")
    sys.path.insert(0, str(stage))
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    os.environ["TIMESLICE_FORCE_CPU"] = "1"
    qt = importlib.import_module("PySide6.QtCore")
    gui = importlib.import_module("PySide6.QtGui")
    qml = importlib.import_module("PySide6.QtQml")
    shiboken = importlib.import_module("shiboken6")
    media = importlib.import_module("media")
    provider = importlib.import_module("controller").PreviewProvider()
    controller = importlib.import_module(
        "next_controller" if args.profile == "full" else "lite_controller"
    )
    kind = controller.NextController if args.profile == "full" else controller.LiteController
    work = args.output.resolve()
    work.mkdir(parents=True, exist_ok=True)
    app = gui.QGuiApplication([])
    app.setApplicationName("TimeSlicePrecisionVerification")
    old_location = qt.QStandardPaths.writableLocation
    qt.QStandardPaths.writableLocation = lambda key: (
        str(work / "cache") if key == qt.QStandardPaths.CacheLocation else old_location(key)
    )
    preferences = qt.QSettings(str(work / "prefs.ini"), qt.QSettings.IniFormat)
    preferences.clear()
    studio = kind(provider, preferences)
    engine = qml.QQmlApplicationEngine()
    warnings = []
    engine.warnings.connect(lambda entries: warnings.extend(str(e) for e in entries))
    engine.addImageProvider("preview", provider)
    engine.rootContext().setContextProperty("studio", studio)
    engine.load(qt.QUrl.fromLocalFile(str(stage / "ui/Main.qml")))
    window = engine.rootObjects()[0] if engine.rootObjects() else None

    def wait(condition, limit=120):
        """等待工作同时处理Qt事件，任何产品错误立即失败。"""
        deadline = time.monotonic() + limit
        while time.monotonic() < deadline:
            app.processEvents()
            if studio.state["error"]:
                raise RuntimeError(studio.state["error"])
            if condition():
                return
            time.sleep(0.01)
        raise TimeoutError(studio.state)

    results = []
    try:
        assert window is not None, warnings
        studio.importSource(str(args.source.resolve()))
        wait(lambda: studio.state["hasImage"] and not studio.state["loading"])
        assert studio.info["hdr"] and studio.cache.meta["pixelFormat"] == "x2rgb10le"
        studio.checked = {100}
        studio.setActive(100)
        for k, v in dict(duration=0.5, fps=12, longEdge=160, engine="cpu", encoder="cpu").items():
            studio.setSetting(k, v)
        out = work / "exports"
        out.mkdir(exist_ok=True)
        studio.setOutput(str(out))
        for mode in ("h264", "hevc10", "hdr_pq", "hdr_hlg"):
            studio.setSetting("exportFormat", mode)
            wait(
                lambda: (
                    not studio.state.get("processing")
                    and not (hasattr(studio, "source_timer") and studio.source_timer.isActive())
                )
            )
            studio.startRender()
            assert studio.state["rendering"], studio.state
            wait(lambda: not studio.state["rendering"])
            directory = Path(studio.state["result"])
            record = json.loads((directory / "渲染记录.json").read_text(encoding="utf-8"))[0]
            video = Path(record["output"])
            info = media.probe(video)
            assert info["hdr"] == mode.startswith("hdr_")
            assert record["settings"]["exportFormat"] == mode
            assert record["encoding"]["bitDepth"] == (8 if mode == "h264" else 10)
            if mode != "h264":
                assert record["verifiedColor"]["lumaBits"] == 10
            r = media.run(
                [
                    media.ffmpeg(),
                    "-v",
                    "error",
                    "-i",
                    str(video),
                    "-map",
                    "0:v:0",
                    "-f",
                    "framemd5",
                    "-",
                ],
                capture_output=True,
                text=True,
                check=True,
            )
            count = sum(bool(line) and not line.startswith("#") for line in r.stdout.splitlines())
            assert count == 6
            results.append(
                dict(format=mode, encoder=record["encoder"], color=info["color"], frames=count)
            )
        for language in ("en", "zh"):
            studio.setLanguage(language)
            window.setProperty("inspectorPage", 3 if args.profile == "full" else 1)
            app.processEvents()
            window.grabWindow().save(str(work / (language + "-output.png")))
        assert not warnings, warnings
        report = dict(
            passed=True,
            profile=args.profile,
            nativeHdrImported=True,
            cases=results,
            qmlWarnings=warnings,
        )
        (work / "report.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print(json.dumps(report, ensure_ascii=False))
    finally:
        studio.shutdown()
        if window is not None:
            shiboken.delete(window)
        shiboken.delete(engine)
        qt.QStandardPaths.writableLocation = old_location


if __name__ == "__main__":
    main()
