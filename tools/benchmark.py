"""固定视频、参数与重复次数，记录耗时、峰值内存和独立进程启动时间。"""

import argparse
import hashlib
import importlib
import json
import os
import platform
import statistics
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def peak_memory():
    """按系统接口读取当前进程峰值工作集，不额外引入运行时依赖。"""
    if sys.platform == "win32":
        import ctypes
        from ctypes import wintypes

        class Counters(ctypes.Structure):
            """对应 Windows PROCESS_MEMORY_COUNTERS 的原生布局。"""

            _fields_ = [("cb", wintypes.DWORD), ("PageFaultCount", wintypes.DWORD)] + [
                (name, ctypes.c_size_t)
                for name in (
                    "PeakWorkingSetSize",
                    "WorkingSetSize",
                    "QuotaPeakPagedPoolUsage",
                    "QuotaPagedPoolUsage",
                    "QuotaPeakNonPagedPoolUsage",
                    "QuotaNonPagedPoolUsage",
                    "PagefileUsage",
                    "PeakPagefileUsage",
                )
            ]

        counters = Counters()
        counters.cb = ctypes.sizeof(counters)
        current = ctypes.windll.kernel32.GetCurrentProcess
        current.restype = wintypes.HANDLE
        read_memory = ctypes.windll.psapi.GetProcessMemoryInfo
        read_memory.argtypes = [wintypes.HANDLE, ctypes.POINTER(Counters), wintypes.DWORD]
        read_memory.restype = wintypes.BOOL
        if not read_memory(current(), ctypes.byref(counters), counters.cb):
            raise ctypes.WinError()
        return counters.PeakWorkingSetSize / 1024**2
    import resource

    value = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    return value / (1024**2 if sys.platform == "darwin" else 1024)


def identity(fixture, stage):
    """记录可比较的硬件与运行时身份，防止把不同机器的结果直接混比。"""
    cpu = platform.processor() or platform.machine()
    if sys.platform == "darwin":
        try:
            cpu = subprocess.check_output(
                ["sysctl", "-n", "machdep.cpu.brand_string"], text=True, stderr=subprocess.DEVNULL
            ).strip()
        except subprocess.CalledProcessError:
            cpu = "unavailable-" + platform.machine()
    return dict(
        os=platform.system(),
        architecture=platform.machine(),
        cpu=cpu,
        cores=os.cpu_count(),
        python=platform.python_version(),
        fixtureSha256=hashlib.sha256(fixture.read_bytes()).hexdigest(),
        profile=json.loads((stage / "resources/release.json").read_text()).get("profile", "full"),
    )


def worker(args):
    """每个新进程做冷缓存与复用缓存各一次，完整解码检查成片后再记结果。"""
    sys.path.insert(0, str(args.stage))
    media = importlib.import_module("media")
    model = importlib.import_module("model")
    defaults = importlib.import_module("effect_models").mac_defaults
    render_type = importlib.import_module("lite_render").LiteRenderJob
    store_type = importlib.import_module("video_cache").VideoCache
    with tempfile.TemporaryDirectory(prefix="timeslice-benchmark-") as folder:
        work = Path(folder)
        (work / "cache").mkdir()
        (work / "output").mkdir()
        info = media.probe(str(args.fixture))
        store = store_type(work / "cache")
        values = []
        try:
            jobs = [
                (
                    model.BY_ID[eid],
                    dict(
                        defaults(model.BY_ID[eid]),
                        duration=1.0,
                        fps=24,
                        longEdge=640,
                        quality="full",
                        engine=args.engine,
                        encoder="cpu",
                    ),
                )
                for eid in (100, 104, 300)
            ]
            for label in ("cold", "warm"):
                job = render_type(
                    info,
                    jobs,
                    work / "output",
                    work / "cache",
                    threading.Event(),
                    lambda *_: None,
                    store=store,
                    order=(100, 104, 300),
                )
                start = time.perf_counter()
                output = job.run()
                seconds = time.perf_counter() - start
                for movie in output.glob("*.mp4"):
                    media.run([media.ffmpeg(), "-v", "error", "-i", str(movie), "-f", "null", "-"])
                values.append(dict(cache=label, seconds=seconds, reused=job.cache_reused))
            result = dict(exports=values, peakMiB=peak_memory())
            args.output.write_text(json.dumps(result, indent=2))
        finally:
            store.close()


