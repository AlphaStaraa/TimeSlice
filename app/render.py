import json
import math
import re
import shutil
import subprocess
import time
import uuid
from pathlib import Path

import numpy as np
from core.engine import CPUEngine, GPUEngine
from export_quality import bitrate_report
from media import FrameCache, check, choose_encoder, encode_args, popen, stop_process, time_map
from model import MAC42, density, duration


# 根据帧数与显存绑定限制计算安全的空间分块尺寸。
def gpu_tile(width, height, frames, max_buffer):
    if MAC42:
        pixels = min(int(max_buffer * 0.8), 192 * 1024**2) // (frames * 4)
        if pixels:
            cols = min(width, pixels)
            rows = min(height, 128, pixels // cols)
            return cols, rows
    else:
        tile = 128
        while tile * tile * 4 * frames > max_buffer * 0.8:
            tile //= 2
        if tile:
            return tile, tile
    raise ValueError("视频过长，GPU 单像素时间缓存也超出显存绑定限制，请使用 CPU。")


class RenderJob:
    report_encoding = False

    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self, info, jobs, output, cache_root, cancel, notify):
        self.info = info
        self.jobs = jobs
        self.output = Path(output)
        self.cache_root = Path(cache_root)
        self.cancel = cancel
        self.notify = notify

    # 更新当前任务状态并把进度通知上层。
    def update(self, index, status, progress=0, detail=""):
        self.notify(index, status, progress, detail)

    # 为编码命令附加可读取的进度输出配置。
    def encoder_args(self, args, progress_file):
        if self.report_encoding:
            return [args[0], "-progress", str(progress_file), "-stats_period", "0.25", *args[1:]]
        return args

    # 等待编码器结束并读取封装进度，期间响应取消。
    def wait_for_encoder(self, process, index, progress_file, duration, render_fraction, detail):
        if self.report_encoding:
            progress = render_fraction
            self.update(index, "编码与封装", progress, detail)
            while process.poll() is None:
                check(self.cancel)
                if progress_file.is_file():
                    with progress_file.open("rb") as stream:
                        stream.seek(max(0, progress_file.stat().st_size - 4096))
                        positions = re.findall(rb"(?:^|\n)out_time_us=(\d+)\n", stream.read())
                    if positions:
                        encoded = min(1, int(positions[-1]) / (duration * 1_000_000))
                        measured = min(0.995, render_fraction + (1 - render_fraction) * encoded)
                        if measured > progress:
                            progress = measured
                            self.update(index, "编码与封装", progress, detail)
                time.sleep(0.08)
        else:
            while process.poll() is None:
                check(self.cancel)
                time.sleep(0.08)

    # 准备可供正式合成读取的素材缓存并报告处理结果。
    def prepare_cache(self, first, workspace, root):
        return FrameCache.create(
            self.info,
            first["longEdge"],
            0 if first["quality"] == "full" else 30,
            workspace,
            self.cancel,
            lambda v: self.update(-1, "读取原片", v, "建立时间缓存"),
        )

    # 按用户选择建立 GPU 或 CPU 渲染器，必要时回退。
    def create_engine(self, first):
        try:
            if first["engine"] == "cpu":
                raise RuntimeError("已选择 CPU")
            return GPUEngine()
        except Exception as err:
            if first["engine"] == "gpu":
                raise ValueError("GPU 未就绪：" + str(err) + "。可改选自动或 CPU。")
            return CPUEngine()

    # 执行当前任务的主流程并把结果或失败交给调用方。
    def run(self):
        stamp = time.strftime("%Y%m%d_%H%M%S") + "_" + uuid.uuid4().hex[:5]
        root = self.output / ("时刃_" + stamp)
        root.mkdir(parents=True, exist_ok=False)
        cache = None
        engine = None
        report = []
        first = self.jobs[0][1]
        workspace = self.cache_root / ("export_" + stamp)
        try:
            if self.report_encoding:
                self.update(-2, "输出文件夹", 0, str(root))
            self.update(-1, "读取原片", 0, "按所选时间精度建立缓存；不降低输出尺寸")
            cache = self.prepare_cache(first, workspace, root)
            engine = self.create_engine(first)
            encoder = choose_encoder(first["encoder"])
            for i, (effect, s) in enumerate(self.jobs):
                s = dict(s, _exportDither=bool(s.get("gradientDither", True)))
                check(self.cancel)
                start = time.monotonic()
                total = round(duration(effect, s) * s["fps"])
                length = total / s["fps"]
                final = root / f"{i + 1:02d}_{effect['name']}.mp4"
                partial = root / f".{i + 1:02d}_{effect['key']}.partial.mp4"
                used = engine.label
                if effect["id"] == 406 and engine.kind == "gpu":
                    used += " · 折页坐标采样由 CPU 完成"
                if s.get("reference"):
                    used = "CPU · 原 PR 逐层对照"
                mp = None
                if s.get("customMap") and s.get("mapPath"):
                    mp, bits = time_map(s["mapPath"], cache.width, cache.height, s["mapMode"] == 1)
                    s = dict(s, mapBits=bits)
                self.update(i, "渲染中", 0, used + " / " + encoder)
                log = workspace / f"encode_{i}.log"
                progress_file = workspace / f"encode_{i}.progress"
                raw = None
                process = None
                out = None
                reference = None
                try:
                    if engine.kind == "gpu" and effect["id"] != 406 and not s.get("reference"):
                        needed = total * cache.width * cache.height * 4
                        if shutil.disk_usage(workspace).free < needed + 512 * 1024**2:
                            raise ValueError(
                                f"GPU 分块缓存还需要 {needed / 1024**3:.1f} GB，"
                                "可改用 CPU 流式渲染以减少占用。"
                            )
                        raw = workspace / f"output_{i}.rgba"
                        out = np.memmap(
                            raw,
                            mode="w+",
                            dtype=np.uint8,
                            shape=(total, cache.height, cache.width, 4),
                        )
                        cols, rows = gpu_tile(
                            cache.width,
                            cache.height,
                            max(total, len(cache.data)),
                            engine.max_buffer,
                        )
                        num = math.ceil(cache.width / cols) * math.ceil(cache.height / rows)
                        done = 0
                        for y in range(0, cache.height, rows):
                            for x in range(0, cache.width, cols):
                                check(self.cancel)
                                w = min(cols, cache.width - x)
                                h = min(rows, cache.height - y)
                                out[:, y : y + h, x : x + w] = engine.export_tile(
                                    cache, effect, s, x, y, w, h, total, mp
                                )
                                done += 1
                                self.update(i, "渲染中", 0.87 * done / num, used + " / " + encoder)
                        out.flush()
                        out._mmap.close()
                        out = None
                        with log.open("wb") as err:
                            args = encode_args(
                                cache.width,
                                cache.height,
                                s["fps"],
                                length,
                                partial,
                                encoder,
                                self.info,
                                s["keepAudio"],
                                raw,
                                bitrate_mbps=s.get("bitrateMbps", 0),
                            )
                            process = popen(
                                self.encoder_args(args, progress_file),
                                stdout=subprocess.DEVNULL,
                                stderr=err,
                            )
                            self.wait_for_encoder(
                                process, i, progress_file, length, 0.87, used + " / " + encoder
                            )
                    else:
                        reference = None
                        if s.get("reference"):
                            from core.reference import ReferenceRenderer

                            reference = ReferenceRenderer(cache)
                        with log.open("wb") as err:
                            args = encode_args(
                                cache.width,
                                cache.height,
                                s["fps"],
                                length,
                                partial,
                                encoder,
                                self.info,
                                s["keepAudio"],
                                bitrate_mbps=s.get("bitrateMbps", 0),
                            )
                            process = popen(
                                self.encoder_args(args, progress_file),
                                stdin=subprocess.PIPE,
                                stdout=subprocess.DEVNULL,
                                stderr=err,
                            )
                            for frame in range(total):
                                check(self.cancel)
                                image = (
                                    reference.frame(effect["id"], frame / s["fps"], s)
                                    if reference
                                    else engine.frame(cache, effect, s, frame / total, mp)
                                )
                                process.stdin.write(image.tobytes())
                                self.update(
                                    i, "渲染中", 0.96 * (frame + 1) / total, used + " / " + encoder
                                )
                            process.stdin.close()
                            if self.report_encoding:
                                self.wait_for_encoder(
                                    process, i, progress_file, length, 0.96, used + " / " + encoder
                                )
                            else:
                                process.wait()
                    if process.returncode:
                        raise ValueError(
                            "视频编码失败："
                            + log.read_text(errors="replace", encoding="utf-8")[-1000:]
                        )
                    check(self.cancel)
                    partial.rename(final)
                    elapsed = time.monotonic() - start
                    item = dict(
                        effect=effect,
                        settings=s,
                        output=str(final),
                        engine=used,
                        encoder=encoder,
                        encoding=bitrate_report(
                            cache.width, cache.height, s["fps"], s.get("bitrateMbps", 0)
                        ),
                        frames=total,
                        seconds=elapsed,
                        sourceCache=cache.meta,
                        slices=density(effect, s, cache.width, cache.height)[0],
                    )
                    report.append(item)
                    (root / "渲染记录.json").write_text(
                        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf8"
                    )
                    self.update(i, "已完成", 1, str(final))
                finally:
                    if reference:
                        reference.close()
                        reference = None
                    if out is not None:
                        out._mmap.close()
                        out = None
                    stop_process(process)
                    partial.unlink(missing_ok=True)
                    if raw:
                        raw.unlink(missing_ok=True)
            return root
        finally:
            if cache:
                cache.close()
            if engine:
                engine.close()
            shutil.rmtree(workspace, ignore_errors=True)
