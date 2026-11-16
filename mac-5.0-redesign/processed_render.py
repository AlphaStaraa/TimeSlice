"""借用已处理素材缓存，按队列顺序导出并应用实时调色。"""

import json
from copy import deepcopy

import numpy as np
from export_pipeline import StreamingExport
from mac_controller import MacRenderJob
from precision_processing import analysis_pixels
from prepared_source import reopen, source_key
from render import RenderJob
from source_processing import (
    analyze_direction,
    grade_config,
    normalized_options,
    process_cache,
    source_color_curve,
)


class ProcessedRenderJob(StreamingExport, MacRenderJob):
    def __init__(
        self, *args, source_options=None, prepared=None, order=None, source_store=None, **kwargs
    ):
        """保存调色配置和缓存描述，导出时再核对文件身份及输出条件。"""
        super().__init__(*args, **kwargs)
        self.source_options = normalized_options(source_options)
        self.prepared = deepcopy(prepared)
        self.source_store = source_store
        self.cache_reused = False
        rank = {eid: index for index, eid in enumerate(order or [])}
        self.jobs.sort(key=lambda job: rank.get(job[0]["id"], len(rank)))

    def prepare_cache(self, first, workspace, root):
        """优先借用全分辨率处理缓存；调色交给 CPU/Metal 合成器实时执行。"""
        key = source_key(self.info, first, self.source_options)
        cache = reopen(self.prepared, key)
        self.cache_reused = cache is not None
        decoded_session = False
        if cache is not None:
            report = deepcopy(cache.meta.get("sourceProcessing", {}))
            self.update(-1, "复用已处理素材", 1.0, f"{cache.width} × {cache.height}")
        else:
            decoded_session = self.source_store is not None and (
                self.source_options["stabilize"] == "off"
                and self.source_options["deflicker"] == "off"
            )
            if decoded_session:
                cache, self.cache_reused = self.source_store.acquire(
                    self.info,
                    first,
                    self.cancel,
                    self.update,
                    folder_root=getattr(self, "working_cache_root", self.cache_root),
                )
            else:
                cache = RenderJob.prepare_cache(self, first, workspace, root)
            try:
                options = dict(self.source_options, grade=False)
                report = deepcopy(cache.meta.get("sourceProcessing", dict(options=options)))
                if options["stabilize"] != "off" or options["deflicker"] != "off":
                    report = process_cache(
                        cache,
                        options,
                        self.cancel,
                        lambda stage, p: self.update(-1, stage, p, "准备正式素材"),
                    )
            except BaseException:
                cache.close()
                raise
        try:
            cache.live_grade = None
            if self.source_options["grade"]:
                if self.source_options["dayNight"] == "auto":
                    analysis = report.get("dayNight") or analyze_direction(
                        analysis_pixels(cache, self.cancel)
                    )
                    report["dayNight"] = analysis
                    if analysis["ambiguous"]:
                        raise ValueError("日夜变化不明显，请先手动选择日转夜或夜转日。")
                curve = report.get("colorProgress")
                if curve is None:
                    curve = source_color_curve(analysis_pixels(cache, self.cancel))
                    report["colorProgress"] = curve.tolist()
                cache.live_grade = grade_config(self.source_options, np.asarray(curve, np.float32))
            if decoded_session:
                cache.meta["sourceProcessing"] = report
                (cache.folder / "cache.json").write_text(
                    json.dumps(cache.meta, ensure_ascii=False),
                    encoding="utf-8",
                )
            report.update(
                exportCacheReused=self.cache_reused,
                gradeAppliedDuringCompositing=True,
                gradingOptions=self.source_options,
            )
            (root / "素材处理.json").write_text(
                json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
            )
        except BaseException:
            cache.close()
            raise
        return cache
