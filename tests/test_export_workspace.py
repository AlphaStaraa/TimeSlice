"""验证大素材缓存会按真实剩余空间选择目录，不因系统盘不足错失优化路径。"""

import tempfile
import threading
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


class ExportWorkspaceTests(unittest.TestCase):
    def test_parallel_pack_preserves_all_pixels(self):
        """并行整理含非整分组尾部的源块，结果与原连续拷贝逐字节一致。"""
        import numpy as np
        from spatial_export import pack_source_tile

        original = np.arange(17 * 54 * 96 * 4, dtype=np.uint8).reshape(17, 54, 96, 4)
        cache = SimpleNamespace(data=original)
        cancel = threading.Event()
        with (
            ThreadPoolExecutor(max_workers=4) as pool,
            patch(
                "spatial_export.SOURCE_PARALLEL_BYTES",
                1,
            ),
        ):
            actual = pack_source_tile(cache, 7, 5, 33, 11, pool, 4, cancel)
        np.testing.assert_array_equal(actual, original[:, 5:16, 7:40])
        self.assertTrue(actual.flags.c_contiguous)

    def test_storage_layout_and_cleanup_without_gpu(self):
        """CI无显卡时也检查真实临时文件的时间组边界、双向分块和异常清理。"""
        import numpy as np
        from media import Cancelled
        from spatial_export import spatial_frames

        class Buffer:
            """记录模拟设备缓冲区的唯一释放，不模拟实际着色器数学。"""

            def __init__(self, engine):
                """记录当前设备上的存活分配。"""
                self.engine = engine
                self.destroyed = False
                engine.live += 1

            def destroy(self):
                """重复销毁视为测试失败。"""
                assert not self.destroyed
                self.destroyed = True
                self.engine.live -= 1

        class Engine:
            """输出独立的时间/横纵坐标色条，使存储转置错误直接可见。"""

            max_buffer = 1024
            device = SimpleNamespace(limits={"max-compute-workgroups-per-dimension": 3})
            lock = threading.Lock()
            live = 0
            calls = 0

            def buffer(self, data):
                """源块分配只跟踪资源生存期。"""
                return Buffer(self)

            def export_batch(self, cache, effect, settings, x, y, w, h, first, count, *args, **kw):
                """用全局坐标直接生成期望模式，不复用被测的打包或组帧代码。"""
                self.calls += 1
                if scenario == "failure" and self.calls == 2:
                    raise RuntimeError("injected render failure")
                t, yy, xx = np.indices((count, h, w))
                return np.stack((t + first, xx + x, yy + y, np.full_like(t, 255)), -1).astype(
                    np.uint8
                )

        cache = SimpleNamespace(width=13, height=7, data=np.zeros((17, 7, 13, 4), np.uint8))
        for scenario in ("normal", "cancel", "failure"):
            with self.subTest(scenario=scenario), tempfile.TemporaryDirectory() as folder:
                cancel = threading.Event()

                def update(*_):
                    """首块完成即取消，检查首帧之前的回收。"""
                    if scenario == "cancel":
                        cancel.set()

                job = SimpleNamespace(cache_root=Path(folder), cancel=cancel, update=update)
                engine = Engine()
                stream = spatial_frames(job, engine, cache, {}, {}, 35, None, 0, "CI")
                if scenario == "normal":
                    actual = np.stack(list(stream))
                    t, y, x = np.indices((35, 7, 13))
                    expected = np.stack((t, x, y, np.full_like(t, 255)), -1).astype(np.uint8)
                    np.testing.assert_array_equal(actual, expected)
                else:
                    with self.assertRaises(Cancelled if scenario == "cancel" else RuntimeError):
                        list(stream)
                self.assertEqual(engine.live, 0)
                self.assertFalse(list(Path(folder).glob("spatial_*")))

    def test_source_page_hints_preserve_pixels(self):
        """对真实只读文件映射回收页面后，原文件和每帧像素仍可完整读取。"""
        import numpy as np
        from spatial_export import release_source_pages, release_source_tile

        original = np.arange(17 * 54 * 96 * 4, dtype=np.uint8).reshape(17, 54, 96, 4)
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "source.rgba"
            path.write_bytes(original.tobytes())
            data = np.memmap(path, dtype=np.uint8, mode="r", shape=original.shape)
            source = SimpleNamespace(width=96, height=54, data=data)
            try:
                release_source_tile(source, 0, 7, 96, 8)
                np.testing.assert_array_equal(data, original)
                release_source_pages(source)
                np.testing.assert_array_equal(data, original)
                self.assertEqual(path.read_bytes(), original.tobytes())
            finally:
                data._mmap.close()

    def test_large_video_uses_output_volume(self):
        """模拟Windows的34GiB系统盘和572GiB输出盘，完整20秒缓存落输出盘。"""
        from effect_models import mac_defaults
        from model import BY_ID
        from spatial_export import workspace_root

        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            source = SimpleNamespace(
                info=dict(width=3840, height=2160, duration=20, fps=60),
                cache_root=root / "system",
                output=root / "output",
                jobs=[(BY_ID[100], dict(mac_defaults(BY_ID[100]), duration=20, longEdge=3840))],
            )
            for system_free, output_free, expected in (
                (34, 572, source.output),
                (200, 572, source.cache_root),
                (50, 572, source.output),
                (50, 50, source.cache_root),
            ):
                with self.subTest(system_free=system_free, output_free=output_free):

                    def usage(path):
                        """只替代磁盘空间读数，不修改磁盘或全局系统配置。"""
                        free = system_free if path == source.cache_root else output_free
                        return SimpleNamespace(free=free * 1024**3)

                    with patch("spatial_export.shutil.disk_usage", side_effect=usage):
                        self.assertEqual(workspace_root(source), expected)
            source.jobs[0][1]["engine"] = "cpu"
            with patch(
                "spatial_export.shutil.disk_usage", return_value=SimpleNamespace(free=50 * 1024**3)
            ):
                self.assertEqual(workspace_root(source), source.cache_root)

    def test_policy_keeps_short_cached_sources_streamed(self):
        """短驻留源与空间不足时保留流式路径，长源且有空间才使用临时成片。"""
        from spatial_export import use_spatial_cache

        source = SimpleNamespace(width=3840, height=2160)
        with patch("spatial_export.shutil.disk_usage", return_value=SimpleNamespace(free=200e9)):
            source.data = SimpleNamespace(nbytes=39_813_120_000)
            self.assertTrue(use_spatial_cache(source, 1200, "."))
            source.data = SimpleNamespace(nbytes=1_990_656_000)
            self.assertFalse(use_spatial_cache(source, 60, ".", resident_budget=2 * 1024**3))
        source.data = SimpleNamespace(nbytes=39_813_120_000)
        with patch("spatial_export.shutil.disk_usage", return_value=SimpleNamespace(free=1e9)):
            self.assertFalse(use_spatial_cache(source, 1200, "."))


if __name__ == "__main__":
    unittest.main()
