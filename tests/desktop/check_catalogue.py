"""Check catalogue migration, per-variant settings, QML and real batch exports."""

import json
import os
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "build/open-source/stage/app"
WORK = ROOT / "build/catalogue51"
sys.path.insert(0, str(STAGE))
from controller import PreviewProvider
from mac_controller import MacController
from media import ffmpeg, run
from model import EFFECTS, TIME_GROUPS, default_settings, library_groups, params
from PySide6.QtCore import QSettings, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
app = QGuiApplication([])
app.setApplicationName("ShiRenCatalogueCheck")
provider = PreviewProvider()
controller = MacController(
    provider, preferences=QSettings(str(WORK / "preferences.ini"), QSettings.IniFormat)
)
engine = QQmlApplicationEngine()
warnings = []
engine.warnings.connect(lambda values: warnings.extend(str(value) for value in values))
engine.addImageProvider("preview", provider)
engine.rootContext().setContextProperty("studio", controller)
engine.load(QUrl.fromLocalFile(str(STAGE / "ui/Main.qml")))
assert engine.rootObjects(), warnings


# 处理事件并等待测试条件，超时后报告当前状态。
def wait_for(predicate, timeout=40):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        app.processEvents()
        if predicate():
            return
        time.sleep(0.02)
    raise AssertionError(controller.state)


assert len(EFFECTS) == 46
assert sum(len(library_groups(f)) for f in (0, 1, 3)) == 35
ids = [v["effect"] for group in TIME_GROUPS for v in group["variants"]]
assert len(ids) == len(set(ids)) == 22
assert set(ids) == {e["id"] for e in EFFECTS if e["family"] in (1, 2)}
for group in TIME_GROUPS:
    for variant in group["variants"]:
        controller.setActive(variant["effect"])
        assert controller.state["activeCatalogue"] == group["key"]
        assert (
            controller.state["movementLabels"][controller.state["movementIndex"]]
            == variant["motion"]
        )
        assert (
            controller.state["orientationLabels"][controller.state["orientationIndex"]]
            == variant["orientation"]
        )

controller.setFamily(2)
assert controller.state["family"] == 1 and len(controller.state["effects"]) == 11
controller.checked.clear()
controller.setActive(2)
controller.setSetting("sliceMode", 1)
controller.setSetting("sliceCount", 37)
controller.toggleEffect(2)
controller.setMovement(1)
assert controller.active == 304
controller.toggleEffect(304)
card = next(x for x in controller.state["effects"] if x["catalogueKey"] == "stripes")
assert card["checkedCount"] == 2 and card["checked"]
controller.setOrientation(1)
assert controller.active == 303
controller.setMovement(0)
assert controller.active == 1
controller.setOrientation(0)
assert controller.active == 2 and controller.state["settings"]["sliceCount"] == 37
assert controller.checked == {2, 304}
controller.setActive(202)
controller.setMovement(1)
assert controller.active == 300 and controller.state["activeCatalogue"] == "circle"
controller.setActive(301)
assert controller.state["activeCatalogue"] == "arc"
controller.setMovement(0)
assert controller.active == 301
assert {"圆形波纹", "弧形波纹"} <= {card["name"] for card in controller.state["effects"]}

# Compare legacy render parameters byte-for-byte against the pre-change implementation.
before = WORK / "before/app/model.py"
baseline = {"__file__": str(STAGE / "model.py")}
exec(compile(before.read_text(), str(before), "exec"), baseline)
for effect in EFFECTS:
    old_effect = baseline["BY_ID"][effect["id"]]
    for phase in (0.17, 0.65):
        settings = default_settings(effect)
        assert settings == baseline["default_settings"](old_effect)
        actual = params(effect, settings, 160, 90, phase, 12, 12)
        expected = baseline["params"](old_effect, settings, 160, 90, phase, 12, 12)
        assert actual.tobytes() == expected.tobytes(), effect["key"]

controller.selectFamily()
assert all(
    any(v["effect"] in controller.checked for v in group["variants"]) for group in TIME_GROUPS
)
controller.selectFamily()
assert not controller.checked

source = WORK / "source.mp4"
run(
    [
        ffmpeg(),
        "-v",
        "error",
        "-y",
        "-f",
        "lavfi",
        "-i",
        "testsrc2=size=160x90:rate=12",
        "-t",
        "1",
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        str(source),
    ]
)
controller.importSource(str(source))
wait_for(lambda: controller.state["hasImage"] and not controller.state["loading"])
output = WORK / "exports"
output.mkdir(exist_ok=True)
controller.setOutput(str(output.resolve()))
for eid in (2, 304):
    controller.setActive(eid)
    controller.setSetting("duration", 0.3)
    controller.setSetting("engine", "cpu")
    controller.toggleEffect(eid)
controller.startRender()
wait_for(lambda: not controller.state["rendering"], 60)
assert len(controller.state["queue"]) == 2
assert all(item["status"] == "已完成" for item in controller.state["queue"]), controller.state[
    "queue"
]
videos = list(Path(controller.state["result"]).rglob("*.mp4"))
assert len(videos) == 2
for video in videos:
    run([ffmpeg(), "-v", "error", "-i", str(video), "-f", "null", "-"])
assert not warnings, warnings
report = dict(
    entries=35,
    timeShapes=11,
    legacyVariants=46,
    legacyParametersUnchanged=True,
    separateCircleAndArc=True,
    multiVariantBatchExports=len(videos),
    qmlWarnings=warnings,
)
(WORK / "catalogue-check.json").write_text(json.dumps(report, ensure_ascii=False, indent=2))
print(json.dumps(report, ensure_ascii=False))
engine.rootObjects()[0].close()
controller.shutdown()
