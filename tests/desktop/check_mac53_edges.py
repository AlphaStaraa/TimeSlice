import ctypes
import json
import sys
from pathlib import Path
from types import SimpleNamespace

import numpy as np
from PIL import Image

R = Path(__file__).resolve().parents[2]
W = R / "build/mac53/edge-tests"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
from core.engine import CPUEngine
from model import BY_ID, params
from next_controller import mac_defaults

old = ctypes.CDLL(
    str(
        R
        / "dist/macOS-5.2.0-mac-preview.1/时刃.app/Contents/Frameworks/app/native"
        / "libtimefield.dylib"
    )
)
P = ctypes.c_void_p
CInt = ctypes.c_int
old.render_cpu.argtypes = [P, CInt, CInt, CInt, CInt, P, P, P]
cpu = CPUEngine()
w, h = 320, 180
scale = 8
low = np.empty((2, h, w, 4), np.uint8)
low[0] = [0, 0, 0, 255]
low[1] = 255
high = np.repeat(np.repeat(low, scale, axis=1), scale, axis=2)


# 使用旧版本内核生成抗锯齿对照画面。
def previous(data, e, s, u):
    _, hh, ww, _ = data.shape
    p = params(e, s, ww, hh, u, 1, 2, 0)
    out = np.empty((hh, ww, 4), np.uint8)
    old.render_cpu(p.ctypes.data, ww, hh, 0, hh, None, data.ctypes.data, out.ctypes.data)
    return out


cache = SimpleNamespace(width=w, height=h, duration=1, fps=1, data=low, folder="aa-quality")
metrics = []
panels = []
for eid in (102, 4, 104, 105, 106, 107, 108, 109, 3, 201, 5, 205):
    e = BY_ID[eid]
    s = dict(
        mac_defaults(e),
        sliceMode=1,
        sliceCount=13,
        outputWidth=w,
        outputHeight=h,
        shadowEnabled=False,
        ending=0,
    )
    u = 0.77
    before = previous(low, e, s, u)
    after = cpu.frame(cache, e, s, u)
    gold = previous(high, e, s, u).reshape(h, scale, w, scale, 4).mean((1, 3))
    a = float(abs(before.astype(float) - gold).mean())
    b = float(abs(after.astype(float) - gold).mean())
    metrics.append(dict(effect=e["key"], beforeMean=a, afterMean=b))
    if eid in (102, 4, 104, 106):
        panels.extend([before, after, np.rint(gold).astype(np.uint8)])
# Retain exact one-slice-per-pixel geometry in the floating-point field.
s = dict(
    mac_defaults(BY_ID[2]),
    sliceMode=1,
    sliceCount=3840,
    shadowEnabled=False,
    outputWidth=3840,
    outputHeight=32,
)
p = params(BY_ID[2], s, 3840, 32, 0.45, 1, 2, 0)
field = cpu.field(p, 3840, 32)
assert len(np.unique(field[0, :, 0])) == 3840
assert sum(m["afterMean"] for m in metrics) < sum(m["beforeMean"] for m in metrics) * 0.85, metrics
Image.fromarray(
    np.concatenate(
        [np.concatenate(panels[i : i + 3], axis=1) for i in range(0, len(panels), 3)], axis=0
    )
).save(W / "before-after-8x-reference.png")
(W / "report.json").write_text(
    json.dumps(dict(referenceSamplesPerPixel=64, exactPixelSlices=3840, effects=metrics), indent=2)
)
print(json.dumps(metrics), flush=True)
cpu.close()
