"""用真实文件树验证 Windows 深路径启动准备，不依赖修改系统注册表。"""

import importlib.util
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / "app/windows_bootstrap.py"
SPEC = importlib.util.spec_from_file_location("bootstrap_under_test", SOURCE)
BOOT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BOOT)


class WindowsBootstrapTests(unittest.TestCase):
    def setUp(self):
        """每例使用独立目录，包含一份程序和一份不属于程序的用户文件。"""
        self.temp = tempfile.TemporaryDirectory(prefix="timeslice-bootstrap-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.source = self.base / "source"
        (self.source / "app").mkdir(parents=True)
        (self.source / "app/main.py").write_text("print('中文')", encoding="utf-8")
        (self.source / "runtime").mkdir()
        (self.source / "runtime/pythonw.exe").write_bytes(b"runtime-fixture")
        (self.source / "user-video.mov").write_bytes(b"user-data")
        self.cache = self.base / "cache"

    def long_dependency(self):
        """创建会超过 Qt 常见路径上限的依赖目录。"""
        dependency = self.source / "runtime" / ("q" * (220 - len(str(self.source)))) / "plugin.dll"
        dependency.parent.mkdir(parents=True)
        dependency.write_bytes(b"qt-plugin-fixture")
        return dependency

    def test_short_path_stays_in_place(self):
        """正常短目录应直接使用，不生成额外副本。"""
        self.assertEqual(BOOT.prepare_runtime(self.source, self.cache), self.source.resolve())
        self.assertFalse(self.cache.exists())

    def test_deep_dependency_gets_complete_copy(self):
        """第一次准备后依赖完整、源文件仍在、用户另放的视频不进入运行缓存。"""
        dependency = self.long_dependency()
        target = BOOT.prepare_runtime(self.source, self.cache)
        self.assertNotEqual(target, self.source)
        self.assertEqual(
            (target / dependency.relative_to(self.source)).read_bytes(), dependency.read_bytes()
        )
        self.assertEqual((self.source / "user-video.mov").read_bytes(), b"user-data")
        self.assertFalse((target / "user-video.mov").exists())
        self.assertTrue((target / BOOT.READY_FILE).is_file())
        self.assertEqual(BOOT.prepare_runtime(self.source, self.cache), target)

    def test_changed_source_gets_new_cache(self):
        """维护代码更新后生成新运行目录，避免缓存命中旧版本。"""
        self.long_dependency()
        first = BOOT.prepare_runtime(self.source, self.cache)
        (self.source / "app/main.py").write_text("print('升级后的代码')", encoding="utf-8")
        second = BOOT.prepare_runtime(self.source, self.cache)
        self.assertNotEqual(first, second)
        self.assertIn("升级", (second / "app/main.py").read_text(encoding="utf-8"))

    def test_interrupted_copy_does_not_publish_partial_runtime(self):
        """复制失败不留下可被误用的完成标记或半成品目录。"""
        self.long_dependency()
        with patch.object(BOOT.shutil, "copy2", side_effect=OSError("simulated failure")):
            with self.assertRaises(OSError):
                BOOT.prepare_runtime(self.source, self.cache)
        self.assertEqual(list(self.cache.iterdir()), [])

    def test_parallel_first_launch(self):
        """同时首次启动时，两个调用最终指向同一份已完成的运行目录。"""
        self.long_dependency()
        with ThreadPoolExecutor(2) as pool:
            results = list(
                pool.map(lambda _: BOOT.prepare_runtime(self.source, self.cache), range(2))
            )
        self.assertEqual(results[0], results[1])
        self.assertEqual(len(list(self.cache.iterdir())), 1)


if __name__ == "__main__":
    unittest.main()
