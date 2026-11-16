"""验证大源有界读取、HDR峰值扫描与取消，不依赖分配数十GB物理内存。"""

import hashlib
import tempfile
import threading
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import numpy as np
from media import Cancelled, rgb10_peak_code
from spatial_export import pack_source_file_tile, pack_source_tile


class ForbiddenMappedReads(np.memmap):
    """文件仍可正常读取，但禁止通过映射索引触及像素。"""

    def __getitem__(self, key):
        """任何映射像素访问都表示有界分支没有真正生效。"""
        raise AssertionError("不应读取源映射像素")


class SourceFileTileTests(unittest.TestCase):
    def source(self, shape=(17, 54, 96, 4), mode="r", protected=False):
        """写入独立像素与非零文件偏移，保留期望值并正确回收映射。"""
        folder = Path(self.enterContext(tempfile.TemporaryDirectory()))
        path = folder / "中文 源时间缓存.rgb10"
        original = np.random.default_rng(108).integers(0, 256, shape, dtype=np.uint8)
        header = b"independent-file-offset!"
        with path.open("wb") as stream:
            stream.write(header)
            stream.write(original)
        kind = ForbiddenMappedReads if protected else np.memmap
        data = kind(path, mode=mode, offset=len(header), dtype=np.uint8, shape=shape)
        self.addCleanup(data._mmap.close)
        cache = SimpleNamespace(data=data, width=shape[2], height=shape[1])
        return cache, original, path

    def test_tiles_and_temporal_views_preserve_every_byte(self):
        """全宽、窄块、时间子视图及不整除线程尾部均与独立原数组一致。"""
        cache, original, path = self.source()
        before = hashlib.sha256(path.read_bytes()).hexdigest()
        root = cache.data
        with (
            ThreadPoolExecutor(4) as pool,
            patch("spatial_export.WINDOWS_FILE_TILES", True),
            patch("spatial_export.SOURCE_FILE_MIN_BYTES", 1),
            patch("spatial_export.SOURCE_PARALLEL_BYTES", 1),
        ):
            for low, high in ((0, 17), (5, 13)):
                cache.data = root[low:high]
                for x, y, w, h in ((0, 0, 96, 54), (0, 7, 96, 8), (3, 5, 33, 11)):
                    for workers in (1, 4):
                        with self.subTest(frames=(low, high), tile=(x, y, w, h), workers=workers):
                            actual = pack_source_tile(
                                cache, x, y, w, h, pool, workers, threading.Event()
                            )
                            np.testing.assert_array_equal(
                                actual, original[low:high, y : y + h, x : x + w]
                            )
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), before)

    def test_bounded_path_does_not_index_the_source_mapping(self):
        """源映射索引被禁止时依然获得正确像素，排除继续触碰映射页的假优化。"""
        cache, original, _ = self.source(protected=True)
        with (
            ThreadPoolExecutor(4) as pool,
            patch("spatial_export.WINDOWS_FILE_TILES", True),
            patch("spatial_export.SOURCE_FILE_MIN_BYTES", 1),
        ):
            actual = pack_source_tile(cache, 7, 4, 31, 12, pool, 4, threading.Event())
        np.testing.assert_array_equal(actual, original[:, 4:16, 7:38])

    def test_copy_on_write_and_ram_keep_unpersisted_edits(self):
        """写时复制和内存源必须使用内存内容，不得重开文件丢失未落盘修改。"""
        cache, original, path = self.source(mode="c")
        before = path.read_bytes()
        cache.data[0, 0, 0] = [1, 2, 3, 4]
        original[0, 0, 0] = [1, 2, 3, 4]
        with (
            ThreadPoolExecutor(2) as pool,
            patch("spatial_export.WINDOWS_FILE_TILES", True),
            patch("spatial_export.SOURCE_FILE_MIN_BYTES", 1),
            patch("spatial_export.pack_source_file_tile", side_effect=AssertionError("错误分支")),
        ):
            actual = pack_source_tile(cache, 0, 0, 96, 54, pool, 2, threading.Event())
            np.testing.assert_array_equal(actual, original)
            cache.data = original.copy()
            cache.data[1, 1, 1] = [9, 8, 7, 6]
            actual = pack_source_tile(cache, 0, 0, 96, 54, pool, 2, threading.Event())
            np.testing.assert_array_equal(actual, cache.data)
        self.assertEqual(path.read_bytes(), before)

    def test_short_read_eof_and_mid_read_cancel(self):
        """补齐短读，拒绝EOF，并在取消后不继续读取下一段。"""
        cache, original, path = self.source()
        real_open = open
        token = threading.Event()

        class Reader:
            """只包装读句柄，不改源文件或Windows文件映射。"""

            def __init__(self, *args, **kwargs):
                """每轮创建独立计数器以注入不同的读取结果。"""
                self.stream = real_open(*args, **kwargs)
                self.calls = 0

            def __enter__(self):
                """提供普通文件上下文接口。"""
                return self

            def __exit__(self, *args):
                """即使失败或取消也关闭句柄。"""
                self.stream.close()

            def seek(self, position):
                """保留真实文件定位。"""
                return self.stream.seek(position)

            def readinto(self, destination):
                """每次最多读31字节，独立注入EOF或取消。"""
                self.calls += 1
                if scenario == "eof" and self.calls == 3:
                    return 0
                received = self.stream.readinto(destination[:31])
                if scenario == "cancel":
                    token.set()
                return received

        before = hashlib.sha256(path.read_bytes()).hexdigest()
        with ThreadPoolExecutor(1) as pool:
            for scenario in ("short", "eof", "cancel"):
                token.clear()
                with (
                    self.subTest(scenario=scenario),
                    patch("spatial_export.open", Reader, create=True),
                ):
                    if scenario == "short":
                        actual = pack_source_file_tile(cache, 3, 2, 20, 8, pool, 1, token)
                        np.testing.assert_array_equal(actual, original[:, 2:10, 3:23])
                    else:
                        error = Cancelled if scenario == "cancel" else ValueError
                        with self.assertRaises(error):
                            pack_source_file_tile(cache, 3, 2, 20, 8, pool, 1, token)
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), before)

    def test_real_parallel_file_block_above_64mib(self):
        """用实际超过64MiB的文件块覆盖并行分支，而不分配多GB源。"""
        cache, original, _ = self.source(shape=(65, 256, 1024, 4), protected=True)
        with (
            ThreadPoolExecutor(4) as pool,
            patch("spatial_export.WINDOWS_FILE_TILES", True),
            patch("spatial_export.SOURCE_FILE_MIN_BYTES", 1),
        ):
            actual = pack_source_tile(cache, 0, 0, 1024, 256, pool, 4, threading.Event())
        np.testing.assert_array_equal(actual, original)

    def test_invalid_ranges_budget_and_cancel_reject_before_reading(self):
        """越界、安全预算和预先取消均不得读取文件或分配大块内存。"""
        cache, _, _ = self.source()
        with (
            ThreadPoolExecutor(1) as pool,
            patch("spatial_export.open", side_effect=AssertionError("不应打开文件"), create=True),
        ):
            for x, y, w, h in ((-1, 0, 1, 1), (0, 54, 1, 1), (95, 0, 2, 1)):
                with self.assertRaises(ValueError):
                    pack_source_file_tile(cache, x, y, w, h, pool, 1, threading.Event())
            with patch("spatial_export.SOURCE_FILE_BLOCK_BYTES", 1):
                with self.assertRaises(ValueError):
                    pack_source_file_tile(cache, 0, 0, 1, 1, pool, 1, threading.Event())
            token = threading.Event()
            token.set()
            with self.assertRaises(Cancelled):
                pack_source_file_tile(cache, 0, 0, 1, 1, pool, 1, token)


