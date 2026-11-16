"""分批渲染后直接送入编码器，省去整条未压缩输出的落盘与重读。"""

import json
import math
import shutil
import subprocess
import time
import uuid

import numpy as np
from export_quality import bitrate_report
from media import check, choose_encoder, encode_args, popen, stop_process, time_map, verify_output
from model import density, duration
from render import gpu_tile
from spatial_export import spatial_frames, use_spatial_cache, workspace_root
from video_color import color_settings


class StreamingExport:
    def stream_frames(self, engine, cache, effect, settings, total, mapping, index, detail):
        """按有限内存批次合成输出帧；小源缓存走常驻 GPU，较大源按空间分块。"""
        if engine.kind != "gpu" or settings.get("reference"):
            reference = None
            try:
                if settings.get("reference"):
                    from core.reference import ReferenceRenderer

                    reference = ReferenceRenderer(cache)
                for frame in range(total):
                    check(self.cancel)
                    image = (
                        reference.frame(effect["id"], frame / settings["fps"], settings)
                        if reference
                        else engine.frame(
                            cache,
                            effect,
                            settings,
                            frame
                            / max(
                                1,
                                total - 1
                                if settings.get("dayNightSplit") and effect["family"] == 0
                                else total,
                            ),
                            mapping,
                        )
                    )
                    yield image
                    self.update(index, "合成与编码", 0.96 * (frame + 1) / total, detail)
            finally:
                if reference:
                    reference.close()
            return
        if use_spatial_cache(cache, total, getattr(self, "working_cache_root", self.cache_root)):
            yield from spatial_frames(
                self, engine, cache, effect, settings, total, mapping, index, detail
            )
            return
        if cache.data.nbytes <= engine.max_buffer * 0.8:
            for frame in range(total):
                check(self.cancel)
                yield engine.frame(
                    cache,
                    effect,
                    settings,
                    frame
                    / max(
                        1,
                        total - 1
                        if settings.get("dayNightSplit") and effect["family"] == 0
                        else total,
                    ),
                    mapping,
                )
                self.update(index, "合成与编码", 0.96 * (frame + 1) / total, detail)
            return
        # 输出批次最多占用 512 MiB；不以整个成片时长分配 RGBA 文件。
        batch = max(1, min(120, (512 * 1024**2) // (cache.width * cache.height * 4)))
        cols, rows = gpu_tile(
            cache.width, cache.height, max(batch, len(cache.data)), engine.max_buffer
        )
        tiles = math.ceil(cache.width / cols) * math.ceil(cache.height / rows)
        for first in range(0, total, batch):
            check(self.cancel)
            count = min(batch, total - first)
            frames = np.empty((count, cache.height, cache.width, 4), np.uint8)
            done = 0
            for y in range(0, cache.height, rows):
                for x in range(0, cache.width, cols):
                    check(self.cancel)
                    w = min(cols, cache.width - x)
                    h = min(rows, cache.height - y)
                    frames[:, y : y + h, x : x + w] = engine.export_batch(
                        cache, effect, settings, x, y, w, h, first, count, total, mapping
                    )
                    done += 1
                    self.update(
                        index,
                        "切片合成",
                        0.96 * (first + count * 0.85 * done / tiles) / total,
                        detail,
                    )
            for frame, image in enumerate(frames, first + 1):
                check(self.cancel)
                yield image
                self.update(index, "合成与编码", 0.96 * frame / total, detail)

    def frame_data(self, image):
        """把连续像素直接交给编码管道，避免完整版逐帧额外复制整幅4K画面。"""
        return memoryview(image if image.flags.c_contiguous else np.ascontiguousarray(image))

    def run(self):
        """共享一次准备好的素材缓存，逐项流式合成、编码，并写入可核查的耗时记录。"""
        stamp = time.strftime("%Y%m%d_%H%M%S") + "_" + uuid.uuid4().hex[:5]
        root = self.output / ("时刃_" + stamp)
        root.mkdir(parents=True, exist_ok=False)
        self.working_cache_root = workspace_root(self)
        workspace = self.working_cache_root / ("export_" + stamp)
        workspace.mkdir()
        cache = None
        engine = None
        report = []
        first = self.jobs[0][1]
        try:
            self.update(-2, "输出文件夹", 0, str(root))
            cache = self.prepare_cache(first, workspace, root)
            engine = self.create_engine(first)
            encoder = choose_encoder(first["encoder"], first.get("exportFormat", "h264"))
            for index, (effect, settings) in enumerate(self.jobs):
                check(self.cancel)
                self.effect_pipeline = "streamed"
                self.output_staging_bytes = 0
                start = time.monotonic()
                total = max(1, round(duration(effect, settings) * settings["fps"]))
                length = total / settings["fps"]
                final = root / f"{index + 1:02d}_{effect['name']}.mp4"
                partial = root / f".{index + 1:02d}.partial.mp4"
                log = workspace / f"encode_{index}.log"
                progress = workspace / f"encode_{index}.progress"
                process = None
                mapping = None
                settings = color_settings(
                    cache,
                    dict(
                        settings,
                        _exportDither=bool(settings.get("gradientDither", True)),
                        _exportFormat=settings.get("exportFormat", "h264"),
                    ),
                )
                if settings.get("customMap") and settings.get("mapPath"):
                    mapping, bits = time_map(
                        settings["mapPath"], cache.width, cache.height, settings["mapMode"] == 1
                    )
                    settings["mapBits"] = bits
                detail = engine.label + " / " + encoder
                try:
                    args = encode_args(
                        cache.width,
                        cache.height,
                        settings["fps"],
                        length,
                        partial,
                        encoder,
                        self.info,
                        settings["keepAudio"],
                        bitrate_mbps=settings.get("bitrateMbps", 0),
                        output_format=settings.get("exportFormat", "h264"),
                    )
                    with log.open("wb") as error:
                        process = popen(
                            self.encoder_args(args, progress),
                            stdin=subprocess.PIPE,
                            stdout=subprocess.DEVNULL,
                            stderr=error,
                        )
                        for image in self.stream_frames(
                            engine, cache, effect, settings, total, mapping, index, detail
                        ):
                            process.stdin.write(self.frame_data(image))
                        process.stdin.close()
                        self.wait_for_encoder(process, index, progress, length, 0.96, detail)
                    if process.returncode:
                        raise ValueError(
                            "视频编码失败："
                            + log.read_text(errors="replace", encoding="utf-8")[-1000:]
                        )
                    check(self.cancel)
                    verified_color = verify_output(partial, settings.get("exportFormat", "h264"))
                    partial.rename(final)
                    report.append(
                        dict(
                            effect=effect,
                            settings=settings,
                            output=str(final),
                            engine=engine.label,
                            encoder=encoder,
                            verifiedColor=verified_color,
                            encoding=bitrate_report(
                                cache.width,
                                cache.height,
                                settings["fps"],
                                settings.get("bitrateMbps", 0),
                                settings.get("exportFormat", "h264"),
                            ),
                            frames=total,
                            seconds=time.monotonic() - start,
                            sourceCache=cache.meta,
                            slices=density(effect, settings, cache.width, cache.height)[0],
                            cacheReused=self.cache_reused,
                            pipeline=self.effect_pipeline,
                            temporaryOutputRGBABytes=self.output_staging_bytes,
                        )
                    )
                    (root / "渲染记录.json").write_text(
                        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
                    )
                    self.update(index, "已完成", 1, str(final))
                except BrokenPipeError as caught:
                    raise ValueError(
                        "视频编码失败：" + log.read_text(errors="replace", encoding="utf-8")[-1000:]
                    ) from caught
                finally:
                    stop_process(process)
                    partial.unlink(missing_ok=True)
            return root
        finally:
            if cache:
                cache.close()
            if engine:
                engine.close()
            shutil.rmtree(workspace, ignore_errors=True)
