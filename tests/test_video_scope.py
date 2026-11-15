"""保证当前桌面只暴露视频工作流，不恢复已移除的照片任务或显影依赖。"""

import sys
import unittest


class VideoScopeTests(unittest.TestCase):
    def test_video_controller_has_no_photo_pipeline(self):
        """导入完整控制器后，没有照片槽、后台任务入口或专用显影模块。"""
        from next_controller import NextController

        for method in ("renderPhotos", "begin_photos", "photo_settings", "isPhotoFolder"):
            self.assertFalse(hasattr(NextController, method), method)
        self.assertFalse({"photo_job", "raw_sequence", "rawpy", "exifread"} & set(sys.modules))
