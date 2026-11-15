"""离线 Windows 实机验收：读取现有安装包，产出可核查的帧、视频和报告。"""

import argparse
import importlib
import json
import os
import platform
import subprocess
import sys
import threading
import time
import traceback
from pathlib import Path


def hardware():
    """记录操作系统、CPU、显卡与内存，不读取账号、网络配置或设备序列号。"""
    result = dict(
        os=platform.platform(), architecture=platform.machine(), python=platform.python_version()
    )
    if sys.platform == "win32":
        command = (
            "[Console]::OutputEncoding=[Text.UTF8Encoding]::new(); "
            "$cpu=Get-CimInstance Win32_Processor | Select-Object Name,NumberOfLogicalProcessors; "
            "$gpu=Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion; "
            "$ram=(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory; "
            "@{cpu=$cpu;gpu=$gpu;memoryBytes=$ram}|ConvertTo-Json -Depth 4"
        )
        probe = subprocess.run(
            ["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", command],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=30,
        )
        if probe.returncode == 0:
            result.update(json.loads(probe.stdout.lstrip("\ufeff")))
        else:
            result["hardwareReadError"] = probe.stderr[-1000:]
    return result


def load_app(path):
    """同时兼容旧单文件控制器和维护后的模块拆分版本。"""
    path = path.resolve()
    if path.is_file():
        path = path.parent
    app = path / "app" if (path / "app").is_dir() else path
    sys.path[:0] = [str(app), str(Path(__file__).resolve().parent)]
    model = importlib.import_module("model")
    try:
        defaults = importlib.import_module("effect_models").mac_defaults
        job_type = importlib.import_module("processed_render").ProcessedRenderJob
    except ModuleNotFoundError:
        next_module = importlib.import_module("next_controller")
        defaults, job_type = next_module.mac_defaults, next_module.ProcessedRenderJob
    return app, model, defaults, job_type


