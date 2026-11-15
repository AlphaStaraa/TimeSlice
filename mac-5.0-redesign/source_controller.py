"""素材处理、缓存失效和后台任务事件。"""

import json
import shutil
import threading
import traceback
import uuid
from copy import deepcopy

import numpy as np
from mac_controller import MacController
from media import Cancelled, FrameCache
from prepared_source import preview_copy, source_key
from PySide6.QtCore import Slot
from source_processing import (
    DEFAULT_OPTIONS,
    analyze_direction,
    normalized_options,
    preset_options,
    process_cache,
    source_color_curve,
)


class SourceController(MacController):
    # 更新一个颜色带的参数并发起实时预览。
    @Slot(int, str, float)
    def setHsl(self, band, key, value):
        if not 0 <= band < 8 or key not in ("hue", "saturation", "luminance"):
            return
        bands = deepcopy(self.source_options["hsl"])
        bands[band][key] = value
        self.setSourceOption("hsl", bands)

    # 更新素材选项，稳定去闪准备正式缓存，调色只刷新实时配置。
    @Slot(str, "QVariant")
    def setSourceOption(self, key, value):
        if key not in DEFAULT_OPTIONS or self._state["rendering"]:
            return
        self.pause()
        current = deepcopy(self.source_options)
        current[key] = value
        if key.startswith(("start", "end")):
            current["look"] = "custom"
        if key in ("look", "dayNight") and current["look"] != "custom":
            resolved = (
                current["dayNight"]
                if current["dayNight"] != "auto"
                else (self._state.get("dayNightDetected") or "day_to_night")
            )
            current = preset_options(current, current["look"], resolved)
        self.source_options = normalized_options(current)
        if key in ("stabilize", "deflicker"):
            self.source_store.close()
            self._state["processingError"] = ""
            self.processing_stop.set()
            self.processing_version += 1
            if self.original_cache is not None:
                self._state.update(
                    processing=True, processingProgress=0.0, processingStage="准备素材处理"
                )
                self.source_timer.start()
        self.preview_serial += 1
        self.sync()
        self.debounce.start()

    @Slot(str, "QVariant")
    def setSetting(self, key, value):
        """尺寸或采样精度变化后重新准备缓存；切片和调色参数不触发源重处理。"""
        if self._state["rendering"]:
            return
        if key == "reference":
            return
        if key == "rotationStartAngle":
            # 旋转的起点是角度相位，不能通过移动圆心伪装成起点。
            if self.active not in (0, 104):
                return
            value = float(value)
            if not np.isfinite(value):
                return
            self.per_effect[self.active].update(
                rotationStartAngle=max(0.0, min(360.0, value)), origin=-1
            )
            self.preview_serial += 1
            self.sync()
            self.debounce.start()
            return
        if key == "origin" and self.active in (0, 104):
            return
        old = self.global_settings.get(key)
        super().setSetting(key, value)
        if (
            key in ("longEdge", "quality")
            and old != self.global_settings.get(key)
            and self.original_cache is not None
        ):
            self.processing_stop.set()
            self.processing_version += 1
            self.source_timer.start()

    # 识别新素材并异步建立预览，过期任务结果不覆盖新素材。
    @Slot(str)
    def importSource(self, url):
        if self._state["rendering"]:
            return super().importSource(url)
        if hasattr(self, "processing_stop"):
            self.source_store.close()
            self.processing_stop.set()
            self.processing_version += 1
            self.source_timer.stop()
            self.preview_serial += 1
            if self.prepared_cache is not None:
                self.prepared_cache.discard()
                self.prepared_cache = None
                self.prepared_key = None
            self._state.update(
                preparedReady=False,
                processing=False,
                processingStage="",
                processingError="",
                stabilizeStatus="",
                deflickerStatus="",
            )
        super().importSource(url)

    def prepare_source_preview(self):
        """立即在后台准备正式尺寸缓存，并从结果派生预览，导出共享相同结果。"""
        original = self.original_cache
        if original is None or self._state["loading"] or self._state["rendering"]:
            return
        self.processing_stop.set()
        self.processing_stop = threading.Event()
        token = self.processing_stop
        version = self.processing_version
        generation = self.import_generation
        options = deepcopy(self.source_options)
        options["grade"] = False
        key = source_key(self.info, self.global_settings, options)
        if self.prepared_cache is not None:
            if key == self.prepared_key:
                self._state.update(processing=False, preparedReady=True)
                self.changed.emit()
                return
            self.prepared_cache.discard()
            self.prepared_cache = None
            self.prepared_key = None
        self._state["preparedReady"] = False
        if options["stabilize"] == "off" and options["deflicker"] == "off":
            prior = self.cache
            self.cache = original
            if prior is not original:
                self.preview.submit(prior.discard)
            self._state.update(
                processing=False,
                processingProgress=0.0,
                processingStage="",
                processingError="",
                sourceReport={},
                stabilizeStatus="",
                deflickerStatus="",
            )
            self.preview_serial += 1
            self.changed.emit()
            self.request_preview()
            return
        self.source_eta.reset()
        self._state.update(
            processing=True,
            processingProgress=0.0,
            processingStage="准备正式素材",
            processingError="",
            stabilizeStatus="等待处理" if options["stabilize"] != "off" else "",
            deflickerStatus="等待处理" if options["deflicker"] != "off" else "",
        )
        self.changed.emit()
        folder = self.cache_root / ("ready_" + uuid.uuid4().hex[:10])
        proxy_folder = self.cache_root / ("processed_" + uuid.uuid4().hex[:10])
        info = deepcopy(self.info)
        settings = dict(self.global_settings)

        # 把内部阶段进度映射到对外可显示的范围。
        def progress(stage, fraction):
            self.event.emit("source_progress", (generation, version, stage, fraction))

        # 在线程池中执行耗时工作，并向界面线程投递结果或异常。
        def work():
            full = None
            proxy = None
            try:
                full = FrameCache.create(
                    info,
                    settings["longEdge"],
                    0 if settings["quality"] == "full" else 30,
                    folder,
                    token,
                    lambda fraction: progress("读取正式素材", 0.30 * fraction),
                )
                report = process_cache(
                    full,
                    options,
                    token,
                    lambda stage, fraction: progress(stage, 0.30 + 0.60 * fraction),
                )
                full.meta.update(preparedKey=key, sourceProcessing=report)
                (folder / "cache.json").write_text(
                    json.dumps(full.meta, ensure_ascii=False), encoding="utf-8"
                )
                proxy = preview_copy(
                    full,
                    proxy_folder,
                    token,
                    lambda stage, fraction: progress(stage, 0.90 + 0.10 * fraction),
                )
                if self.shutting_down:
                    proxy.discard()
                    full.discard()
                else:
                    self.event.emit("source_done", (generation, version, proxy, report, full, key))
            except Cancelled:
                if proxy:
                    proxy.discard()
                else:
                    shutil.rmtree(proxy_folder, ignore_errors=True)
                if full:
                    full.discard()
                else:
                    shutil.rmtree(folder, ignore_errors=True)
            except Exception as error:
                if proxy:
                    proxy.discard()
                else:
                    shutil.rmtree(proxy_folder, ignore_errors=True)
                if full:
                    full.discard()
                else:
                    shutil.rmtree(folder, ignore_errors=True)
                try:
                    self.log(traceback.format_exc())
                except OSError:
                    pass
                self.event.emit("source_error", (generation, version, str(error)))

        self.io.submit(work)

    # 在界面线程接收后台事件并更新任务与预览状态。
    @Slot(str, object)
    def receive(self, kind, data):
        if kind == "import_done" and hasattr(self, "original_cache"):
            generation, info, cache = data
            if generation == self.import_generation:
                self.processing_stop.set()
                old = self.original_cache
                if old is not None and old is not self.cache:
                    self.preview.submit(old.discard)
                self.color_curve = source_color_curve(cache.data)
                analysis = analyze_direction(cache.data)
                self._state.update(
                    dayNightDetected=analysis["direction"],
                    dayNightConfidence=analysis["confidence"],
                )
                if self.source_options["look"] != "custom":
                    resolved = (
                        self.source_options["dayNight"]
                        if self.source_options["dayNight"] != "auto"
                        else analysis["direction"]
                    )
                    self.source_options = preset_options(
                        self.source_options, self.source_options["look"], resolved
                    )
                super().receive(kind, data)
                self.original_cache = self.cache
                self.processing_version += 1
                self.prepare_source_preview()
                return
        if kind == "preview_complete":
            serial, image, error = data
            self.preview_pending = False
            if serial == self.preview_serial:
                if image is not None:
                    self.provider.set(image)
                    self._state["imageVersion"] += 1
                    self._state["hasImage"] = True
                    self._state["previewWidth"] = image.shape[1]
                    self._state["previewHeight"] = image.shape[0]
                elif error:
                    self._state["status"] = "预览未完成：" + error
                self.changed.emit()
            if self.preview_dirty or serial != self.preview_serial:
                self.preview_dirty = False
                self.request_preview()
            return
        if kind in ("source_progress", "source_done", "source_error"):
            generation, version, *payload = data
            if generation != self.import_generation or version != self.processing_version:
                if kind == "source_done":
                    payload[0].discard()
                    payload[2].discard()
                return
            if kind == "source_progress":
                stage, fraction = payload
                fraction = max(self._state["processingProgress"], fraction)
                self._state.update(processingStage=stage, processingProgress=fraction)
                self.source_eta.update(fraction)
                reading = stage in ("准备正式素材", "读取正式素材")
                if self.source_options["stabilize"] != "off":
                    self._state["stabilizeStatus"] = (
                        "等待素材"
                        if reading
                        else "锁定分析"
                        if stage == "固定点锁定"
                        else "锁定参数就绪"
                        if stage == "去闪分析"
                        else "应用锁定"
                        if stage == "应用画面处理"
                        else "已完成"
                    )
                if self.source_options["deflicker"] != "off":
                    self._state["deflickerStatus"] = (
                        "等待素材"
                        if reading
                        else "等待去闪"
                        if stage == "固定点锁定"
                        else "去闪分析"
                        if stage == "去闪分析"
                        else "应用去闪"
                        if stage == "应用画面处理"
                        else "已完成"
                    )
            elif kind == "source_error":
                self._state.update(
                    processing=False,
                    processingError=payload[0],
                    stabilizeStatus="处理失败" if self.source_options["stabilize"] != "off" else "",
                    deflickerStatus="处理失败" if self.source_options["deflicker"] != "off" else "",
                )
            else:
                copied, report, full, key = payload
                prior = self.cache
                self.cache = copied
                self.prepared_cache = full
                self.prepared_key = key
                self._state["preparedReady"] = True
                self._state["cacheInfo"] = (
                    f"正式缓存 {full.width}×{full.height} · {len(full.data)} 个时间样本 · 导出复用"
                )
                self.color_curve = np.asarray(
                    report.get("colorProgress", self.color_curve), np.float32
                )
                self.source_eta.update(1.0)
                if prior is not self.original_cache:
                    self.preview.submit(prior.discard)
                self._state.update(
                    processing=False,
                    processingProgress=1.0,
                    processingStage="素材处理完成",
                    sourceReport=report,
                    processingError="",
                    status="素材处理完成",
                    stabilizeStatus="已完成" if self.source_options["stabilize"] != "off" else "",
                    deflickerStatus="已完成" if self.source_options["deflicker"] != "off" else "",
                )
                self.preview_serial += 1
                self.request_preview()
            self.changed.emit()
            return
        super().receive(kind, data)
        if kind == "render_progress":
            self.export_eta.update(self._state.get("batchProgress", 0.0))
            self.changed.emit()
