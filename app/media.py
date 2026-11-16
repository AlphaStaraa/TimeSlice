import json
import math
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

import numpy as np
from export_quality import target_bitrate
from hevc_stream import sequence_info
from model import ROOT, dimensions
from PIL import Image
from video_color import output_spec, source_color

CREATE_NO_WINDOW = 0x08000000 if sys.platform == "win32" else 0


# 执行当前任务的主流程并把结果或失败交给调用方。
def run(args, **kwargs):
    return subprocess.run(args, creationflags=CREATE_NO_WINDOW, **kwargs)


# 以平台兼容的选项启动异步子进程。
def popen(args, **kwargs):
    return subprocess.Popen(args, creationflags=CREATE_NO_WINDOW, **kwargs)


# 关闭管道并终止未退出的子进程，防止编码器残留。
def stop_process(process):
    if process is None:
        return
    if process.stdin and not process.stdin.closed:
        try:
            process.stdin.close()
        except (BrokenPipeError, OSError):
            pass
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=3)


# 优先返回安装包内的 FFmpeg，否则使用项目依赖提供的可执行文件。
def ffmpeg():
    packaged = ROOT / "bin" / ("ffmpeg.exe" if sys.platform == "win32" else "ffmpeg")
    if packaged.exists():
        return str(packaged)
    import imageio_ffmpeg

    return imageio_ffmpeg.get_ffmpeg_exe()


# 解析本机视频的尺寸、时长、帧率与音轨，拒绝不能正确处理的素材。
def probe(path):
    result = run(
        [
            ffmpeg(),
            "-hide_banner",
            "-i",
            str(path),
            "-map",
            "0:v:0",
            "-frames:v",
            "1",
            "-an",
            "-f",
            "null",
            "-",
        ],
        capture_output=True,
        text=True,
        encoding="utf8",
        errors="replace",
        timeout=45,
    )
    s = result.stderr
    if result.returncode:
        raise ValueError("无法读取这个视频。请选择可正常播放的 MP4、MOV 或 MKV。\n" + s[-700:])
    dur = re.search(r"Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)", s)
    videos = [line for line in s.splitlines() if "Video:" in line]
    line = videos[-1] if videos else ""
    dim = re.search(r"\b(\d{2,6})x(\d{2,6})\b", line)
    fps = re.search(r"(\d+(?:\.\d+)?) fps", line)
    if not dur or not dim:
        raise ValueError("未读到有效的视频时长或尺寸。")
    duration = int(dur[1]) * 3600 + int(dur[2]) * 60 + float(dur[3])
    width, height = map(int, dim.groups())
    if duration <= 0:
        raise ValueError("视频没有有效时长。")
    first = videos[0] if videos else ""
    hdr = "smpte2084" in first or "arib-std-b67" in first
    pix = re.search(r"\b(?:yuv\w+|p010le|p016le|gbrp\w+|rgb48\w*|nv12)\b", first)
    pixel_format = pix[0] if pix else "yuv420p"
    depth = re.search(r"p(10|12|16)(?:le|be)", pixel_format)
    bits = (
        int(depth[1])
        if depth
        else 10
        if pixel_format == "p010le"
        else 16
        if "48" in pixel_format
        else 8
    )
    color = dict(
        transfer="smpte2084"
        if "smpte2084" in first
        else "arib-std-b67"
        if "arib-std-b67" in first
        else "iec61966-2-1"
        if "iec61966-2-1" in first
        else "bt709",
        primaries="bt2020" if "bt2020" in first else "bt709",
        matrix="bt2020nc" if "bt2020" in first else "bt709",
        range="pc" if "(pc" in first or ", pc" in first else "tv",
        bits=bits,
        hdr=hdr,
        peakNits=1000 if hdr else 203,
    )
    descriptor = re.search(r"\((?:tv|pc),\s*([^,)]+)", first)
    tagged = descriptor[1].strip() if descriptor else "unknown"
    values = tagged.split("/")
    color["tagsPresent"] = "unknown" not in values and tagged != "unspecified"
    if len(values) == 3:
        color["matrix"] = values[0] if values[0] != "unknown" else "bt709"
        color["primaries"] = values[1] if values[1] != "unknown" else "bt709"
        color["transfer"] = values[2] if values[2] != "unknown" else "bt709"
    return dict(
        path=str(Path(path).resolve()),
        name=Path(path).name,
        width=width,
        height=height,
        duration=duration,
        fps=float(fps[1]) if fps else 30,
        audio="Audio:" in s,
        hdr=hdr,
        color=color,
    )


class Cancelled(Exception):
    pass


