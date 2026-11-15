"""防止角向效果在奇数预览尺寸的中心轴出现单列或单行伪影。"""

import os
import unittest

import numpy as np


class PreviewAxisTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("TIMESLICE_TEST_GPU") == "1", "requires physical GPU")
    def test_odd_viewport_axes_match_cpu(self):
        """横竖奇数视口、四个扇形起点及三种运动均须通过独立CPU参考。"""
        from core.engine import CPUEngine, GPUEngine
        from effect_models import mac_defaults
        from golden_input import source
        from model import EFFECTS
        from preview_render import PreviewRenderer
        from source_processing import grade_config, normalized_options

        cache = source()
        cpu, gpu, preview = CPUEngine(), GPUEngine(), PreviewRenderer()
        grade = grade_config(
            normalized_options({}), np.linspace(0, 1, len(cache.data), dtype=np.float32)
        )
        try:
            for effect in (e for e in EFFECTS if e["shape"] == 3):
                for origin in range(4):
                    settings = dict(
                        mac_defaults(effect), origin=origin, outputWidth=3840, outputHeight=2160
                    )
                    for width, height in ((257, 145), (145, 257)):
                        expected = preview.frame(
                            cpu, cache, effect, settings, 0.63, (width, height), grade
                        )
                        actual = preview.frame(
                            gpu, cache, effect, settings, 0.63, (width, height), grade
                        )
                        difference = abs(actual.astype(np.int16) - expected.astype(np.int16))
                        label = f"{effect['key']} origin={origin} {width}x{height}"
                        self.assertLess(float(difference.mean()), 0.01, label)
                        self.assertLess(float(difference[:, width // 2].mean()), 0.05, label)
                        self.assertLess(float(difference[height // 2].mean()), 0.05, label)
        finally:
            preview.close()
            cpu.close()
            gpu.close()
