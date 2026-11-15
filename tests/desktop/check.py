import os
import sys
import time
import uuid
from pathlib import Path
from types import SimpleNamespace

import numpy as np
from PySide6.QtCore import QEvent, QMetaObject, QObject, QSettings, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "build/mac50"
STAGE = BUILD / "stage/app"
sys.path.insert(0, str(STAGE))
from controller import PreviewProvider
from core.engine import CPUEngine, GPUEngine
from core.reference import ReferenceRenderer
from mac_controller import MacController
from media import ffmpeg, run
from model import BY_ID, EFFECTS, default_settings, duration, params


# 处理事件并等待测试条件，超时后报告当前状态。
def wait_for(predicate, timeout=40):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        app.processEvents()
        if predicate():
            return
        time.sleep(0.02)
    raise TimeoutError(str(controller.state.get("status")))


# 运行渲染器的一致性回归并核对输出。
def check_renderers(cpu, gpu):
    assert len(EFFECTS) == 46 and set(range(407, 411)) <= BY_ID.keys()
    assert 405 not in BY_ID and 406 not in BY_ID
    cache = SimpleNamespace(
        width=384,
        height=256,
        duration=4,
        fps=1,
        folder="check-white",
        data=np.full((4, 256, 384, 4), 255, dtype=np.uint8),
    )
    worst = 0
    for effect in EFFECTS:
        s = default_settings(effect)
        assert s["shadowEnabled"] == (effect["family"] == 0)
        if effect["family"] == 0:
            assert s["ending"] == 3 and s["direction"] == 0
        elif effect["family"] == 2:
            assert duration(effect, s) == 4
        for phase in (0.23, 0.65, 0.92):
            p = params(effect, s, 72, 96, phase, 23, 24)
            error = float(np.abs(cpu.field(p, 72, 96) - gpu.field(p, 72, 96)).mean())
            assert np.isfinite(error) and error < 0.003, (effect["name"], error)
            worst = max(worst, error)
        # Keep continuous wave sampling; use wide pieces to make the shading
        # measurable even for a small synthetic source.
        if effect["family"] != 2:
            s.update(sliceMode=1, sliceCount=12)
        s.update(shadowEnabled=True, shadowStrength=0.75, shadowWidth=0.32)
        for phase in (0.27, 0.55, 0.79):
            shaded = cpu.frame(cache, effect, s, phase)
            if shaded[..., 0].min() < 250:
                break
        else:
            raise AssertionError(f"No shaded pixels for {effect['name']}")
        metal = gpu.frame(cache, effect, s, phase)
        mae = np.abs(shaded[..., :3].astype(np.int16) - metal[..., :3]).mean()
        assert mae < 0.4 and (metal[..., 0].min() < 250), (effect["name"], mae)
        plain = cpu.frame(cache, effect, dict(s, shadowEnabled=False), phase)
        assert np.all(plain == 255) and np.all(shaded[..., 3] == 255)
        original = gpu.frame(cache, effect, s, phase, view=1)
        assert np.all(original == 255)

    stripes = BY_ID[100]
    settings = dict(default_settings(stripes), sliceMode=1, sliceCount=12)
    tail = cpu.frame(cache, stripes, settings, 0.56)[128, :32, 0]
    head = cpu.frame(cache, stripes, dict(settings, shadowSide=1), 0.56)[128, :32, 0]
    assert tail[0] == 255 and tail[-1] < 220 and np.array_equal(tail, head[::-1])
    wider = cpu.frame(cache, stripes, dict(settings, shadowWidth=0.5), 0.56)[128, :32, 0]
    harder = cpu.frame(cache, stripes, dict(settings, shadowSoftness=0), 0.56)[128, :32, 0]
    assert (wider < 255).sum() > (tail < 255).sum()
    assert harder[-4] < tail[-4]
    gray = cpu.frame(cache, stripes, settings, 0.56, view=2)
    assert np.array_equal(
        gray, cpu.frame(cache, stripes, dict(settings, shadowEnabled=False), 0.56, view=2)
    )

    # One-tenth of a phase cycle travels two cells right/clockwise with 20 pieces.
    cache_w = 360
    for eid in (100, 104):
        effect = BY_ID[eid]
        s = dict(default_settings(effect), sliceMode=1, sliceCount=20)

        # 生成当前测试需要覆盖的代表时间位置。
        def times(phase):
            field = cpu.field(params(effect, s, cache_w, 256, phase, 4, 4, view=2), cache_w, 256)
            return field[..., 0] * (1 - field[..., 2]) + field[..., 1] * field[..., 2]

        assert np.max(np.abs(times(0.5 - 1e-6) - times(0.5 + 1e-6))) < 0.0001
        before, after = times(0.55), times(0.5625)
        if eid == 100:
            assert np.allclose(before[:, :-36], after[:, 36:], atol=1e-6)
        else:
            # 读取或构造当前几何测试点。
            def point(q):
                angle = 2 * np.pi * q
                return (int(128 - 80 * np.cos(angle)), int(180 + 80 * np.sin(angle)))

            assert abs(before[point(0.235)] - after[point(0.335)]) < 1e-6
            assert abs(before[point(0.235)] - after[point(0.135)]) > 0.1

    reference = ReferenceRenderer(cache)
    try:
        for eid in (0, 2, 4, 5):
            s = dict(
                default_settings(BY_ID[eid]),
                shadowEnabled=True,
                shadowStrength=0.75,
                shadowWidth=0.45,
            )
            phase = 4 if eid == 4 else 1.7
            shaded = reference.frame(eid, phase, s)
            plain = reference.frame(eid, phase, dict(s, shadowEnabled=False))
            difference = plain[..., 0].astype(np.int16) - shaded[..., 0]
            assert difference.max() >= 5 and difference.min() >= 0, BY_ID[eid]["name"]
    finally:
        reference.close()
    print(
        "138 field comparisons, shadow pixels for all 46 effects, "
        "directional flow and 4 PR modes passed",
        worst,
        flush=True,
    )


