import json
import subprocess
import sys
import time
from pathlib import Path
from types import SimpleNamespace

import numpy as np
from PIL import Image

R = Path(__file__).resolve().parents[2]
W = R / "build/mac53/real-tests"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
from core.engine import CPUEngine, GPUEngine
from media import FrameCache, ffmpeg
from model import BY_ID
from next_controller import mac_defaults
from preview_render import PreviewRenderer
from source_processing import grade_config, normalized_options, source_color_curve

cache = (
    FrameCache.open(R / "build/mac-next/real-city")
    if hasattr(FrameCache, "open")
    else FrameCache(
        R / "build/mac-next/real-city",
        json.loads((R / "build/mac-next/real-city/cache.json").read_text()),
    )
)
gpu = GPUEngine()
cpu = CPUEngine()
preview = PreviewRenderer()
opts = normalized_options({"grade": True, "dayNight": "day_to_night"})
opts["hsl"][5]["hue"] = -15
grade = grade_config(opts, source_color_curve(cache.data))
e = BY_ID[102]
s = dict(mac_defaults(e), outputWidth=3840, outputHeight=2160)
a = preview.frame(gpu, cache, e, s, 0.78, (1440, 810), grade)
start = time.perf_counter()
for i in range(8):
    b = preview.frame(gpu, cache, e, s, 0.78, (1440, 810), grade)
seconds = (time.perf_counter() - start) / 8
Image.fromarray(a).save(W / "Shanghai-live-preview.png")
source = cache.meta["source"]
cache.close()
frames = []
for at in (0, 19):
    raw = subprocess.run(
        [
            ffmpeg(),
            "-v",
            "error",
            "-ss",
            str(at),
            "-i",
            source,
            "-frames:v",
            "1",
            "-pix_fmt",
            "rgba",
            "-f",
            "rawvideo",
            "pipe:1",
        ],
        stdout=subprocess.PIPE,
        check=True,
    ).stdout
    frames.append(np.frombuffer(raw, np.uint8).reshape(2160, 3840, 4))
full = SimpleNamespace(
    width=3840, height=2160, duration=1, fps=1, data=np.stack(frames), folder="Shanghai4K-native"
)
start = time.perf_counter()
a = cpu.frame(full, e, s, 0.77)
cpu_time = time.perf_counter() - start
start = time.perf_counter()
b = gpu.frame(full, e, s, 0.77)
gpu_time = time.perf_counter() - start
d = abs(a.astype(np.int16) - b.astype(np.int16))
assert d.mean() < 0.1, (d.mean(), d.max())
Image.fromarray(b).save(W / "Shanghai-4K-diagonal.png")
report = dict(
    realViewport=[1440, 810],
    sourceFrames=60,
    liveGradeSeconds=seconds,
    fullResolution=[3840, 2160],
    cpuSeconds=cpu_time,
    metalSeconds=gpu_time,
    cpuMetalMean=float(d.mean()),
    cpuMetalMax=int(d.max()),
    note="One 4K frame comparison using two original source frames, not a full-length 4K render.",
)
(W / "report.json").write_text(json.dumps(report, indent=2))
print(json.dumps(report), flush=True)
preview.close()
cpu.close()
gpu.close()