# 检查取消标志或输入约束，必要时中止当前任务。
def check(cancel):
    if cancel and cancel.is_set():
        raise Cancelled("已取消；已完成的视频保留。")


def rgb10_peak_code(path, cancel=None, block_bytes=8_000_000):
    """逐块扫描RGB10最高代码值，不将整段HDR缓存映射进进程工作集。"""
    block_bytes = int(block_bytes) // 4 * 4
    if block_bytes < 4:
        raise ValueError("高精度扫描分块必须至少包含一个像素")
    maximum = 0
    with Path(path).open("rb") as stream:
        while True:
            check(cancel)
            raw = stream.read(block_bytes)
            if not raw:
                break
            if len(raw) % 4:
                raise ValueError("高精度缓存字节不完整")
            block = np.frombuffer(raw, dtype="<u4")
            maximum = max(
                maximum,
                int(((block >> 20) & 1023).max()),
                int(((block >> 10) & 1023).max()),
                int((block & 1023).max()),
            )
            del block
    return maximum


class FrameCache:
    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self, folder, meta):
        self.folder = Path(folder)
        self.width = meta["width"]
        self.height = meta["height"]
        self.duration = meta["duration"]
        self.fps = meta["fps"]
        self.meta = meta
        self.data = np.memmap(
            self.folder / "frames.rgba",
            mode="r",
            dtype=np.uint8,
            shape=(meta["frames"], self.height, self.width, 4),
        )

    # 建立缓存或底层资源，成功后才向调用方公开完整结果。
    @classmethod
    def create(cls, info, edge, fps, folder, cancel=None, progress=None, precision=False):
        folder = Path(folder)
        folder.mkdir(parents=True, exist_ok=True)
        w, h = dimensions(info, edge)
        fps = min(info["fps"], fps) if fps else info["fps"]
        fps = max(1, fps)
        estimated = math.ceil(info["duration"] * fps) * w * h * 4
        if shutil.disk_usage(folder).free < estimated + 512 * 1024**2:
            raise ValueError(
                f"缓存需要约 {estimated / 1024**3:.1f} GB 空间，请更换缓存位置或降低输出尺寸。"
            )
        target = folder / "frames.rgba"
        partial = folder / "frames.partial"
        log = folder / "decode.log"
        color = source_color(info)
        high = bool(precision or color["hdr"])
        pixel_format = "x2rgb10le" if high else "rgba"
        filters = f"fps={fps:.8f},scale={w}:{h}:flags=lanczos"
        if high:
            filters = filters.replace("flags=lanczos", "flags=lanczos+accurate_rnd+full_chroma_int")
            matrix = "bt2020" if color["matrix"].startswith("bt2020") else "bt709"
            filters += f":in_color_matrix={matrix}:in_range={color['range']}:out_range=pc"
        args = [
            ffmpeg(),
            "-hide_banner",
            "-loglevel",
            "error",
            "-nostdin",
            "-i",
            info["path"],
            "-map",
            "0:v:0",
            "-an",
            "-vf",
            filters,
            "-pix_fmt",
            pixel_format,
            "-threads",
            "4",
            "-f",
            "rawvideo",
            "-y",
            str(partial),
        ]
        with log.open("wb") as err:
            process = popen(args, stdout=subprocess.DEVNULL, stderr=err)
            try:
                while process.poll() is None:
                    check(cancel)
                    if progress:
                        progress(
                            min(0.99, partial.stat().st_size / max(1, estimated))
                            if partial.exists()
                            else 0
                        )
                    time.sleep(0.08)
                if process.returncode:
                    raise ValueError(
                        "读取视频失败：" + log.read_text(errors="replace", encoding="utf-8")[-1000:]
                    )
                check(cancel)
                size = partial.stat().st_size
                frames = size // (w * h * 4)
                if frames < 2 or size % (w * h * 4):
                    raise ValueError("解码的视频帧不完整。")
                partial.replace(target)
                if high and color["hdr"]:
                    maximum = rgb10_peak_code(target, cancel)
                    if color["transfer"] == "smpte2084":
                        from precision_pixels import pq_decode

                        observed = float(pq_decode(np.array(maximum / 1023)))
                    else:
                        value = maximum / 1023
                        scene = (
                            value * value / 3
                            if value <= 0.5
                            else (math.exp((value - 0.55991073) / 0.17883277) + 0.28466892) / 12
                        )
                        observed = 1000 * scene**1.2
                    color = dict(
                        color,
                        peakNits=max(color["peakNits"], min(10000, observed)),
                        observedPeakNits=observed,
                    )
                meta = dict(
                    width=w,
                    height=h,
                    fps=fps,
                    duration=info["duration"],
                    frames=frames,
                    source=info["path"],
                    pixelFormat=pixel_format,
                    color=color,
                )
                (folder / "cache.json").write_text(
                    json.dumps(meta, ensure_ascii=False), encoding="utf8"
                )
                return cls(folder, meta)
            except BaseException:
                stop_process(process)
                partial.unlink(missing_ok=True)
                raise

    # 关闭当前对象持有的资源，避免重复占用文件、线程或设备。
    def close(self):
        proxy = getattr(self, "analysis_proxy", None)
        if proxy is not None:
            proxy.close()
            self.analysis_proxy = None
        if getattr(self, "data", None) is not None:
            self.data._mmap.close()
            self.data = None

    # 关闭并删除可重建的临时缓存，不触及输入素材。
    def discard(self):
        self.close()
        shutil.rmtree(self.folder, ignore_errors=True)