# 在高片数下核对阴影强度与像素覆盖。
def check_dense_shadows(cpu, gpu):
    for length, count in ((1080, 300), (1276, 500), (1080, 320), (1080, 720), (270, 100)):
        # Preview and full-size renders can have different pixel pitches.
        for horizontal in (False, True):
            w, h = (12, length) if horizontal else (length, 12)
            cache = SimpleNamespace(
                width=w,
                height=h,
                duration=1,
                fps=2,
                folder=f"dense-{w}-{h}",
                data=np.full((2, h, w, 4), 255, dtype=np.uint8),
            )
            effect = BY_ID[101 if horizontal else 100]
            base = dict(
                default_settings(effect),
                sliceMode=1,
                sliceCount=count,
                outputWidth=1920,
                outputHeight=1920,
            )
            for direction in (0, 1):
                coords = np.arange(length)
                if direction:
                    coords = coords[::-1]
                index = ((2 * coords + 1) * count) // (2 * length)
                for side in (0, 1):
                    settings = dict(base, direction=direction, shadowSide=side)
                    image = cpu.frame(cache, effect, settings, 0.56)
                    row = image[:, 0, 0] if horizontal else image[0, :, 0]
                    minima = np.full(count, 255)
                    np.minimum.at(minima, index, row)
                    assert minima.max() < 255 and np.ptp(minima) <= 1, (
                        length,
                        count,
                        direction,
                        side,
                        minima.min(),
                        minima.max(),
                    )
                    metal = gpu.frame(cache, effect, settings, 0.56)
                    assert np.abs(metal.astype(np.int16) - image).max() <= 1, (
                        length,
                        count,
                        horizontal,
                        direction,
                        side,
                    )
    print("Dense shadows aligned on CPU and Metal at 100–720 pieces, including preview", flush=True)


