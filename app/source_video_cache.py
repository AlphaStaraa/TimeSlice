"""缓存视频解码帧，供连续切片任务复用。"""

import hashlib
import json
import shutil
import uuid
from pathlib import Path

from media import FrameCache
from model import dimensions


def video_key(info, settings):
    """用原文件身份、尺寸和时间精度判定缓存能否原样复用。"""
    path = Path(info["path"]).resolve()
    stat = path.stat()
    size = dimensions(info, settings["longEdge"])
    fps = info["fps"] if settings["quality"] == "full" else min(30, info["fps"])
    identity = (str(path), stat.st_size, stat.st_mtime_ns, *size, fps)
    return hashlib.sha256(json.dumps(identity).encode()).hexdigest()


class VideoCache:
    def __init__(self, root):
        """每个工作会话最多保留一份正式解码缓存，退出时清理。"""
        self.root = Path(root)
        self.folder = None
        self.key = None

    def acquire(self, info, settings, cancel, notify, folder_root=None):
        """首次直接解码，之后借用独立只读租约，不重复分析或解码。"""
        key = video_key(info, settings)
        if key == self.key and self.folder is not None and (self.folder / "cache.json").is_file():
            notify(-1, "复用视频缓存", 1, "直接进入切片合成")
            return FrameCache(
                self.folder, json.loads((self.folder / "cache.json").read_text(encoding="utf-8"))
            ), True
        self.close()
        folder = Path(folder_root or self.root) / (".timeslice-video_" + uuid.uuid4().hex[:10])
        try:
            cache = FrameCache.create(
                info,
                settings["longEdge"],
                0 if settings["quality"] == "full" else 30,
                folder,
                cancel,
                lambda value: notify(-1, "读取原片", value, "准备切片素材"),
            )
            self.folder, self.key = folder, key
            return cache, False
        except BaseException:
            shutil.rmtree(folder, ignore_errors=True)
            raise

    def close(self):
        """移除本进程的可重建缓存，始终不触碰原视频。"""
        if self.folder is not None:
            shutil.rmtree(self.folder, ignore_errors=True)
        self.folder = self.key = None
