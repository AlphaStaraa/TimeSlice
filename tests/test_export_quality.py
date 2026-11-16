"""验证码率影响真实编码结果，并核对亚色阶平均亮度与CPU/GPU一致性。"""

import os
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

import numpy as np
from core.engine import CPUEngine, GPUEngine
from export_quality import recommended_bitrate, target_bitrate
from media import encode_args, ffmpeg, run
from model import BY_ID, default_settings


class ExportQualityTests(unittest.TestCase):
    def test_resolution_rate_and_orientation(self):
        """主要输出规格具有明确推荐值，旋转画布不改变码率，手动值不被自动覆盖。"""
        for width, height, fps, expected in (
            (1920, 1080, 30, 20),
            (1920, 1080, 60, 35),
            (3840, 2160, 30, 60),
            (3840, 2160, 60, 100),
        ):
            self.assertEqual(recommended_bitrate(width, height, fps), expected)
            self.assertEqual(recommended_bitrate(height, width, fps), expected)
            self.assertEqual(target_bitrate(width, height, fps, 73.5), 73_500_000)
        for invalid in (-1, 0.5, 501, float("nan"), float("inf"), True):
            with self.assertRaises(ValueError):
                target_bitrate(3840, 2160, 60, invalid)

    def test_fractional_gradient_and_optional_gpu(self):
        """有序抖动保留亚色阶的平均亮度，整数原像素保持不变，GPU启用时必须真实对照。"""
        frames = np.full((2, 64, 64, 4), 20, np.uint8)
        frames[1, :, :, :3] = 21
        frames[:, :, :, 3] = 255
        cache = SimpleNamespace(
            data=frames,
            width=64,
            height=64,
            duration=1,
            fps=1,
            folder=Path(self.enterContext(tempfile.TemporaryDirectory())),
        )
        effect = BY_ID[100]
        settings = dict(default_settings(effect), playback=0)
        cpu = CPUEngine()
        try:
            old = cpu.frame(cache, effect, settings, 0.3, view=1)
            settings["_exportDither"] = True
            image = cpu.frame(cache, effect, settings, 0.3, view=1)
            self.assertLess(abs(float(image[:, :, 0].mean()) - 20.3), 0.03)
            self.assertGreater(abs(float(old[:, :, 0].mean()) - 20.3), 0.2)
            np.testing.assert_array_equal(cpu.frame(cache, effect, settings, 0, view=1), frames[0])
            if os.environ.get("TIMESLICE_TEST_GPU") == "1":
                gpu = GPUEngine()
                try:
                    other = gpu.frame(cache, effect, settings, 0.3, view=1)
                    self.assertLessEqual(
                        int(np.abs(other.astype(int) - image.astype(int)).max()), 1
                    )
                    self.assertLess(abs(float(other[:, :, 0].mean()) - 20.3), 0.03)
                finally:
                    gpu.close()
        finally:
            cpu.close()

    def test_custom_bitrate_changes_real_encoded_quality(self):
        """实际编码同一段灰度细节，较高目标应保留更多细节并生成更大的视频。"""
        random = np.random.default_rng(105)
        gray = random.integers(32, 224, (12, 180, 320), dtype=np.uint8)
        frames = np.empty((12, 180, 320, 4), np.uint8)
        frames[:, :, :, :3] = gray[:, :, :, None]
        frames[:, :, :, 3] = 255
        samples = []
        with tempfile.TemporaryDirectory(prefix="timeslice-quality-") as folder:
            for mbps in (1, 12):
                target = Path(folder) / f"{mbps}.mp4"
                run(
                    encode_args(
                        320,
                        180,
                        30,
                        0.4,
                        target,
                        "libx264",
                        {"audio": False},
                        False,
                        bitrate_mbps=mbps,
                    ),
                    input=frames.tobytes(),
                    capture_output=True,
                    check=True,
                )
                decoded = run(
                    [
                        ffmpeg(),
                        "-v",
                        "error",
                        "-i",
                        str(target),
                        "-f",
                        "rawvideo",
                        "-pix_fmt",
                        "rgba",
                        "-",
                    ],
                    capture_output=True,
                    check=True,
                ).stdout
                image = np.frombuffer(decoded, np.uint8).reshape(frames.shape)
                error = float(np.abs(image[:, :, :, 0].astype(float) - gray).mean())
                samples.append((target.stat().st_size, error))
            self.assertGreater(samples[1][0], samples[0][0] * 1.25, samples)
            self.assertLess(samples[1][1], samples[0][1], samples)


if __name__ == "__main__":
    unittest.main()