class StreamingPeakTests(unittest.TestCase):
    def raw(self, values):
        """直接构造已知32位字，不复用被测的通道解包或峰值算法。"""
        folder = Path(self.enterContext(tempfile.TemporaryDirectory()))
        path = folder / "HDR.rgb10"
        path.write_bytes(b"".join(value.to_bytes(4, "little") for value in values))
        return path

    def test_peak_all_channels_and_chunk_boundaries_without_mapping(self):
        """完整扫描尾块和RGB三通道，同时忽略最高两位填充值。"""
        path = self.raw([0xC0000000, 0xC0000001, (3 << 30) | (997 << 20), (3 << 30) | (1001 << 10)])
        before = path.read_bytes()
        with patch("media.np.memmap", side_effect=AssertionError("峰值扫描不得映射文件")):
            for block_bytes in (4, 8, 13, 8_000_000):
                self.assertEqual(rgb10_peak_code(path, block_bytes=block_bytes), 1001)
            self.assertEqual(rgb10_peak_code(self.raw([0xC0000000])), 0)
            self.assertEqual(rgb10_peak_code(self.raw([0xC00003FF])), 1023)
        self.assertEqual(path.read_bytes(), before)

    def test_peak_rejects_partial_pixels(self):
        """末尾不足四字节必须报错，不能返回看似完整的峰值。"""
        path = self.raw([0xC00003FF])
        with path.open("ab") as stream:
            stream.write(b"\x00\x01\x02")
        with self.assertRaises(ValueError):
            rgb10_peak_code(path)
        with self.assertRaises(ValueError):
            rgb10_peak_code(path, block_bytes=3)

    def test_peak_cancel_preserves_file(self):
        """取消扫描时原缓存保持完整。"""
        path = self.raw([0xC00003FF])
        before = path.read_bytes()
        token = threading.Event()
        token.set()
        with self.assertRaises(Cancelled):
            rgb10_peak_code(path, token)
        self.assertEqual(path.read_bytes(), before)
