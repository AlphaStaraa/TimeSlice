"""打包应用的显式命令行验收，运行真实界面、目录流程和视频输出。"""

import json
import time
import traceback
from pathlib import Path

from media import ffmpeg, run
from PySide6.QtCore import QMetaObject, QObject, QTimer, Slot


class PackageCheck(QObject):
    def __init__(self, app, studio, engine, output, require_gpu=False):
        """仅显式自测时创建，使用独立偏好、缓存及输出。"""
        super().__init__()
        self.app, self.studio, self.engine = app, studio, engine
        self.output, self.require_gpu = Path(output), require_gpu
        self.window = engine.rootObjects()[0]
        self.phase = 0
        self.started = time.monotonic()
        self.warnings = []
        self.report = dict(packaged=True, requireGpu=require_gpu, ffmpeg=ffmpeg())
        self.engine.warnings.connect(lambda items: self.warnings.extend(str(x) for x in items))
        self.timer = QTimer(self)
        self.timer.setInterval(50)
        self.timer.timeout.connect(self.tick)
        self.timer.start()

    @Slot()
    def tick(self):
        """用正常事件循环等待真实后台任务，任何错误会保留诊断并退出失败。"""
        try:
            if time.monotonic() - self.started > 90:
                raise TimeoutError("Packaged application workflow timed out")
            studio = self.studio
            state = studio.state
            if state["error"]:
                raise RuntimeError(state["error"])
            if self.phase == 0:
                if "正在检测" in state["device"]:
                    return
                self.report["device"] = state["device"]
                if self.require_gpu and not state["gpuAvailable"]:
                    raise RuntimeError("A real GPU was required but not available")
                studio.importExample()
                self.phase = 1
            elif self.phase == 1 and state["hasImage"] and not state["loading"]:
                studio.setActive(104)
                studio.setSetting("rotationStartAngle", 90)
                studio.setFreezeSplit(True)
                for key, value in dict(
                    duration=0.5, fps=12, longEdge=160, engine="gpu" if self.require_gpu else "auto"
                ).items():
                    studio.setSetting(key, value)
                folder = self.output / "exports"
                folder.mkdir(exist_ok=True)
                studio.setOutput(str(folder))
                studio.startRender()
                self.phase = 2
            elif self.phase == 2 and not state["rendering"]:
                folder = Path(state["result"])
                record = json.loads((folder / "渲染记录.json").read_text(encoding="utf-8"))[0]
                if self.require_gpu and not record["engine"].startswith("GPU"):
                    raise RuntimeError("GPU test unexpectedly fell back to CPU")
                movie = next(folder.glob("*.mp4"))
                decoded = run(
                    [ffmpeg(), "-v", "error", "-i", str(movie), "-f", "framemd5", "-"],
                    capture_output=True,
                    text=True,
                    check=True,
                )
                count = sum(
                    bool(line) and not line.startswith("#") for line in decoded.stdout.splitlines()
                )
                assert count == 6, count
                self.report.update(
                    engine=record["engine"],
                    encoder=record["encoder"],
                    decodedFrames=count,
                    video=str(movie),
                    cacheReused=record["cacheReused"],
                )
                self.engine.rootObjects()[0].grabWindow().save(
                    str(self.output / "packaged-window.png")
                )
                self.phase = 3
                studio.chooseOutput()
            elif self.phase == 3:
                if not self.window.property("outputFolderVisible"):
                    return
                self.report["outputDialogOpened"] = True
                QMetaObject.invokeMethod(self.window, "dismissOutputDialog")
                self.phase = 4
            elif self.phase == 4 and not studio.picker_open:
                assert not self.warnings, self.warnings
                self.report.update(
                    passed=True, qmlWarnings=self.warnings, seconds=time.monotonic() - self.started
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

    def finish(self, code):
        """落盘结果后通过应用正常退出流程释放线程和显存。"""
        self.timer.stop()
        (self.output / "report.json").write_text(
            json.dumps(self.report, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        self.app.exit(code)