# 读取黑白时间图并转换为指定分辨率的归一化取样场。
def time_map(path, w, h, relative=False):
    im = Image.open(path)
    if im.mode in ("I;16", "I;16L", "I;16B", "I"):
        bits = 16
        q = np.asarray(im, dtype=np.float32) / 65535
    elif im.mode == "F":
        bits = 32
        q = np.asarray(im, dtype=np.float32)
    else:
        bits = 8
        rgba = np.asarray(im.convert("RGBA"), dtype=np.float32) / 255
        gray = rgba[..., :3] @ np.array([0.2126, 0.7152, 0.0722], np.float32)
        neutral = 128 / 255 if relative else 0.5
        q = gray * rgba[..., 3] + neutral * (1 - rgba[..., 3])
    q = np.asarray(
        Image.fromarray(q.astype(np.float32)).resize((w, h), Image.Resampling.BILINEAR),
        dtype=np.float32,
    ).copy()
    return np.clip(q, 0, 1), bits


ENCODERS = {
    "h264_videotoolbox": ["-c:v", "h264_videotoolbox"],
    "h264_nvenc": ["-c:v", "h264_nvenc", "-rc", "vbr"],
    "h264_qsv": ["-c:v", "h264_qsv"],
    "h264_amf": ["-c:v", "h264_amf", "-quality", "quality"],
    "libx264": ["-c:v", "libx264", "-preset", "medium"],
    "hevc_videotoolbox": ["-c:v", "hevc_videotoolbox", "-profile:v", "main10"],
    "hevc_videotoolbox_sw": [
        "-c:v",
        "hevc_videotoolbox",
        "-profile:v",
        "main10",
        "-require_sw",
        "1",
    ],
    "hevc_nvenc": ["-c:v", "hevc_nvenc", "-profile:v", "main10", "-rc", "vbr"],
    "hevc_qsv": ["-c:v", "hevc_qsv", "-profile:v", "main10"],
    "hevc_amf": ["-c:v", "hevc_amf", "-profile:v", "main10", "-quality", "quality"],
    "libx265": [
        "-c:v",
        "libx265",
        "-profile:v",
        "main10",
        "-preset",
        "medium",
        "-x265-params",
        "log-level=error:pools=2:frame-threads=2",
    ],
}
_encoder_cache = {}


# 探测硬件编码器并在不可用时回退到软件编码。
def choose_encoder(mode="auto", output_format="h264"):
    """以真实编码和SPS确认Main10能力，无法满足格式时禁止退成8位。"""
    spec = output_spec(output_format)
    high = spec["bits"] == 10
    if mode == "cpu" and not high:
        return "libx264"
    key = (mode, high)
    if key in _encoder_cache:
        return _encoder_cache[key]
    if high:
        if mode == "cpu":
            candidates = (
                ["hevc_videotoolbox_sw", "libx265"] if sys.platform == "darwin" else ["libx265"]
            )
        else:
            candidates = (
                ["hevc_videotoolbox", "hevc_videotoolbox_sw", "libx265"]
                if sys.platform == "darwin"
                else ["hevc_nvenc", "hevc_qsv", "hevc_amf", "libx265"]
            )
    else:
        candidates = (
            ["h264_videotoolbox"]
            if sys.platform == "darwin"
            else ["h264_nvenc", "h264_qsv", "h264_amf"]
        )
    for name in candidates:
        pixel = "yuv420p10le" if name == "libx265" else "p010le"
        options = ["-vf", "format=" + pixel] if high else []
        try:
            result = run(
                [
                    ffmpeg(),
                    "-hide_banner",
                    "-loglevel",
                    "error",
                    "-f",
                    "lavfi",
                    "-i",
                    "color=s=128x128:r=30:d=0.1",
                    "-frames:v",
                    "1",
                    *options,
                    *ENCODERS[name],
                    *(["-movflags", "frag_keyframe+empty_moov"] if high else []),
                    "-f",
                    "mp4" if high else "null",
                    "-",
                ],
                capture_output=True,
                timeout=30,
            )
            if result.returncode:
                continue
            if high:
                actual = sequence_info(result.stdout)
                if actual["lumaBits"] != 10 or actual["chromaBits"] != 10:
                    continue
            _encoder_cache[key] = name
            return name
        except (ValueError, subprocess.TimeoutExpired):
            continue
    if high:
        raise ValueError(
            "当前设备或编码方式无法输出真正的HEVC Main10。请改选其他编码方式或H.264兼容格式。"
        )
    _encoder_cache[key] = "libx264"
    return "libx264"


