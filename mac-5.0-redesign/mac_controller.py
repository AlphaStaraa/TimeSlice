import json
import os
import sys
from pathlib import Path
from tempfile import TemporaryFile

from controller import Controller
from model import EFFECTS
from PySide6.QtCore import QSettings, QStandardPaths, QUrl, Signal, Slot
from PySide6.QtGui import QDesktopServices
from render import RenderJob


class MacRenderJob(RenderJob):
    report_encoding = True


class MacController(Controller):
    render_job_type = MacRenderJob
    outputPickerRequested = Signal(str)

    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self, provider, preferences=None):
        super().__init__(provider)
        preference_name = "ShiRenWindows" if sys.platform == "win32" else "ShiRenMac"
        self.preferences = (
            preferences if preferences is not None else QSettings("AlphaStar", preference_name)
        )
        self.render_after_selection = False
        self.prep_fraction = 0.15
        self.output_picker_open = False
        output = self.preferences.value("export/folder", "", str)
        if output and not Path(output).is_dir():
            output = ""
        resource_root = (
            Path(sys._MEIPASS) / "app"
            if getattr(sys, "frozen", False)
            else Path(__file__).resolve().parent
        )
        release = json.loads((resource_root / "resources/release.json").read_text(encoding="utf-8"))
        self._state.update(
            version=release["displayVersion"],
            author="AlphaStar",
            output=output,
            effectCount=len(EFFECTS),
            batchProgress=0.0,
            batchStage="",
            finishedCount=0,
        )

    # 打开导出位置选择流程。
    @Slot()
    def chooseOutput(self):
        self.request_output_picker(resume_export=False)

    # 组织目录选择请求，并记录选择后是否继续导出。
    def request_output_picker(self, resume_export):
        if self._state["rendering"] or self.output_picker_open:
            return
        self.render_after_selection = resume_export
        self.output_picker_open = True
        selected = self._state["output"]
        initial = (
            selected
            if selected and Path(selected).is_dir()
            else QStandardPaths.writableLocation(QStandardPaths.MoviesLocation)
        )
        self.outputPickerRequested.emit(QUrl.fromLocalFile(initial).toString())

    # 取消目录选择并清理尚未开始的请求。
    @Slot()
    def rejectOutput(self):
        self.render_after_selection = False
        self.output_picker_open = False

    # 验证本机导出目录并记住用户选择。
    @Slot(str)
    def setOutput(self, url):
        resume_export = self.render_after_selection
        self.rejectOutput()
        if self._state["rendering"]:
            return
        try:
            local_path = QUrl(url).toLocalFile() if url.startswith("file:") else url
            if not local_path:
                raise ValueError("请选择本机文件夹")
            folder = Path(local_path).resolve(strict=True)
            if not folder.is_dir():
                raise ValueError("请选择文件夹")
            with TemporaryFile(prefix=".shiren-", dir=folder):
                pass
        except (OSError, ValueError) as error:
            self.receive("error", f"无法写入所选位置。{error}")
            return
        self.preferences.setValue("export/folder", str(folder))
        self.preferences.sync()
        self._state.update(output=str(folder), status="已选择导出位置", result="")
        self.changed.emit()
        if resume_export:
            self.startRender()

    # 检查当前目录是否存在且具有写入权限。
    def output_ready(self):
        output = self._state["output"]
        return bool(output and Path(output).is_dir() and os.access(output, os.W_OK | os.X_OK))

    # 检查素材与目标位置后启动批量导出。
    @Slot()
    def startRender(self):
        if self._state["rendering"] or self._state["loading"] or not self.info or not self.checked:
            return
        if not self.output_ready():
            self._state.update(output="", result="", status="请选择导出位置")
            self.changed.emit()
            self.request_output_picker(resume_export=True)
            return
        self._state.update(batchProgress=0.0, batchStage="准备导出", finishedCount=0)
        self.prep_fraction = 0.15
        self.render_job_type = self.render_factory()
        super().startRender()

    # 冻结当前导出配置并返回对应的任务构造器。
    def render_factory(self):
        return MacRenderJob

    # 在系统文件管理器中显示已完成输出或选定目录。
    @Slot()
    def openOutput(self):
        path = self._state["result"] or self._state["output"]
        if path and Path(path).is_dir():
            QDesktopServices.openUrl(QUrl.fromLocalFile(path))

    # 在界面线程接收后台事件并更新任务与预览状态。
    @Slot(str, object)
    def receive(self, kind, data):
        if kind == "render_progress":
            index, stage, fraction, detail = data
            if index == -2:
                self._state["result"] = detail
                self.changed.emit()
                return
            if self.stop.is_set() and stage != "已完成":
                return
            queue = self._state["queue"]
            if index < 0:
                overall = self.prep_fraction * fraction
                title = stage
            else:
                overall = self.prep_fraction + (1 - self.prep_fraction) * (index + fraction) / len(
                    queue
                )
                title = f"{queue[index]['name']} · {stage}"
                self._state["finishedCount"] = index + 1 if stage == "已完成" else index
            self._state.update(
                batchStage=title, batchProgress=max(self._state["batchProgress"], overall)
            )
        elif kind == "render_done":
            self._state.update(batchStage="导出完成", batchProgress=1.0)
        elif kind == "cancelled":
            self._state["batchStage"] = "已取消"
            self._state["result"] = self._state["result"] if self._state["finishedCount"] else ""
        elif kind == "error" and self._state["rendering"]:
            self._state["batchStage"] = "导出未完成"
            self._state["result"] = self._state["result"] if self._state["finishedCount"] else ""
        super().receive(kind, data)
