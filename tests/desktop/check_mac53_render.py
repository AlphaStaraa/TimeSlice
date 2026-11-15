import json
import sys
import time
from pathlib import Path
from types import SimpleNamespace

import numpy as np
from PIL import Image

R = Path(__file__).resolve().parents[2]
W = R / "build/mac53/render-tests"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
from core.engine import CPUEngine, GPUEngine
from model import BY_ID, EFFECTS
from next_controller import mac_defaults
from preview_render import PreviewRenderer
from source_processing import DEFAULT_OPTIONS, grade_config, grade_frame, normalized_options

cpu = CPUEngine()
gpu = GPUEngine()
preview = PreviewRenderer()
rng = np.random.default_rng(4)
n, h, w = 17, 72, 96
source = np.empty((n, h, w, 4), np.uint8)
for i in range(n):
    source[i, :, :, 0] = i * 14
    source[i, :, :, 1] = np.arange(w)[None, :] * 2
    source[i, :, :, 2] = np.arange(h)[:, None] * 3
    source[i, :, :, 3] = 255
cache = SimpleNamespace(
    width=w, height=h, duration=1, fps=16, data=source, folder="render53-synthetic"
)
curve = np.linspace(0, 1, n, dtype=np.float32)
opts = normalized_options(DEFAULT_OPTIONS)
grade = grade_config(opts, curve)
worst = 0
maxerr = 0
for e in EFFECTS:
    s = dict(
        mac_defaults(e), outputWidth=w, outputHeight=h, sliceMode=1, sliceCount=17, reference=False
    )
    for u in (0.23, 0.81):
        a = cpu.frame(cache, e, s, u)
        b = gpu.frame(cache, e, s, u)
        error = np.abs(a.astype(np.int16) - b.astype(np.int16))
        worst = max(worst, float(error.mean()))
        maxerr = max(maxerr, int(error.max()))
        assert error.mean() < 0.05 and error.max() <= 3, (
            e["key"],
            u,
            float(error.mean()),
            int(error.max()),
        )
print("46 effects CPU / Metal:", worst, maxerr, flush=True)
opts["grade"] = True
opts["look"] = "custom"
opts["hsl"][0].update(hue=22, saturation=-40, luminance=30)
opts["hsl"][5].update(hue=-19, saturation=35, luminance=-20)
grade = grade_config(opts, curve)
e = BY_ID[102]
s = dict(mac_defaults(e), outputWidth=3840, outputHeight=2160, reference=False)
a = preview.frame(cpu, cache, e, s, 0.75, (384, 288), grade)
b = preview.frame(gpu, cache, e, s, 0.75, (384, 288), grade)
error = np.abs(a.astype(np.int16) - b.astype(np.int16))
assert error.mean() < 0.5, (error.mean(), error.max())
Image.fromarray(a).save(W / "live-grade-cpu.png")
Image.fromarray(b).save(W / "live-grade-metal.png")
# At an exact source frame, the live GPU equations agree with export grading.
i = 9
u = i / 16
expected = grade_frame(source[i], opts, float(curve[i]))
actual = preview.frame(gpu, cache, e, s, u, (w, h), grade, view=1)
error = np.abs(expected.astype(np.int16) - actual.astype(np.int16))
assert error.mean() < 0.4, (error.mean(), error.max())
# Zero HSL adjustments preserve the original grading exactly.
opts2 = normalized_options(opts)
opts2["hsl"] = [dict(hue=0, saturation=0, luminance=0) for _ in range(8)]
base = grade_frame(source[9], opts2, float(curve[9]))
shift = grade_frame(source[9], opts, float(curve[9]))
assert abs(base.astype(float) - shift).mean() > 2
# One output pixel per vertical strip must remain exact.
wide = np.empty((2, 32, 3840, 4), np.uint8)
wide[0] = [0, 0, 0, 255]
wide[1] = [255, 255, 255, 255]
flat = SimpleNamespace(width=3840, height=32, duration=1, fps=1, data=wide, folder="pixel53")
s = dict(
    mac_defaults(BY_ID[2]),
    sliceMode=1,
    sliceCount=3840,
    shadowEnabled=False,
    outputWidth=3840,
    outputHeight=32,
)
im = cpu.frame(flat, BY_ID[2], s, 0.45, view=2)
assert len(np.unique(im[0, :, 0])) > 80
# Antialiasing produces fractional coverage on high-contrast oblique boundaries.
white = np.full((2, 180, 320, 4), 255, np.uint8)
black = white.copy()
black[0, :, :, :3] = 0
flat = SimpleNamespace(width=320, height=180, duration=1, fps=1, data=black, folder="alias53")
e = BY_ID[102]
s = dict(
    mac_defaults(e),
    sliceMode=1,
    sliceCount=7,
    build=0.9,
    shadowEnabled=False,
    outputWidth=320,
    outputHeight=180,
    softness=0,
)
im = cpu.frame(flat, e, s, 0.78)
Image.fromarray(im).save(W / "oblique-aa.png")
# Timings after GPU warm-up: grade edits reuse source buffers.
start = time.perf_counter()
for i in range(8):
    preview.frame(gpu, cache, BY_ID[102], s, 0.75, (960, 540), grade)
elapsed = (time.perf_counter() - start) / 8
report = dict(
    effects=46,
    comparedFrames=92,
    cpuMetalMeanMax=worst,
    cpuMetalPixelMax=maxerr,
    liveGradeExportMean=float(error.mean()),
    warmLivePreviewSeconds=elapsed,
    hsl=True,
    pixelCuts3840=True,
)
(W / "report.json").write_text(json.dumps(report, indent=2))
print(json.dumps(report), flush=True)
preview.close()
cpu.close()
gpu.close()