os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
app = QGuiApplication([])
app.setOrganizationName("AlphaStar")
app.setApplicationName("时刃")
work = BUILD / ("check-" + uuid.uuid4().hex[:6])
work.mkdir()
settings_file = str(work / "preferences.ini")
provider = PreviewProvider()
controller = MacController(provider, QSettings(settings_file, QSettings.IniFormat))
try:
    gpu = GPUEngine()
    cpu = CPUEngine()
    try:
        check_dense_shadows(cpu, gpu)
        check_renderers(cpu, gpu)
    finally:
        gpu.close()
        cpu.close()
    controller.importSource(
        os.environ.get("SHIREN_TEST_SOURCE", str(ROOT / "mobile/tests/source_android.mp4"))
    )
    wait_for(lambda: controller.state["hasImage"] or controller.state["error"])
    assert controller.state["hasImage"], controller.state["error"]
    requested = []
    controller.outputPickerRequested.connect(requested.append)
    controller.startRender()
    assert (
        len(requested) == 1 and not controller.state["rendering"] and not controller.state["output"]
    )
    controller.rejectOutput()
    assert not controller.state["rendering"] and not controller.state["output"]
    controller.startRender()
    assert len(requested) == 2
    controller.rejectOutput()
    removed = work / "已移除的测试文件夹"
    removed.mkdir()
    controller.setOutput(QUrl.fromLocalFile(str(removed)).toString())
    removed.rmdir()
    controller.startRender()
    assert len(requested) == 3 and not removed.exists() and not controller.state["rendering"]

    engine = QQmlApplicationEngine()
    engine.addImageProvider("preview", provider)
    engine.rootContext().setContextProperty("studio", controller)
    engine.load(QUrl.fromLocalFile(str(STAGE / "ui/Main.qml")))
    assert engine.rootObjects()
    window = engine.rootObjects()[0]
    window.resize(994, 662)
    window.setProperty("advanced", True)
    wait_for(lambda: window.isVisible())
    app.processEvents()
    inspector = window.findChild(QObject, "inspectorScroll")
    form = window.findChild(QObject, "inspectorForm")
    assert abs(inspector.property("contentWidth") - inspector.property("availableWidth")) < 0.1
    assert form.property("width") == inspector.property("contentWidth")
    assert form.property("implicitHeight") > inspector.property("height")
    window.grabWindow().save(str(work / "compact.png"))
    window.setProperty("inspectorPage", 1)
    app.processEvents()
    toggle = window.findChild(QObject, "shadowToggle")
    assert toggle.property("checked") and QMetaObject.invokeMethod(toggle, "click")
    assert not controller.state["settings"]["shadowEnabled"]
    controller.resetSettings()
    assert toggle.property("checked")
    window.resize(1320, 842)
    window.setProperty("advanced", False)
    controller.setSetting("sliceMode", 1)
    controller.setSetting("sliceCount", 10)
    frame = controller.state["imageVersion"]
    controller.seek(0.48)
    wait_for(lambda: controller.state["imageVersion"] > frame)
    window.grabWindow().save(str(work / "shadow.png"))
    window.setProperty("inspectorPage", 2)
    window.setProperty("exportAdvanced", True)
    window.setProperty("dark", True)
    app.processEvents()
    window.grabWindow().save(str(work / "dark.png"))
    window.setProperty("dark", False)

    output = work / "导出 位置"
    output.mkdir()
    controller.checked = {100, 2, 407}
    expected_exports = len(controller.checked)
    controller.global_settings.update(longEdge=256, fps=30, engine="gpu", encoder="cpu")
    for key in controller.checked:
        controller.per_effect[key]["duration"] = 1.2
    progress = []
    controller.changed.connect(
        lambda: progress.append((controller.state["batchProgress"], controller.state["batchStage"]))
    )
    controller.sync()
    controller.setOutput(QUrl.fromLocalFile(str(output)).toString())
    assert controller.state["rendering"]
    wait_for(lambda: not controller.state["rendering"])
    assert not controller.state["error"], controller.state["error"]
    assert (
        controller.state["batchProgress"] == 1
        and controller.state["finishedCount"] == expected_exports
    )
    assert any("编码与封装" in stage for _, stage in progress)
    assert all(a[0] <= b[0] for a, b in zip(progress, progress[1:])), progress
    actual = Path(controller.state["result"])
    assert actual.parent == output
    for file in actual.glob("*.mp4"):
        run([ffmpeg(), "-v", "error", "-i", str(file), "-f", "null", "-"], check=True)
    assert len(list(actual.glob("*.mp4"))) == expected_exports
    remembered = QSettings(settings_file, QSettings.IniFormat).value("export/folder")
    assert remembered == str(output)
    controller.global_settings["longEdge"] = 1920
    controller.sync()
    app.processEvents()
    window.grabWindow().save(str(work / "complete.png"))
    controller.checked = {407}
    controller.per_effect[407]["duration"] = 16
    controller.global_settings.update(engine="cpu", longEdge=256)
    stopped = []

    # 在渲染中触发取消，检查清理和输出保留行为。
    def stop_during_render():
        if (
            not stopped
            and controller.state["rendering"]
            and controller.state["batchStage"].endswith("渲染中")
        ):
            stopped.append(True)
            controller.cancelRender()

    controller.changed.connect(stop_during_render)
    controller.startRender()
    wait_for(lambda: not controller.state["rendering"])
    assert stopped and controller.state["batchStage"] == "已取消"
    assert not list(output.rglob("*.partial.mp4"))
    assert len(list(actual.glob("*.mp4"))) == expected_exports
    print(
        "Folder gating, persistence, layout, three Metal exports, progress and cancellation passed",
        work,
        flush=True,
    )
finally:
    if "engine" in globals():
        engine.deleteLater()
        app.sendPostedEvents(None, QEvent.DeferredDelete)
    controller.shutdown()