def startup(args):
    """测独立 Python 进程到真实 QML 工作台就绪，区分操作系统整机冷启动。"""
    sys.path.insert(0, str(args.stage))
    os.environ["QT_QPA_PLATFORM"] = "offscreen"
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
    os.environ["TIMESLICE_FORCE_CPU"] = "1"
    qt = importlib.import_module("PySide6.QtCore")
    gui = importlib.import_module("PySide6.QtGui")
    qml = importlib.import_module("PySide6.QtQml")
    controller = importlib.import_module("lite_controller").LiteController
    provider = importlib.import_module("controller").PreviewProvider
    app = gui.QGuiApplication([])
    with tempfile.TemporaryDirectory(prefix="timeslice-startup-") as folder:
        old = qt.QStandardPaths.writableLocation
        qt.QStandardPaths.writableLocation = lambda key: (
            folder if key == qt.QStandardPaths.CacheLocation else old(key)
        )
        prefs = qt.QSettings(str(Path(folder) / "prefs.ini"), qt.QSettings.IniFormat)
        studio = controller(provider(), prefs)
        engine = qml.QQmlApplicationEngine()
        engine.addImageProvider("preview", studio.provider)
        engine.rootContext().setContextProperty("studio", studio)
        try:
            engine.load(qt.QUrl.fromLocalFile(str(args.stage / "ui/Main.qml")))
            assert engine.rootObjects(), "QML startup failed"
            app.processEvents()
            args.output.write_text(json.dumps(dict(readyAt=time.time(), peakMiB=peak_memory())))
        finally:
            studio.shutdown()
            importlib.import_module("shiboken6").delete(engine)
            qt.QStandardPaths.writableLocation = old


def main():
    """汇总中位数，与同身份基准比较；默认 10% 回退触发明确报警。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", type=Path, default=ROOT / "build/lite/stage/app")
    parser.add_argument("--fixture", type=Path, default=ROOT / "tests/benchmark/source.mp4")
    parser.add_argument("--output", type=Path, default=ROOT / "build/benchmark/current.json")
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--repeats", type=int, default=3)
    parser.add_argument("--engine", choices=("cpu", "gpu"), default="cpu")
    parser.add_argument("--identity-only", action="store_true")
    parser.add_argument("--worker", action="store_true")
    parser.add_argument("--startup", action="store_true")
    args = parser.parse_args()
    args.stage, args.fixture, args.output = (
        args.stage.resolve(),
        args.fixture.resolve(),
        args.output.resolve(),
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    if args.identity_only:
        machine = identity(args.fixture, args.stage)
        machine["engine"] = args.engine
        hardware_id = hashlib.sha256(json.dumps(machine, sort_keys=True).encode()).hexdigest()[:16]
        args.output.write_text(json.dumps(machine, ensure_ascii=False, indent=2))
        if os.environ.get("GITHUB_OUTPUT"):
            with open(os.environ["GITHUB_OUTPUT"], "a") as stream:
                stream.write(f"hardware_id={hardware_id}\n")
        print(hardware_id)
        return
    if args.worker:
        return worker(args)
    if args.startup:
        return startup(args)
    if not 1 <= args.repeats <= 9:
        parser.error("repeats must be between 1 and 9")
    measurements, starts = [], []
    for repeat in range(args.repeats):
        result = args.output.with_name(f"sample-{repeat}.json")
        base = [
            sys.executable,
            str(Path(__file__).resolve()),
            "--stage",
            str(args.stage),
            "--fixture",
            str(args.fixture),
            "--output",
            str(result),
            "--engine",
            args.engine,
        ]
        subprocess.run(base + ["--worker"], check=True)
        measurements.append(json.loads(result.read_text()))
        started = time.time()
        subprocess.run(base + ["--startup"], check=True)
        starts.append(json.loads(result.read_text())["readyAt"] - started)
    metrics = dict(
        coldExportSeconds=statistics.median(m["exports"][0]["seconds"] for m in measurements),
        warmExportSeconds=statistics.median(m["exports"][1]["seconds"] for m in measurements),
        peakMemoryMiB=statistics.median(m["peakMiB"] for m in measurements),
        processStartupSeconds=statistics.median(starts),
    )
    machine = identity(args.fixture, args.stage)
    machine["engine"] = args.engine
    report = dict(
        schema=1,
        identity=machine,
        repetitions=args.repeats,
        metrics=metrics,
        samples=measurements,
        startupSamples=starts,
        regressions=[],
        comparison="no-baseline",
    )
    if args.baseline and args.baseline.exists():
        previous = json.loads(args.baseline.read_text())
        if previous["identity"] == machine:
            report["comparison"] = "comparable"
            for name, value in metrics.items():
                ratio = value / max(1e-6, previous["metrics"][name])
                if ratio > 1.1:
                    report["regressions"].append(
                        dict(
                            metric=name,
                            ratio=ratio,
                            previous=previous["metrics"][name],
                            current=value,
                        )
                    )
                    print(f"::warning::Performance regression: {name} +{(ratio - 1) * 100:.1f}%")
        else:
            report["comparison"] = "different-machine-or-runtime"
            print(
                "::warning::Performance baseline is not comparable; "
                "review hardware/runtime identity."
            )
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2))
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as stream:
            stream.write(f"regressed={str(bool(report['regressions'])).lower()}\n")
            allowed = (
                report["comparison"] in ("no-baseline", "comparable") and not report["regressions"]
            )
            stream.write(f"baseline_allowed={str(allowed).lower()}\n")
    print(
        json.dumps(
            dict(
                metrics=metrics, comparison=report["comparison"], regressions=report["regressions"]
            ),
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
