"""真实HEVC编码/解码回归，防止缓存转换或标记丢失导致假10位。"""

import tempfile
import unittest
from pathlib import Path

import numpy as np
from media import FrameCache, choose_encoder, encode_args, probe, run, verify_output
from precision_pixels import pack_rgb10, unpack_rgb10


class PrecisionCodecTests(unittest.TestCase):
    def test_main10_sps_tags_and_decode_precision(self):
        """三种输出均实际写10位SPS和正确色彩；解码缓存必须保留超过256级。"""
        width, height = 1024, 128
        rgb = np.broadcast_to(
            np.linspace(0, 1, width, dtype=np.float32)[None, :, None], (height, width, 3)
        ).copy()
        frames = pack_rgb10(rgb).tobytes() * 4
        with tempfile.TemporaryDirectory(prefix="timeslice-main10-") as folder:
            for mode in ("hevc10", "hdr_pq", "hdr_hlg"):
                video = Path(folder) / (mode + ".mp4")
                encoder = choose_encoder("cpu", mode)
                result = run(
                    encode_args(
                        width,
                        height,
                        12,
                        1 / 3,
                        video,
                        encoder,
                        {"audio": False},
                        False,
                        bitrate_mbps=60,
                        output_format=mode,
                    ),
                    input=frames,
                    capture_output=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr.decode(errors="replace"))
                actual = verify_output(video, mode)
                self.assertEqual(actual["lumaBits"], 10)
                info = probe(video)
                self.assertEqual(info["hdr"], mode.startswith("hdr_"))
                cache = FrameCache.create(
                    info, 0, 0, Path(folder) / (mode + "-cache"), precision=True
                )
                try:
                    levels = len(np.unique(unpack_rgb10(cache.data[0])[:, :, 0]))
                    self.assertGreater(levels, 400, (mode, encoder, levels))
                    self.assertEqual(cache.meta["pixelFormat"], "x2rgb10le")
                finally:
                    cache.close()


if __name__ == "__main__":
    unittest.main()
