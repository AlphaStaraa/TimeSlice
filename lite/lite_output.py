"""轻量版输出目录、队列进度与任务协调，不依赖完整桌面控制器。"""

import time
from functools import partial
from pathlib import Path
from tempfile import TemporaryFile

from controller import Controller
from lite_render import LiteRenderJob
from PySide6.QtCore import QStandardPaths, QUrl, Signal, Slot


class LiteOutputController(Controller):
    outputPickerRequested = Signal(str)

    @Slot()
    def chooseOutput(self):
        """请求用户选择输出位置，不通过打开桌面代替导出设置。"""
        self.request_output(False)

    def request_output(self, resume):
        """打开一次目录选择，明确选择后是否接续导出。"""
        if self._state["rendering"] or self.picker_open:
            return
        self.picker_open, self.resume_export = True, resume
        folder = self._state["output"] or QStandardPaths.writableLocation(
            QStandardPaths.MoviesLocation
        )
        self.outputPickerRequested.emit(QUrl.fromLocalFile(folder).toString())

    @Slot()
    def rejectOutput(self):
        """取消目录选择，不启动任何导出。"""
        self.picker_open = self.resume_export = False

    @Slot(str)
    def setOutput(self, url):
        """确认目录可写后保存轻量版独立设置，首次导出可自动接续。"""
        resume = self.resume_export
        self.rejectOutput()
        if self._state["rendering"]:
            return
        try:
            path = QUrl(url).toLocalFile() if url.startswith("file:") else url
            folder = Path(path).resolve(strict=True)
            if not folder.is_dir():
                raise ValueError("请选择文件夹")
            with TemporaryFile(prefix=".timeslice-lite-", dir=folder):
                pass
        except (OSError, ValueError) as error:
            self.receive("error", "无法写入所选位置。" + str(error))
            return
        self.preferences.setValue("export/folder", str(folder))
        self._state.update(output=str(folder), result="")
        self.changed.emit()
        if resume:
            self.startRender()

    @Slot()
    def startRender(self):
        """冻结所选顺序，直接进入视频切片；首次先要求选输出目录。"""
        if self._state["rendering"] or self._state["loading"] or not self.info or not self.checked:
            return
        if not self._state["output"] or not Path(self._state["output"]).is_dir():
            self.request_output(True)
            return
        self.export_eta.reset()
        self.export_started = time.monotonic()
        self._state.update(batchProgress=0.0, batchStage="准备导出", finishedCount=0)
        self.render_job_type = partial(
            LiteRenderJob, store=self.source_store, order=self.selected_order
        )
        super().startRender()
        rank = {eid: index for index, eid in enumerate(self.selected_order)}
        self._state["queue"].sort(key=lambda row: rank.get(row["id"], len(rank)))
        self.changed.emit()

    @Slot(str, object)
    def receive(self, kind, data):
        """只聚合视频导出和预览进度，不设素材加工阶段。"""
        if kind == "render_progress":
            index, stage, fraction, detail = data
            if index == -2:
                self._state["result"] = detail
                self.changed.emit()
                return
            queue = self._state["queue"]
            if index < 0:
                progress, title = 0.15 * fraction, stage
            else:
                progress = 0.15 + 0.85 * (index + fraction) / max(1, len(queue))
                title = f"{queue[index]['name']} · {stage}"
                self._state["finishedCount"] = index + (stage == "已完成")
            self._state.update(
                batchStage=title, batchProgress=max(self._state["batchProgress"], progress)
            )
            self.export_eta.update(self._state["batchProgress"])
        elif kind == "render_done":
            self._state.update(batchProgress=1.0, batchStage="导出完成")
        elif kind == "cancelled":
            self._state["batchStage"] = "已取消"
        if kind in ("render_done", "cancelled", "error") and self._state["rendering"]:
            reason = (
                ""
                if kind == "render_done"
                else "cancelled"
                if kind == "cancelled"
                else "export-error"
            )
            try:
                self.metrics.record(
                    kind == "render_done",
                    time.monotonic() - self.export_started,
                    self.selected_order,
                    reason,
                )
            except OSError:
                pass
        super().receive(kind, data)
        if kind == "import_done" and data[0] == self.import_generation:
            self._state.update(status="素材已就绪，选择切片后即可导出。", result="", queue=[])
            self.changed.emit()
