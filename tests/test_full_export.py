"""完整版导出独立验证：关闭功能不扫描，已处理缓存不重做，HSL保留。"""

import json
import os
import tempfile
import threading
import unittest
from pathlib import Path
from unittest.mock import patch

import numpy as np


class FullExportTests(unittest.TestCase):
    def test_decoded_session_reuses_pixels_and_color_curve(self):
        """连续导出复用解码缓存，调色开启只补一次曲线，HSL变化不再扫源。"""
        from media import FrameCache
        from processed_render import ProcessedRenderJob
        from source_processing import normalized_options
        from source_video_cache import VideoCache

        store = VideoCache(self.root)
        self.addCleanup(store.close)
        calls = []

        def decode(info, edge, fps, folder, *args):
            """模拟一次成功解码，实际写入完整RGBA文件和缓存元数据。"""
            calls.append(folder)
            folder.mkdir()
            (folder / "frames.rgba").write_bytes(self.pixels.tobytes())
            meta = dict(
                width=128, height=96, fps=16, duration=17 / 16, frames=17, source=info["path"]
            )
            (folder / "cache.json").write_text(json.dumps(meta), encoding="utf-8")
            return FrameCache(folder, meta)

        with (
            patch("source_video_cache.FrameCache.create", side_effect=decode),
            patch(
                "processed_render.process_cache",
                side_effect=AssertionError("no processing enabled"),
            ),
        ):
            for attempt in range(3):
                options = normalized_options(dict(grade=attempt > 0, dayNight="day_to_night"))
                options["hsl"][1]["saturation"] = 10 * attempt
                job = ProcessedRenderJob(
                    self.info,
                    [(self.effect, self.settings)],
                    self.root,
                    self.root,
                    threading.Event(),
                    lambda *_: None,
                    source_options=options,
                    source_store=store,
                )
                with patch(
                    "processed_render.source_color_curve", return_value=np.linspace(0, 1, 17)
                ) as curve:
                    cache = job.prepare_cache(self.settings, self.root, self.root)
                self.assertEqual(job.cache_reused, attempt > 0)
                self.assertEqual(curve.call_count, 1 if attempt == 1 else 0)
                np.testing.assert_array_equal(cache.data, self.pixels)
                cache.close()
        self.assertEqual(len(calls), 1)

    def setUp(self):
        """生成可复现的RGBA缓存和真实文件身份，不解码或改动用户素材。"""
        from effect_models import mac_defaults
        from model import BY_ID

        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        source = self.root / "identity.mp4"
        source.write_bytes(b"identity only; prepared pixels are tested separately")
        self.info = dict(
            path=str(source), width=128, height=96, fps=16, duration=17 / 16, audio=False
        )
        self.effect = BY_ID[100]
        self.settings = dict(
            mac_defaults(self.effect),
            longEdge=128,
            quality="full",
            duration=0.75,
            fps=12,
            engine="gpu",
            encoder="cpu",
            keepAudio=False,
        )
        t, y, x = np.indices((17, 96, 128))
        self.pixels = np.stack(
            (
                (t * 13 + x * 2) % 256,
                (y * 2 + t * 11) % 256,
                (x + y + t * 9) % 256,
                np.full_like(t, 255),
            ),
            -1,
        ).astype(np.uint8)

    def make_cache(self, name, options=None):
        """写入带身份和已有处理报告的真实只读缓存，供正常租约逻辑打开。"""
        from media import FrameCache
        from prepared_source import source_key

        folder = self.root / name
        folder.mkdir()
        (folder / "frames.rgba").write_bytes(self.pixels.tobytes())
        meta = dict(
            width=128, height=96, fps=16, duration=17 / 16, frames=17, source=self.info["path"]
        )
        descriptor = None
        if options:
            key = source_key(self.info, self.settings, options)
            meta.update(
                preparedKey=key,
                sourceProcessing=dict(
                    dayNight=dict(ambiguous=False, direction="day_to_night"),
                    colorProgress=np.linspace(0, 1, 17).tolist(),
                ),
            )
            descriptor = dict(key=key, folder=str(folder))
        (folder / "cache.json").write_text(json.dumps(meta), encoding="utf-8")
        return FrameCache(folder, meta), descriptor

    def test_disabled_features_do_not_scan_source(self):
        """关闭稳定去闪调色时，导出不进入任何分析或LUT构建。"""
        from processed_render import ProcessedRenderJob

        cache, _ = self.make_cache("plain")
        job = ProcessedRenderJob(
            self.info,
            [(self.effect, self.settings)],
            self.root,
            self.root,
            threading.Event(),
            lambda *_: None,
        )
        try:
            with patch("processed_render.RenderJob.prepare_cache", return_value=cache):
                with patch.multiple(
                    "processed_render",
                    **{
                        name: unittest.mock.Mock(side_effect=AssertionError(name))
                        for name in (
                            "process_cache",
                            "analyze_direction",
                            "source_color_curve",
                            "grade_config",
                        )
                    },
                ):
                    result = job.prepare_cache(self.settings, self.root, self.root)
            self.assertIsNone(result.live_grade)
            self.assertFalse(job.cache_reused)
        finally:
            cache.close()

    def prepared_job(self):
        """建立启用稳定去闪、调色和HSL的已处理导出任务。"""
        from processed_render import ProcessedRenderJob
        from source_processing import normalized_options

        options = normalized_options(dict(stabilize="lock", deflicker="standard", grade=True))
        options["hsl"][1]["saturation"] = 15
        cache, descriptor = self.make_cache("prepared", options)
        cache.close()
        job = ProcessedRenderJob(
            self.info,
            [(self.effect, self.settings)],
            self.root,
            self.root,
            threading.Event(),
            lambda *_: None,
            source_options=options,
            prepared=descriptor,
        )
        return job

    def test_prepared_cache_and_analysis_are_reused(self):
        """已有色彩进度与昼夜分析直接复用，改HSL不重做稳定去闪。"""
        job = self.prepared_job()
        folder = Path(job.prepared["folder"])
        before = (folder / "frames.rgba").read_bytes()
        with patch.multiple(
            "processed_render",
            **{
                name: unittest.mock.Mock(side_effect=AssertionError(name))
                for name in (
                    "process_cache",
                    "analyze_direction",
                    "source_color_curve",
                )
            },
        ):
            cache = job.prepare_cache(self.settings, self.root, self.root)
        try:
            self.assertTrue(job.cache_reused)
            self.assertEqual(cache.live_grade[0], 1)
            self.assertTrue(cache.live_grade[12])
            self.assertEqual((folder / "frames.rgba").read_bytes(), before)
        finally:
            cache.close()

    @unittest.skipUnless(os.environ.get("TIMESLICE_TEST_GPU") == "1", "requires physical GPU")
    def test_gpu_spatial_export_keeps_live_grade(self):
        """真实GPU比较调色后的空间缓存像素，并实际编码解码与清理临时文件。"""
        from core.engine import GPUEngine
        from media import ffmpeg, run
        from spatial_export import spatial_frames

        job = self.prepared_job()
        cache = job.prepare_cache(self.settings, self.root, self.root)
        engine = GPUEngine()
        try:
            engine.max_buffer = 128 * 1024
            actual = np.stack(
                list(
                    spatial_frames(
                        job,
                        engine,
                        cache,
                        self.effect,
                        self.settings,
                        35,
                        None,
                        0,
                        "HSL",
                    )
                )
            )
            expected = engine.export_batch(
                cache, self.effect, self.settings, 0, 0, 128, 96, 0, 35, 35
            )
            np.testing.assert_array_equal(actual, expected)
            grade = cache.live_grade
            cache.live_grade = None
            neutral = engine.export_batch(
                cache, self.effect, self.settings, 0, 0, 128, 96, 0, 35, 35
            )
            self.assertGreater(np.abs(actual.astype(int) - neutral.astype(int)).mean(), 0.1)
            cache.live_grade = grade
        finally:
            engine.close()
            cache.close()
        with (
            patch("export_pipeline.use_spatial_cache", return_value=True),
            patch(
                "processed_render.process_cache",
                side_effect=AssertionError("must reuse"),
            ),
        ):
            output = job.run()
        record = json.loads((output / "渲染记录.json").read_text(encoding="utf-8"))[0]
        self.assertTrue(record["cacheReused"])
        self.assertEqual(record["pipeline"], "spatial-cache")
        self.assertFalse(list(self.root.glob("spatial_*")))
        self.assertTrue((Path(job.prepared["folder"]) / "frames.rgba").is_file())
        run([ffmpeg(), "-v", "error", "-i", record["output"], "-f", "null", "-"], check=True)


if __name__ == "__main__":
    unittest.main()
