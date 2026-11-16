"""验证视口预览真正解读RGB10，且所有导出格式都以RGBA8显示。"""

import os
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

import numpy as np
from core.engine import CPUEngine, GPUEngine
from effect_models import mac_defaults
from model import BY_ID
from precision_pixels import pack_rgb10, preview_rgb8
from preview_render import PreviewRenderer
from source_processing import grade_config, normalized_options


class PrecisionPreviewTests(unittest.TestCase):
    def setUp(self):
        """使用实际渲染内核和独立缓存身份，避免测试之间复用旧纹理。"""
        self.folder = Path(self.enterContext(tempfile.TemporaryDirectory()))
        self.cpu = CPUEngine()
        self.addCleanup(self.cpu.close)
        self.engines = [self.cpu]
        if os.environ.get("TIMESLICE_TEST_GPU") == "1":
            gpu = GPUEngine()
            self.addCleanup(gpu.close)
            self.engines.append(gpu)
        self.preview = PreviewRenderer()
        self.addCleanup(self.preview.close)

    def cache(self, transfer="bt709"):
        """相同灰阶帧的正确预览必须保持中性，不能出现彩色噪点。"""
        ramp = np.linspace(0.05, 0.9, 96, dtype=np.float32)
        rgb = np.broadcast_to(ramp[None, :, None], (54, 96, 3)).copy()
        data = np.stack([pack_rgb10(rgb)] * 4)
        return SimpleNamespace(
            width=96,
            height=54,
            duration=1,
            fps=3,
            data=data,
            folder=self.folder / transfer,
            meta=dict(
                pixelFormat="x2rgb10le",
                color=dict(
                    transfer=transfer,
                    primaries="bt709" if transfer == "bt709" else "bt2020",
                    peakNits=1000,
                    bits=10,
                ),
            ),
        )

    def test_rgb10_and_hdr_viewport_match_independent_display_reference(self):
        """SDR10/PQ/HLG按独立NumPy参考显示，选择HDR导出也不能直接显示打包字节。"""
        effect = BY_ID[100]
        grade = np.zeros(16, np.float32)
        for transfer in ("bt709", "smpte2084", "arib-std-b67"):
            cache = self.cache(transfer)
            expected = preview_rgb8(cache.data[0], cache.meta["color"])
            for mode in ("h264", "hevc10", "hdr_pq", "hdr_hlg"):
                settings = dict(mac_defaults(effect), exportFormat=mode, _exportFormat=mode)
                original = dict(settings)
                for engine in self.engines:
                    with self.subTest(transfer=transfer, output=mode, engine=engine.kind):
                        actual = self.preview.frame(
                            engine, cache, effect, settings, 0.4, (96, 54), grade, view=1
                        )
                        difference = np.abs(actual.astype(np.int16) - expected.astype(np.int16))
                        self.assertLessEqual(int(difference.max()), 2)
                        self.assertTrue(np.all(actual[:, :, 3] == 255))
                        self.assertEqual(settings, original)

    def test_graded_freeze_preview_agrees_with_correct_full_frame_renderer(self):
        """开启HSL后，扇形等冻结效果的视口像素应与正确色彩链路的正式尺寸预览一致。"""
        cache = self.cache()
        options = normalized_options(dict(grade=True, dayNight="day_to_night"))
        options["hsl"][1]["saturation"] = 20
        grade = grade_config(options, np.linspace(0, 1, len(cache.data), dtype=np.float32))
        cache.live_grade = grade
        effects = [
            next(e for e in BY_ID.values() if e["family"] == 0 and e["shape"] == shape)
            for shape in (0, 2, 3, 4)
        ]
        for effect in effects:
            settings = dict(mac_defaults(effect), exportFormat="hdr_pq")
            expected = self.cpu.frame(cache, effect, settings, 0.4)
            for engine in self.engines:
                with self.subTest(effect=effect["key"], engine=engine.kind):
                    actual = self.preview.frame(
                        engine, cache, effect, settings, 0.4, (96, 54), grade
                    )
                    difference = np.abs(actual.astype(np.int16) - expected.astype(np.int16))
                    self.assertLess(float(difference.mean()), 0.5)
                    self.assertLessEqual(int(difference.max()), 3)
