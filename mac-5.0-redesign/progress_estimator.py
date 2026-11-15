"""以单调时钟和平滑速率估算本地任务的剩余时间。"""

import time


class ProgressEstimator:
    def __init__(self):
        """初始化估算器；尚未取得有效速率时不显示虚假的精确秒数。"""
        self.reset()

    def reset(self):
        """为新任务清空上一个任务的采样、速率与剩余时间。"""
        self.started = time.monotonic()
        self.last_time = self.started
        self.last_progress = 0.0
        self.rate = None
        self.remaining = None

    def update(self, progress):
        """按新进度采样吞吐量，使用指数平滑降低预计时间的跳动。"""
        now = time.monotonic()
        p = min(1.0, max(0.0, float(progress)))
        if p >= 1:
            self.remaining = 0.0
            return
        delta = p - self.last_progress
        seconds = now - self.last_time
        if delta > 0 and seconds >= 0.2:
            measured = delta / seconds
            self.rate = measured if self.rate is None else 0.25 * measured + 0.75 * self.rate
            self.last_progress = p
            self.last_time = now
            if now - self.started >= 0.5 and p >= 0.015:
                self.remaining = (1 - p) / max(1e-8, self.rate)

    def text(self, language="zh"):
        """返回可直接显示的中英文估算文案，明确标为近似值。"""
        if self.remaining is None:
            return "Estimating…" if language == "en" else "正在估算…"
        value = max(0, round(self.remaining))
        if value == 0:
            return "Complete" if language == "en" else "已完成"
        minutes, seconds = divmod(value, 60)
        hours, minutes = divmod(minutes, 60)
        if language == "en":
            units = (
                f"{hours}h {minutes}m"
                if hours
                else f"{minutes}m {seconds}s"
                if minutes
                else f"{seconds}s"
            )
            return f"About {units} remaining"
        units = (
            f"{hours} 小时 {minutes} 分"
            if hours
            else f"{minutes} 分 {seconds} 秒"
            if minutes
            else f"{seconds} 秒"
        )
        return f"预计剩余约 {units}"
