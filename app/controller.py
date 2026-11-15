"""保留公共控制器入口，管理导出和资源退出。"""

import threading
import traceback
from pathlib import Path

from controller_preview import PreviewController
from controller_preview import PreviewProvider as PreviewProvider
from media import Cancelled
from model import EFFECTS
from PySide6.QtCore import QUrl, Slot
from PySide6.QtGui import QDesktopServices


class Controller(PreviewController):
    # 验证本机导出目录并记住用户选择。
    @Slot(str)
    def setOutput(self, url):
        self._state["output"] = QUrl(url).toLocalFile() if url.startswith("file:") else url
        self.changed.emit()

    # 检查素材与目标位置后启动批量导出。
    @Slot()
    def startRender(self):
        if self._state["rendering"] or not self.info or not self.checked:
            return
        self.pause()
        self.stop = threading.Event()
        jobs = []
        queue = []
        for e in EFFECTS:
            if e["id"] not in self.checked:
                continue
            s = dict(self.per_effect[e["id"]])
            s.update(
                {
                    k: self.global_settings[k]
                    for k in ["fps", "longEdge", "engine", "quality", "keepAudio", "encoder"]
                }
            )
            jobs.append((e, s))
            queue.append(
                dict(
                    id=e["id"],
                    name=e["name"],
                    key=e["key"],
                    status="等待中",
                    progress=0.0,
                    detail="",
                )
            )
        self._state.update(rendering=True, queue=queue, error="", result="", status="准备批量导出…")
        self.changed.emit()
        job = self.render_job_type(
            dict(self.info),
            jobs,
            self._state["output"],
            self.cache_root,
            self.stop,
            lambda *x: self.event.emit("render_progress", x),
        )

        # 在线程池中执行耗时工作，并向界面线程投递结果或异常。
        def work():
            try:
                self.event.emit("render_done", str(job.run()))
            except Cancelled as e:
                self.event.emit("cancelled", str(e))
            except Exception as e:
                self.log(traceback.format_exc())
                self.event.emit("error", str(e))

        self.export.submit(work)

    # 通知后台取消任务并保留已经完成的成片。
    @Slot()
    def cancelRender(self):
        self.stop.set()
        self._state["status"] = "正在安全取消…"
        self.changed.emit()

    # 在系统文件管理器中显示已完成输出或选定目录。
    @Slot()
    def openOutput(self):
        path = Path(self._state["result"] or self._state["output"])
        path.mkdir(parents=True, exist_ok=True)
        QDesktopServices.openUrl(QUrl.fromLocalFile(str(path)))

    # 停止后台任务并依次关闭缓存、线程和渲染设备。
    @Slot()
    def shutdown(self):
        self.stop.set()
        self.load_stop.set()
        self.pause()
        self.io.shutdown(wait=True)
        self.preview.shutdown(wait=True)
        self.export.shutdown(wait=True)
        if self.cache:
            self.cache.discard()
        if self.reference:
            self.reference.close()
        self.cpu.close()
        if self.gpu:
            self.gpu.close()