# 组合原始帧输入、音频映射、编码质量和封装参数。
def encode_args(
    w,
    h,
    fps,
    duration,
    output,
    encoder,
    info,
    audio,
    input_path="pipe:0",
    bitrate_mbps=0,
    output_format="h264",
):
    spec = output_spec(output_format)
    high = spec["bits"] == 10
    if high != (encoder.startswith("hevc_") or encoder == "libx265"):
        raise ValueError("编码器与所选输出格式不一致，已停止导出以避免位深降级")
    input_pixel = "x2rgb10le" if high else "rgba"
    output_pixel = (
        "yuv420p10le" if high and encoder == "libx265" else "p010le" if high else "yuv420p"
    )
    matrix = spec["matrix"]
    bits = target_bitrate(w, h, fps, bitrate_mbps)
    args = [
        ffmpeg(),
        "-hide_banner",
        "-loglevel",
        "error",
        "-nostdin",
        "-f",
        "rawvideo",
        "-pix_fmt",
        input_pixel,
        "-s",
        f"{w}x{h}",
        "-r",
        str(fps),
        "-i",
        str(input_path),
    ]
    position = args.index("-i")
    args[position:position] = [
        "-color_primaries",
        spec["primaries"],
        "-color_trc",
        spec["transfer"],
        "-colorspace",
        "bt2020nc" if matrix == "bt2020" else "bt709",
        "-color_range",
        "pc",
    ]
    if audio and info["audio"]:
        args += [
            "-i",
            info["path"],
            "-map",
            "0:v:0",
            "-map",
            "1:a:0?",
            "-af",
            "apad",
            "-c:a",
            "aac",
            "-b:a",
            "192k",
        ]
    else:
        args += ["-an"]
    args += ENCODERS[encoder] + [
        "-b:v",
        str(bits),
        "-maxrate",
        str(round(bits * 1.5)),
        "-bufsize",
        str(bits * 2),
        "-vf",
        f"scale=iw:ih:out_color_matrix={matrix}:in_range=pc:out_range=tv:"
        "flags=accurate_rnd+full_chroma_int:sws_dither=ed",
        "-pix_fmt",
        output_pixel,
        "-color_primaries",
        spec["primaries"],
        "-color_trc",
        spec["transfer"],
        "-colorspace",
        "bt2020nc" if matrix == "bt2020" else "bt709",
        "-color_range",
        "tv",
        "-movflags",
        "+faststart",
        "-t",
        str(duration),
        "-n",
        str(output),
    ]
    if high:
        args[-1:-1] = ["-tag:v", "hvc1"]
    return args


def verify_output(path, output_format="h264"):
    """正式发布文件前验证SPS真实10位和传递函数，失败时保留错误而非假装HDR。"""
    spec = output_spec(output_format)
    if spec["bits"] == 8:
        return None
    with Path(path).open("rb") as stream:
        header = stream.read(4 * 1024 * 1024)
        try:
            sequence = sequence_info(header)
        except ValueError:
            stream.seek(max(0, Path(path).stat().st_size - 4 * 1024 * 1024))
            sequence = sequence_info(stream.read())
    info = probe(path)
    color = info["color"]
    if sequence["lumaBits"] != 10 or sequence["chromaBits"] != 10:
        raise ValueError("编码器实际输出不足10位，已停止保存")
    if (
        not color["tagsPresent"]
        or color["transfer"] != spec["transfer"]
        or color["primaries"] != spec["primaries"]
    ):
        raise ValueError("成片色彩标记与目标不一致，已停止保存")
    return dict(sequence, transfer=color["transfer"], primaries=color["primaries"])
