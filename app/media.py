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
from model import ROOT, dimensions
from PIL import Image

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
    if hdr:
        raise ValueError(
            "当前版本处理 SDR 视频。这个素材是 HDR，请先导出为 Rec.709 SDR，避免亮度和颜色改变。"
        )
    return dict(
        path=str(Path(path).resolve()),
        name=Path(path).name,
        width=width,
        height=height,
        duration=duration,
        fps=float(fps[1]) if fps else 30,
        audio="Audio:" in s,
        hdr=hdr,
    )


class Cancelled(Exception):
    pass


# 检查取消标志或输入约束，必要时中止当前任务。
def check(cancel):
    if cancel and cancel.is_set():
        raise Cancelled("已取消；已完成的视频保留。")


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
    def create(cls, info, edge, fps, folder, cancel=None, progress=None):
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
            f"fps={fps:.8f},scale={w}:{h}:flags=lanczos",
            "-pix_fmt",
            "rgba",
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
                meta = dict(
                    width=w,
                    height=h,
                    fps=fps,
                    duration=info["duration"],
                    frames=frames,
                    source=info["path"],
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
}
_encoder_cache = {}


# 探测硬件编码器并在不可用时回退到软件编码。
def choose_encoder(mode="auto"):
    if mode == "cpu":
        return "libx264"
    if mode in _encoder_cache:
        return _encoder_cache[mode]
    candidates = (
        ["h264_videotoolbox"]
        if sys.platform == "darwin"
        else ["h264_nvenc", "h264_qsv", "h264_amf"]
    )
    for name in candidates:
        r = run(
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
                *ENCODERS[name],
                "-f",
                "null",
                "-",
            ],
            capture_output=True,
            timeout=20,
        )
        if r.returncode == 0:
            _encoder_cache[mode] = name
            return name
    _encoder_cache[mode] = "libx264"
    return "libx264"


# 组合原始帧输入、音频映射、编码质量和封装参数。
def encode_args(
    w, h, fps, duration, output, encoder, info, audio, input_path="pipe:0", bitrate_mbps=0
):
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
        "rgba",
        "-s",
        f"{w}x{h}",
        "-r",
        str(fps),
        "-i",
        str(input_path),
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
        "scale=iw:ih:out_color_matrix=bt709:in_range=pc:out_range=tv:"
        "flags=accurate_rnd+full_chroma_int:sws_dither=ed",
        "-pix_fmt",
        "yuv420p",
        "-color_primaries",
        "bt709",
        "-color_trc",
        "bt709",
        "-colorspace",
        "bt709",
        "-color_range",
        "tv",
        "-movflags",
        "+faststart",
        "-t",
        str(duration),
        "-n",
        str(output),
    ]
    return args
