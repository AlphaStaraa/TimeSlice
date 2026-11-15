"""管理素材导入、设备检测和后台事件。"""

import threading
import time
import traceback
import uuid

from controller_state import ControllerState
from core.engine import GPUEngine
from media import Cancelled, FrameCache, probe
from PySide6.QtCore import QUrl, Slot


class SourceController(ControllerState):
    # 检测可用渲染设备并把结果通知界面。
    def detect(self):
        try:
            self.gpu = GPUEngine()
            self.event.emit("device", dict(device=self.gpu.label, gpuAvailable=True))
        except Exception as e:
            self.event.emit(
                "device", dict(device=self.cpu.label + " · GPU 未启用", gpuAvailable=False)
            )
            self.log("GPU detection: " + str(e))

    # 把诊断信息追加到本机日志。
    def log(self, text):
        with (self.cache_root / "时刃诊断.log").open("a", encoding="utf8") as f:
            f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + text + "\n")

    # 在界面线程接收后台事件并更新任务与预览状态。
    @Slot(str, object)
    def receive(self, kind, data):
        if kind == "device":
            self._state.update(data)
            self.changed.emit()
        elif kind == "import_progress":
            generation, value = data
            if generation == self.import_generation:
                self._state.update(
                    status=f"正在准备预览 · {value:.0%}", busyText=f"读取素材 {value:.0%}"
                )
                self.changed.emit()
        elif kind == "import_error":
            generation, message = data
            if generation == self.import_generation:
                self.receive("error", message)
        elif kind == "import_done":
            generation, info, cache = data
            if generation != self.import_generation:
                cache.discard()
                return
            if self.cache:
                self.preview.submit(self.cache.discard)
            if self.reference:
                self.reference.close()
                self.reference = None
            self.info = info
            self.cache = cache
            self._state.update(
                source=info,
                loading=False,
                hasImage=False,
                progress=0,
                status="素材已就绪，点击效果卡片预览；勾选后可批量导出。",
                cacheInfo=(
                    f"预览 {cache.width}×{cache.height} · {len(cache.data)} 个时间样本"
                    " · 正式输出单独读取原片"
                ),
                busyText="",
            )
            self.sync()
            self.request_preview()
        elif kind == "image":
            serial, im = data
            self.preview_pending = False
            if serial == self.preview_serial:
                self.provider.set(im)
                self._state["imageVersion"] += 1
                self._state["hasImage"] = True
                self.changed.emit()
            if self.preview_dirty:
                self.preview_dirty = False
                self.request_preview()
        elif kind == "preview_error":
            self.preview_pending = False
            self._state["status"] = str(data)
            self.changed.emit()
        elif kind == "error":
            self._state.update(error=str(data), loading=False, rendering=False, busyText="")
            self._state["queue"] = [
                dict(x, status="失败" if x["status"] == "渲染中" else x["status"])
                for x in self._state["queue"]
            ]
            self.log(str(data))
            self.changed.emit()
        elif kind == "render_progress":
            index, status, pct, detail = data
            if index < 0:
                self._state.update(status=f"{status} · {pct:.0%}", busyText=f"{status} {pct:.0%}")
            else:
                q = [dict(x) for x in self._state["queue"]]
                q[index].update(status=status, progress=pct, detail=detail)
                self._state["queue"] = q
                self._state["status"] = f"{q[index]['name']} · {status} {pct:.0%}"
                self._state["busyText"] = detail
            self.changed.emit()
        elif kind == "render_done":
            self._state.update(
                rendering=False, status="全部导出完成", busyText="", result=str(data)
            )
            self.changed.emit()
        elif kind == "cancelled":
            self._state.update(rendering=False, status=str(data), busyText="")
            self._state["queue"] = [
                dict(x, status="已取消" if x["status"] != "已完成" else x["status"])
                for x in self._state["queue"]
            ]
            self.changed.emit()

    # 识别新素材并异步建立预览，过期任务结果不覆盖新素材。
    @Slot(str)
    def importSource(self, url):
        if self._state["rendering"]:
            self._state["error"] = "请等待当前导出完成，或先取消导出。"
            self.changed.emit()
            return
        path = QUrl(url).toLocalFile() if url.startswith("file:") else url
        self.load_stop.set()
        self.load_stop = threading.Event()
        self.import_generation += 1
        generation = self.import_generation
        cancel = self.load_stop
        self.pause()
        self._state.update(
            loading=True, error="", status="正在识别素材…", busyText="识别分辨率与时长"
        )
        self.changed.emit()

        # 在线程池中执行耗时工作，并向界面线程投递结果或异常。
        def work():
            try:
                info = probe(path)
                cache = FrameCache.create(
                    info,
                    480,
                    30,
                    self.cache_root / ("preview_" + uuid.uuid4().hex[:10]),
                    cancel,
                    lambda v: self.event.emit("import_progress", (generation, v)),
                )
                self.event.emit("import_done", (generation, info, cache))
            except Cancelled:
                pass
            except Exception as e:
                self.event.emit("import_error", (generation, str(e)))
                self.log(traceback.format_exc())

        self.io.submit(work)

    # 导入自定义黑白时间图并刷新预览。
    @Slot(str)
    def importMap(self, url):
        path = QUrl(url).toLocalFile() if url.startswith("file:") else url
        self.per_effect[self.active].update(customMap=True, mapPath=path, sliceMode=2)
        self.sync()
        self.debounce.start()
