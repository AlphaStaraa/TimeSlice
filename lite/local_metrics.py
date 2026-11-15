"""用户自愿开启的本地统计，不联网，不保存素材路径或设备唯一标识。"""

import json
import platform
import time
from collections import Counter
from pathlib import Path


class LocalMetrics:
    def __init__(self, path, enabled=False):
        """默认关闭；只有开启后才持久化新导出事件。"""
        self.path, self.enabled = Path(path), bool(enabled)

    def record(self, success, seconds, effects, reason=""):
        """保存结果、效果编号与耗时，错误只保存分类，不保存可能含路径的原文。"""
        if not self.enabled:
            return
        row = dict(
            time=int(time.time()),
            success=bool(success),
            seconds=round(seconds, 3),
            effects=list(effects),
            reason=reason,
            os=platform.system(),
            architecture=platform.machine(),
        )
        rows = self.rows()[-999:]
        rows.append(row)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")

    def rows(self):
        """读取最多一千条本地事件，损坏时返回空记录而不影响导出。"""
        try:
            data = json.loads(self.path.read_text(encoding="utf-8"))
            return data if isinstance(data, list) else []
        except (OSError, ValueError):
            return []

    def export(self, path):
        """由用户主动保存统计摘要，软件不上传任何内容。"""
        rows = self.rows()
        frequencies = Counter(eid for row in rows for eid in row.get("effects", []))
        payload = dict(
            format="timeslice.local-metrics/v1",
            enabled=self.enabled,
            exports=len(rows),
            successes=sum(bool(row.get("success")) for row in rows),
            effectUsage=dict(frequencies),
            events=rows,
        )
        Path(path).write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
