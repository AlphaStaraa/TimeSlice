"""验证真实10位级数、HDR绝对亮度与线性插值，不以标签代替像素检查。"""

import os
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

import numpy as np
from core.engine import CPUEngine, GPUEngine
from model import BY_ID, default_settings
from precision_pixels import pack_rgb10, pq_decode, pq_encode, unpack_rgb10


class PrecisionColorTests(unittest.TestCase):
    def cache(self, frames, transfer="bt709", primaries="bt709"):
        """建立RGB10真实字节缓存，含独立GPU缓存身份。"""
        packed = np.stack([pack_rgb10(f) for f in frames])
        return SimpleNamespace(
            data=packed,
            width=packed.shape[2],
            height=packed.shape[1],
            duration=1,
            fps=1,
            folder=Path(self.enterContext(tempfile.TemporaryDirectory())),
            meta={
                "pixelFormat": "x2rgb10le",
                "color": {
                    "transfer": transfer,
                    "primaries": primaries,
                    "bits": 10,
                    "peakNits": 1000,
                },
            },
        )

    def engines(self):
        """CPU始终验证，显式GPU模式必须真实建立适配器。"""
        engines = [CPUEngine()]
        if os.environ.get("TIMESLICE_TEST_GPU") == "1":
            engines.append(GPUEngine())
        for engine in engines:
            self.addCleanup(engine.close)
        return engines

    def test_all_1024_levels_survive_compositing(self):
        """同一梯度通过真实合成器仍有1024级，不是RGBA8升格封装。"""
        gray = np.broadcast_to(
            np.arange(1024, dtype=np.float32)[None, :, None] / 1023, (8, 1024, 3)
        ).copy()
        cache = self.cache([gray, gray])
        effect = BY_ID[100]
        settings = dict(default_settings(effect), playback=0, _exportFormat="hevc10")
        for engine in self.engines():
            pixels = engine.frame(cache, effect, settings, 0.3, view=1)
            out = unpack_rgb10(pixels)
            self.assertEqual(len(np.unique(out[:, :, 0])), 1024, engine.label)
            np.testing.assert_allclose(out, gray, atol=1 / 1023)

    def test_deflicker_keeps_high_precision_formal_cache(self):
        """去闪只用低精度代理分析，正式像素仍保留多于256级。"""
        from media import FrameCache
        from source_processing import process_cache

        folder = Path(self.enterContext(tempfile.TemporaryDirectory()))
        gray = np.broadcast_to(
            np.linspace(0.02, 0.9, 1024, dtype=np.float32)[None, :, None], (128, 1024, 3)
        ).copy()
        frames = np.stack(
            [pack_rgb10(np.clip(gray * (1 + 0.05 * (-1) ** i), 0, 1)) for i in range(12)]
        )
        (folder / "frames.rgba").write_bytes(frames.tobytes())
        meta = dict(
            width=1024,
            height=128,
            frames=12,
            fps=12,
            duration=1,
            pixelFormat="x2rgb10le",
            color=dict(transfer="bt709", primaries="bt709", bits=10),
        )
        cache = FrameCache(folder, meta)
        try:
            report = process_cache(
                cache,
                dict(stabilize="off", deflicker="light", grade=False, dayNight="day_to_night"),
            )
            self.assertFalse(report["precision"]["formalPixelsFromProxy"])
            self.assertGreater(len(np.unique(unpack_rgb10(cache.data[0])[:, :, 0])), 400)
            self.assertEqual(cache.meta["pixelFormat"], "x2rgb10le")
        finally:
            cache.close()

    def test_pq_uses_absolute_brightness_and_linear_blending(self):
        """0与1000nit插值为500nit；原生PQ往返不压到SDR白点。"""
        white = np.full((8, 64, 3), float(pq_encode(np.array(1000.0))), np.float32)
        black = np.zeros_like(white)
        cache = self.cache([black, white], "smpte2084", "bt2020")
        settings = dict(default_settings(BY_ID[100]), playback=0, _exportFormat="hdr_pq")
        decoded_source = float(pq_decode(unpack_rgb10(cache.data[1])[0, 0, 0]))
        for engine in self.engines():
            image = unpack_rgb10(engine.frame(cache, BY_ID[100], settings, 0.5, view=1))
            nits = float(pq_decode(image[0, 0, 0]))
            self.assertLess(abs(nits - decoded_source * 0.5), 6, (engine.label, nits))
            end = unpack_rgb10(engine.frame(cache, BY_ID[100], settings, 1, view=1))
            self.assertGreater(float(pq_decode(end[0, 0, 0])), 980)

    def test_sdr_white_maps_to_203_nits_in_pq(self):
        """SDR白点进行真实亮度映射，不能直接重标为10000nit PQ。"""
        white = np.ones((8, 64, 3), np.float32)
        cache = self.cache([white, white])
        settings = dict(default_settings(BY_ID[100]), playback=0, _exportFormat="hdr_pq")
        for engine in self.engines():
            image = unpack_rgb10(engine.frame(cache, BY_ID[100], settings, 0.5, view=1))
            nits = float(pq_decode(image[0, 0, 0]))
            self.assertLess(abs(nits - 203), 3, (engine.label, nits))

    def test_hlg_identity_and_hdr_grading_keep_highlights(self):
        """HLG原生往返保持代码值；PQ加一档曝光仍保留2000nit高光。"""
        gray = np.broadcast_to(
            np.linspace(0, 1, 64, dtype=np.float32)[None, :, None], (8, 64, 3)
        ).copy()
        hlg = self.cache([gray, gray], "arib-std-b67", "bt2020")
        settings = dict(default_settings(BY_ID[100]), playback=0, _exportFormat="hdr_hlg")
        for engine in self.engines():
            out = unpack_rgb10(engine.frame(hlg, BY_ID[100], settings, 0.5, view=1))
            np.testing.assert_allclose(out, unpack_rgb10(hlg.data[0]), atol=2 / 1023)
        pq = np.full_like(gray, float(pq_encode(np.array(1000.0))))
        cache = self.cache([pq, pq], "smpte2084", "bt2020")
        grade = np.zeros(16 + 2 + 3072, np.float32)
        grade[0] = 1
        grade[1] = 2
        grade[4] = grade[6] = grade[9] = grade[11] = 1
        grade[5] = grade[10] = 1
        cache.live_grade = grade
        settings["_exportFormat"] = "hdr_pq"
        for engine in self.engines():
            out = unpack_rgb10(engine.frame(cache, BY_ID[100], settings, 0.5, view=1))
            self.assertGreater(float(pq_decode(out[0, 0, 0])), 1950, engine.label)


if __name__ == "__main__":
    unittest.main()