def golden_check(kit, model, defaults, output, use_gpu):
    """比对 92 张 CPU 标准帧，并在真实 GPU 可用时计算两种后端的像素误差。"""
    import numpy as np
    from PIL import Image

    source = importlib.import_module("golden_input").source()
    engines = importlib.import_module("core.engine")
    cpu, gpu = engines.CPUEngine(), None
    report = dict(cpuFrames=[], gpuFrames=[], gpuStatus="not-requested")
    if use_gpu:
        try:
            gpu = engines.GPUEngine()
            report["gpuInfo"] = dict(gpu.info)
            info = json.dumps(report["gpuInfo"], default=str).lower()
            software = any(
                word in info for word in ("swiftshader", "llvmpipe", "basic render driver")
            )
            software = software or str(gpu.info.get("adapter_type", "")).lower() == "cpu"
            report["gpuStatus"] = "software-adapter" if software else "hardware-adapter"
            if software:
                gpu.close()
                gpu = None
        except Exception as error:
            report["gpuStatus"], report["gpuError"] = "unavailable", str(error)
    manifest = json.loads((kit / "tests/golden/manifest.json").read_text(encoding="utf-8"))
    try:
        for entry in manifest["cases"]:
            effect, position = model.BY_ID[entry["effect"]], entry["position"]
            settings = defaults(effect)
            actual = cpu.frame(source, effect, settings, position)
            expected = np.asarray(Image.open(kit / "tests/golden" / entry["name"]).convert("RGBA"))
            diff = np.abs(actual.astype(np.int16) - expected.astype(np.int16))
            passed = (
                float(diff.mean()) <= manifest["meanTolerance"]
                and float(np.quantile(diff, 0.99)) <= manifest["p99Tolerance"]
                and float((diff > 3).mean()) <= manifest["outlierTolerance"]
            )
            report["cpuFrames"].append(
                dict(
                    effect=effect["key"],
                    position=position,
                    mean=float(diff.mean()),
                    maximum=int(diff.max()),
                    passed=bool(passed),
                )
            )
            if gpu:
                other = gpu.frame(source, effect, settings, position)
                diff = np.abs(actual.astype(np.int16) - other.astype(np.int16))
                report["gpuFrames"].append(
                    dict(
                        effect=effect["key"],
                        position=position,
                        mean=float(diff.mean()),
                        p99=float(np.quantile(diff, 0.99)),
                        maximum=int(diff.max()),
                        outliers=float((diff > 3).mean()),
                        passed=bool(
                            float(diff.mean()) < 0.5
                            and float(np.quantile(diff, 0.99)) <= 1
                            and float((diff > 3).mean()) < 0.003
                        ),
                    )
                )
        report["cpuGoldenPassed"] = len(report["cpuFrames"]) == 92 and all(
            x["passed"] for x in report["cpuFrames"]
        )
        report["gpuComparisonPassed"] = bool(gpu) and all(x["passed"] for x in report["gpuFrames"])
        (output / "golden-and-gpu.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        return report
    finally:
        cpu.close()
        if gpu:
            gpu.close()


def export_cases(kit, model, defaults, job_type, output, engines, four_k=False, quick=False):
    """走真实导出流水线；完成后完整解码并核对分辨率、帧率及帧数。"""
    media = importlib.import_module("media")
    source = kit / "media" / ("上海日夜_4K60_1s.mp4" if four_k else "上海日夜_1080p30_2s.mp4")
    info = media.probe(str(source))
    fps, edge = (60, 3840) if four_k else (30, 1080 if info["height"] > info["width"] else 1920)
    if quick:
        fps, edge = 12, 320
    results = []
    for engine in engines:
        folder = output / ("4k60" if four_k else "1080p30") / engine
        folder.mkdir(parents=True, exist_ok=True)
        cache = folder / "cache"
        cache.mkdir(exist_ok=True)
        jobs = []
        for eid in (100, 104, 300):
            effect = model.BY_ID[eid]
            settings = dict(
                defaults(effect),
                duration=1.0,
                fps=fps,
                longEdge=edge,
                quality="full",
                engine=engine,
                encoder="auto",
                sliceMode=1,
                sliceCount=60,
                shadowStrength=0.25,
                shadowWidth=0.5,
            )
            jobs.append((effect, settings))

        def notify(index, stage, value, detail):
            """按阶段写控制台进度，避免把等待误认为软件卡死。"""
            if value == 1 or index == -2:
                print(engine, stage, detail, flush=True)

        try:
            start = time.perf_counter()
            job = job_type(
                info,
                jobs,
                folder,
                cache,
                threading.Event(),
                notify,
                source_options=dict(stabilize="off", deflicker="off", grade=False),
                order=[100, 104, 300],
            )
            produced = job.run()
            elapsed = time.perf_counter() - start
            record = json.loads((produced / "渲染记录.json").read_text(encoding="utf-8"))
            videos = []
            for movie in sorted(produced.glob("*.mp4")):
                metadata = media.probe(str(movie))
                decoded = subprocess.run(
                    [
                        media.ffmpeg(),
                        "-v",
                        "error",
                        "-i",
                        str(movie),
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
                frames = sum(
                    bool(line.strip()) and not line.startswith("#")
                    for line in decoded.stdout.splitlines()
                )
                expected_size = model.dimensions(info, edge)
                passed = (
                    (metadata["width"], metadata["height"]) == expected_size
                    and frames == fps
                    and abs(metadata["fps"] - fps) < 0.02
                )
                videos.append(
                    dict(
                        path=str(movie.relative_to(output)),
                        frames=frames,
                        width=metadata["width"],
                        height=metadata["height"],
                        fps=metadata["fps"],
                        decoded=True,
                        passed=passed,
                    )
                )
            results.append(
                dict(
                    engineRequested=engine,
                    seconds=elapsed,
                    passed=all(v["passed"] for v in videos),
                    videos=videos,
                    actualEngines=[r["engine"] for r in record],
                    actualEncoders=[r["encoder"] for r in record],
                )
            )
        except Exception as error:
            (folder / "failure.log").write_text(traceback.format_exc(), encoding="utf-8")
            results.append(dict(engineRequested=engine, passed=False, error=str(error)))
    return results


def ui_probe(args):
    """打开独立验收窗口，检查实际 QML/预览及语言；不操作用户原有窗口。"""
    app_path, _, _, _ = load_app(args.app)
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    qt = importlib.import_module("PySide6.QtCore")
    gui = importlib.import_module("PySide6.QtGui")
    qml = importlib.import_module("PySide6.QtQml")
    bridge = importlib.import_module("controller")
    control = importlib.import_module("next_controller").NextController
    translator_type = importlib.import_module("i18n").Translator
    application = gui.QGuiApplication([])
    application.setApplicationName("TimeSliceWinAcceptance")
    application.setFont(gui.QFontDatabase.systemFont(gui.QFontDatabase.GeneralFont))
    old_location = qt.QStandardPaths.writableLocation
    qt.QStandardPaths.writableLocation = lambda key: (
        str(args.output / "ui-cache")
        if key == qt.QStandardPaths.CacheLocation
        else old_location(key)
    )
    prefs = qt.QSettings(str(args.output / "ui-test.ini"), qt.QSettings.IniFormat)
    prefs.clear()
    studio = control(bridge.PreviewProvider(), prefs)
    engine = qml.QQmlApplicationEngine()
    translator = translator_type(studio.language)
    application.installTranslator(translator)

    def translate(language):
        """真实触发中英文界面翻译。"""
        translator.language = language
        engine.retranslate()

    studio.languageChanged.connect(translate)
    warnings = []
    engine.warnings.connect(lambda items: warnings.extend(str(item) for item in items))
    engine.addImageProvider("preview", studio.provider)
    engine.rootContext().setContextProperty("studio", studio)
    started = time.perf_counter()
    engine.load(qt.QUrl.fromLocalFile(str(app_path / "ui/Main.qml")))
    window = engine.rootObjects()[0] if engine.rootObjects() else None
    try:
        assert window, warnings
        window.setTitle("时刃 · 验收窗口")
        studio.importSource(str(args.kit / "media/上海日夜_1080p30_2s.mp4"))
        deadline = time.monotonic() + 60
        while not studio.state["hasImage"] and time.monotonic() < deadline:
            application.processEvents()
            time.sleep(0.01)
        assert studio.state["hasImage"], studio.state.get("error")
        for language in ("zh", "en"):
            studio.setLanguage(language)
            for _ in range(30):
                application.processEvents()
                time.sleep(0.02)
            window.grabWindow().save(str(args.output / f"window-{language}.png"))
        result = dict(
            windowLoaded=True,
            previewRendered=True,
            languages=["zh", "en"],
            elapsedSeconds=time.perf_counter() - started,
            qmlWarnings=warnings,
            manualInteraction="请按18项人工清单确认原生文件选择、拖拽、取消等交互",
        )
        assert not warnings, warnings
        (args.output / "ui.json").write_text(
            json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8"
        )
    finally:
        studio.shutdown()
        if window:
            importlib.import_module("shiboken6").delete(window)
        importlib.import_module("shiboken6").delete(engine)
        qt.QStandardPaths.writableLocation = old_location


def main():
    """将所有结果写入独立目录，失败保留日志，不将未执行项记为通过。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--app", type=Path, required=True)
    parser.add_argument("--kit", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path)
    parser.add_argument("--4k", dest="four_k", action="store_true")
    parser.add_argument("--no-gpu", action="store_true")
    parser.add_argument("--no-ui", action="store_true")
    parser.add_argument("--ui-probe", action="store_true")
    parser.add_argument("--quick", action="store_true")
    args = parser.parse_args()
    args.kit, args.app = args.kit.resolve(), args.app.resolve()
    args.output = (args.output or args.kit / ("结果_" + time.strftime("%Y%m%d_%H%M%S"))).resolve()
    args.output.mkdir(parents=True, exist_ok=True)
    if args.ui_probe:
        return ui_probe(args)
    report = dict(
        hardware=hardware(),
        app=str(args.app),
        kit=str(args.kit),
        quick=args.quick,
        uiStatus="not-run",
        fourKStatus="not-requested",
        tests=[],
    )
    try:
        app, model, defaults, job_type = load_app(args.app)
        report["app"] = str(app)
        metadata = app / "resources/release.json"
        if metadata.exists():
            report["release"] = json.loads(metadata.read_text(encoding="utf-8"))
        print("1/3 Checking 92 golden frames and GPU…", flush=True)
        golden = golden_check(args.kit, model, defaults, args.output, not args.no_gpu)
        report["goldenPassed"] = golden["cpuGoldenPassed"]
        report["gpuStatus"] = golden["gpuStatus"]
        report["gpuComparisonPassed"] = golden["gpuComparisonPassed"]
        engines = ["cpu"] + (["gpu"] if golden["gpuStatus"] == "hardware-adapter" else [])
        print("2/3 Exporting and fully decoding videos…", flush=True)
        report["tests"] = export_cases(
            args.kit, model, defaults, job_type, args.output, engines, quick=args.quick
        )
        if args.four_k:
            report["fourKStatus"] = "executed"
            report["fourKTests"] = export_cases(
                args.kit, model, defaults, job_type, args.output, engines, four_k=True
            )
        if not args.no_ui:
            print("3/3 Opening an isolated validation window…", flush=True)
            with (args.output / "ui-console.log").open("w", encoding="utf-8") as stream:
                child = subprocess.run(
                    [
                        sys.executable,
                        "-X",
                        "utf8",
                        str(Path(__file__).resolve()),
                        "--ui-probe",
                        "--app",
                        str(args.app),
                        "--kit",
                        str(args.kit),
                        "--output",
                        str(args.output),
                    ],
                    stdout=stream,
                    stderr=subprocess.STDOUT,
                    timeout=120,
                )
            report["uiStatus"] = (
                "passed"
                if child.returncode == 0 and (args.output / "ui.json").exists()
                else "failed"
            )
    except Exception as error:
        report["error"] = str(error)
        (args.output / "failure.log").write_text(traceback.format_exc(), encoding="utf-8")
    finally:
        try:
            report["parentPeakMemoryMiB"] = importlib.import_module("benchmark").peak_memory()
        except Exception as error:
            report["memoryReadError"] = str(error)
        (args.output / "report.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2, default=str), encoding="utf-8"
        )
        print("Report:", args.output / "report.json", flush=True)
    if (
        report.get("error")
        or not report.get("goldenPassed")
        or any(not r["passed"] for r in report["tests"])
        or any(not r["passed"] for r in report.get("fourKTests", []))
        or report["uiStatus"] == "failed"
        or (report.get("gpuStatus") == "hardware-adapter" and not report.get("gpuComparisonPassed"))
    ):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
