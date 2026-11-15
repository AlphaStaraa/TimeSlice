"""用合成素材验证冻结时间、亚像素间距、阴影及可选 CPU/GPU 对照。"""

import os
import unittest
from types import SimpleNamespace

import numpy as np
from core.engine import CPUEngine, GPUEngine
from effect_models import mac_defaults
from model import BY_ID, EFFECTS, params


def retained_time(value, discard):
    """独立计算首尾保留的冻结时刻，中央样本仍属于前半段。"""
    return value * (1 - discard) + np.where(value > 0.5, discard, 0)


def synthetic_cache(width=96, height=48, frames=17):
    """创建每帧、每行、每列均有变化的 RGBA 素材，避免纯色掩盖采样错误。"""
    t, y, x = np.indices((frames, height, width))
    data = np.stack(
        (
            (t * 17 + x * 3) % 256,
            (y * 7 + t * 9) % 256,
            (x + y + t * 23) % 256,
            np.full_like(t, 255),
        ),
        axis=-1,
    ).astype(np.uint8)
    return SimpleNamespace(
        width=width, height=height, duration=1, fps=frames - 1, data=data, folder="synthetic-test"
    )


class CoreRegression(unittest.TestCase):
    """共用原生对象，始终关闭线程池和 GPU 资源。"""

    @classmethod
    def setUpClass(cls):
        """按明确开关选择 GPU，CI 不会把未运行的 GPU 测试记作通过。"""
        cls.cpu = CPUEngine()
        cls.gpu = GPUEngine() if os.environ.get("TIMESLICE_TEST_GPU") == "1" else None

    @classmethod
    def tearDownClass(cls):
        """测试结束后释放本测试创建的设备。"""
        cls.cpu.close()
        if cls.gpu:
            cls.gpu.close()

    def test_day_night_formula(self):
        """十种冻结的背景保持连续，只有冻结片跳过中段；兼顾正反放与入出点。"""
        width, height, frames = 64, 36, 101
        for effect in (e for e in EFFECTS if e["family"] == 0):
            for reverse, start, end in ((False, 0.0, 1.0), (True, 0.1, 0.85)):
                base = dict(
                    mac_defaults(effect),
                    ending=0,
                    shadowEnabled=False,
                    sourceReverse=reverse,
                    sourceStart=start,
                    sourceEnd=end,
                )
                for discard in (0.0, 0.6, 0.9, 1.0):
                    split = dict(base, dayNightSplit=True, discardRatio=discard)
                    for u in (0.0, 0.23, 0.49, 0.51, 0.79, 1.0):
                        with self.subTest(
                            effect=effect["key"], reverse=reverse, discard=discard, u=u
                        ):
                            plain = self.cpu.field(
                                params(effect, base, width, height, u * base["build"], 100, frames),
                                width,
                                height,
                            )
                            field = self.cpu.field(
                                params(effect, split, width, height, u, 100, frames), width, height
                            )
                            np.testing.assert_allclose(field[..., 2:], plain[..., 2:], atol=1e-6)
                            if self.gpu:
                                gpu_field = self.gpu.field(
                                    params(effect, split, width, height, u, 100, frames),
                                    width,
                                    height,
                                )
                                np.testing.assert_allclose(gpu_field, field, atol=2e-5)
                            for channel in (0, 1):
                                original = (plain[..., channel] - start) / (end - start)
                                if reverse:
                                    original = 1 - original
                                original = np.where(np.abs(original - 0.5) < 1e-6, 0.5, original)
                                expected = (
                                    retained_time(original, discard)
                                    if channel == 1 or u == 1
                                    else original
                                )
                                if reverse:
                                    expected = 1 - expected
                                expected = start + expected * (end - start)
                                np.testing.assert_allclose(field[..., channel], expected, atol=2e-6)

    def test_equal_subpixel_spacing(self):
        """270 像素宽的 100 条切片，应保持 2.7 像素均匀间隔。"""
        source = np.zeros((101, 8, 270, 4), np.uint8)
        source[1::2, :, :, :3] = 255
        source[:, :, :, 3] = 255
        cache = SimpleNamespace(
            width=270, height=8, fps=100, duration=1, data=source, folder="spacing-test"
        )
        settings = dict(
            mac_defaults(BY_ID[100]),
            sliceMode=1,
            sliceCount=100,
            ending=0,
            shadowEnabled=False,
            outputWidth=1080,
            outputHeight=1920,
        )
        row = self.cpu.frame(cache, BY_ID[100], settings, 0.75)[0, :, 0].astype(float) - 127.5
        indices = np.flatnonzero(row[:-1] * row[1:] < 0)
        crossings = indices + 0.5 - row[indices] / (row[indices + 1] - row[indices])
        self.assertEqual(len(crossings), 99)
        self.assertLess(np.std(np.diff(crossings) - 2.7), 0.12)

    def test_defaults_and_pixel_limit(self):
        """统一阴影默认值，验证 4K 一像素一切的极限可以实际计算。"""
        for effect in EFFECTS:
            settings = mac_defaults(effect)
            self.assertEqual((settings["shadowStrength"], settings["shadowWidth"]), (0.25, 0.5))
            self.assertEqual(settings["shadowEnabled"], effect["family"] == 0)
            if effect["family"] == 0:
                self.assertEqual(settings["sliceCount"], 60)
        cache = synthetic_cache(width=3840, height=8, frames=2)
        settings = dict(
            mac_defaults(BY_ID[2]),
            sliceMode=1,
            sliceCount=3840,
            shadowEnabled=False,
            outputWidth=3840,
            outputHeight=8,
        )
        image = self.cpu.frame(cache, BY_ID[2], settings, 0.45, view=2)
        self.assertEqual(image.shape, (8, 3840, 4))
        self.assertTrue(np.isfinite(image).all())

    def test_all_effects_and_optional_gpu(self):
        """所有效果实际合成；GPU 开启时比较两端字段和图像，禁止静默跳过。"""
        cache = synthetic_cache()
        for effect in EFFECTS:
            for u in (0.23, 0.79):
                with self.subTest(effect=effect["key"], u=u):
                    settings = mac_defaults(effect)
                    image = self.cpu.frame(cache, effect, settings, u)
                    self.assertEqual(image.shape, cache.data.shape[1:])
                    self.assertTrue(np.all(image[..., 3] == 255))
                    if self.gpu:
                        other = self.gpu.frame(cache, effect, settings, u)
                        error = np.abs(image.astype(np.int16) - other.astype(np.int16))
                        self.assertLess(float(error.mean()), 0.5)
                        # 不连续切缝的浮点临界点可能跨过相邻时刻；沿用基线的整体误差边界。
                        # 99% 通道误差不超过 1，超过 3 的通道比例必须小于 0.3%。
                        self.assertLessEqual(float(np.quantile(error, 0.99)), 1)
                        self.assertLess(float((error > 3).mean()), 0.003)


if __name__ == "__main__":
    unittest.main()
