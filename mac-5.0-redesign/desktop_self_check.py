"""显式自检完整版真实界面、稳定去闪缓存、实时调色和GPU导出。"""

import json
import sys
import time
import traceback
from pathlib import Path

from media import ffmpeg, run
from PySide6.QtCore import QObject, QTimer, Slot


class FullPackageCheck(QObject):
    def __init__(
        self, app, studio, engine, output, source, require_gpu, warnings, output_format="h264"
    ):
        """仅测试入口启用，偏好和缓存由主入口隔离，不操作用户素材。"""
        super().__init__()
        self.app, self.studio, self.engine = app, studio, engine
        self.output, self.source = Path(output), Path(source)
        self.require_gpu, self.warnings = require_gpu, warnings
        self.output_format = output_format
        self.phase, self.started = 0, time.monotonic()
        self.report = dict(
            packaged=bool(getattr(sys, "frozen", False)), profile="full", requireGpu=require_gpu
        )
        self.timer = QTimer(self)
        self.timer.setInterval(50)
        self.timer.timeout.connect(self.tick)
        self.timer.start()

    @Slot()
    def tick(self):
        """沿正常控制器流程准备缓存、改HSL、导出；过期或失败保留诊断。"""
        try:
            if time.monotonic() - self.started > 300:
                raise TimeoutError("Full package self-check timed out")
            studio, state = self.studio, self.studio.state
            if state["error"] or state.get("processingError"):
                raise RuntimeError(state["error"] or state["processingError"])
            if self.phase == 0:
                if "正在检测" in state["device"]:
                    return
                if self.require_gpu and not state["gpuAvailable"]:
                    raise RuntimeError("A real GPU is required")
                studio.setActive(100)
                for key, value in dict(
                    duration=0.5,
                    fps=12,
                    longEdge=384,
                    quality="full",
                    engine="gpu" if self.require_gpu else "auto",
                    encoder="auto",
                    exportFormat=self.output_format,
                ).items():
                    studio.setSetting(key, value)
                studio.importSource(str(self.source))
                self.phase = 1
            elif self.phase == 1 and state["hasImage"] and not state["loading"]:
                studio.setSourceOption("dayNight", "day_to_night")
                studio.setSourceOption("stabilize", "lock")
                studio.setSourceOption("deflicker", "standard")
                studio.setSourceOption("grade", True)
                self.phase = 2
            elif self.phase == 2 and state.get("preparedReady") and not state["processing"]:
                cache = studio.prepared_cache
                self.folder = cache.folder
                self.modified = (self.folder / "frames.rgba").stat().st_mtime_ns
                report = cache.meta["sourceProcessing"]
                assert report.get("stabilization") and report.get("deflicker")
                studio.setHsl(1, "saturation", 15)
                studio.setHsl(5, "hue", 8)
                self.ready_at = time.monotonic()
                self.phase = 3
            elif self.phase == 3 and time.monotonic() - self.ready_at > 0.4:
                assert not state["processing"] and studio.prepared_cache.folder == self.folder
                assert (self.folder / "frames.rgba").stat().st_mtime_ns == self.modified
                folder = self.output / "exports"
                folder.mkdir(exist_ok=True)
                studio.setOutput(str(folder))
                studio.startRender()
                assert studio.state["rendering"]
                self.phase = 4
            elif self.phase == 4 and not state["rendering"]:
                folder = Path(state["result"])
                record = json.loads((folder / "渲染记录.json").read_text(encoding="utf-8"))[0]
                source_report = json.loads((folder / "素材处理.json").read_text(encoding="utf-8"))
                assert record["cacheReused"] and source_report["exportCacheReused"]
                assert source_report["gradingOptions"]["hsl"][1]["saturation"] == 15
                assert source_report["gradingOptions"]["hsl"][5]["hue"] == 8
                assert (self.folder / "frames.rgba").stat().st_mtime_ns == self.modified
                if self.require_gpu:
                    assert record["engine"].startswith("GPU")
                movie = next(folder.glob("*.mp4"))
                decoded = run(
                    [
                        ffmpeg(),
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
                frames = sum(bool(x) and not x.startswith("#") for x in decoded.stdout.splitlines())
                assert frames == 6
                if self.output_format != "h264":
                    assert record["verifiedColor"]["lumaBits"] == 10
                    assert record["sourceCache"]["pixelFormat"] == "x2rgb10le"
                self.engine.rootObjects()[0].grabWindow().save(str(self.output / "界面预览.png"))
                assert not self.warnings, self.warnings
                self.report.update(
                    outputFormat=self.output_format,
                    verifiedColor=record.get("verifiedColor"),
                    stabilization=True,
                    deflicker=True,
                    realtimeHsl=True,
                    preprocessingCacheReused=True,
                    preprocessingFileUnchanged=True,
                    engine=record["engine"],
                    encoder=record["encoder"],
                    decodedFrames=frames,
                    video=str(movie),
                    qmlWarnings=self.warnings,
                    seconds=time.monotonic() - self.started,
                )
                studio.setSourceOption("stabilize", "off")
                studio.setSourceOption("deflicker", "off")
                studio.setSourceOption("grade", False)
                self.phase = 5
            elif self.phase == 5 and not state["processing"] and not studio.source_timer.isActive():
                studio.startRender()
                assert studio.state["rendering"]
                self.phase = 6
            elif self.phase == 6 and not state["rendering"]:
                self.decoded_folder = studio.source_store.folder
                assert self.decoded_folder is not None
                self.decoded_modified = (self.decoded_folder / "frames.rgba").stat().st_mtime_ns
                first = self.read_decoded_export()
                assert not first["cacheReused"]
                studio.setSourceOption("grade", True)
                studio.setHsl(5, "hue", -12)
                studio.setActive(101)
                studio.startRender()
                assert studio.state["rendering"]
                self.phase = 7
            elif self.phase == 7 and not state["rendering"]:
                assert studio.source_store.folder == self.decoded_folder
                assert (
                    self.decoded_folder / "frames.rgba"
                ).stat().st_mtime_ns == self.decoded_modified
                second = self.read_decoded_export()
                assert second["cacheReused"]
                options = json.loads(
                    (Path(state["result"]) / "素材处理.json").read_text(encoding="utf-8")
                )
                assert options["gradingOptions"]["hsl"][5]["hue"] == -12
                assert not self.warnings, self.warnings
                self.report.update(
                    passed=True,
                    decodedSessionReused=True,
                    decodedSessionPixelsUnchanged=True,
                    decodedSessionColorChanged=True,
                    decodedSessionFolder=str(self.decoded_folder),
                    seconds=time.monotonic() - self.started,
                )
                self.finish(0)
        except Exception:
            self.report.update(
                passed=False,
                phase=self.phase,
                traceback=traceback.format_exc(),
                qmlWarnings=self.warnings,
            )
            self.finish(1)

    def read_decoded_export(self):
        """完整解码连续导出的短片，核对正式记录中的源缓存复用状态。"""
        folder = Path(self.studio.state["result"])
        record = json.loads((folder / "渲染记录.json").read_text(encoding="utf-8"))[0]
        decoded = run(
            [
                ffmpeg(),
                "-v",
                "error",
                "-i",
                record["output"],
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
        assert sum(bool(x) and not x.startswith("#") for x in decoded.stdout.splitlines()) == 6
        return record

    def finish(self, code):
        """先保存完整记录，再让主入口按正常顺序释放控制器和界面。"""
        self.timer.stop()
        (self.output / "report.json").write_text(
            json.dumps(self.report, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        self.app.exit(code)
