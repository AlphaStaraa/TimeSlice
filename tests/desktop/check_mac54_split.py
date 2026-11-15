"""验证所有冻结形状的冻结层只取首尾、底片连续、结束静止及 CPU/Metal 一致。"""

import json
import sys
from pathlib import Path
from types import SimpleNamespace

import numpy as np
from PIL import Image

R = Path(__file__).resolve().parents[2]
W = R / "build/mac54/split-tests"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
from core.engine import CPUEngine, GPUEngine
from media import FrameCache
from model import EFFECTS, params
from next_controller import mac_defaults

cpu = CPUEngine()
gpu = GPUEngine()
n, h, w = 101, 90, 160
source = np.empty((n, h, w, 4), np.uint8)
for i in range(n):
    source[i, :, :, :3] = round(i * 255 / (n - 1))
    source[i, :, :, 3] = 255
cache = SimpleNamespace(width=w, height=h, fps=100, duration=1, data=source, folder="split54")
worst = 0
checked = 0
for effect in EFFECTS:
    if effect["family"] != 0:
        continue
    for discard in (0.0, 0.6, 0.9, 1.0):
        s = dict(
            mac_defaults(effect),
            dayNightSplit=True,
            discardRatio=discard,
            shadowEnabled=False,
            fps=12,
            duration=1.0,
        )
        for u in (0, 0.23, 0.5, 0.79, 1.0):
            p = params(effect, s, w, h, u, 100, n)
            field = cpu.field(p, w, h)
            # 展开期间 A 是连续底片，只有 B 跳过中段；完成后 A/B 都是冻结结果。
            values = field[..., :2] if u == 1 else field[..., 1:2]
            keep = (1 - discard) / 2
            assert np.all((values <= keep + 1e-5) | (values >= 1 - keep - 1e-5)), (
                effect["key"],
                discard,
                u,
            )
            if u < 1:
                assert np.allclose(field[..., 0], u, atol=1e-6), (
                    effect["key"],
                    discard,
                    u,
                    "background",
                )
            a = cpu.frame(cache, effect, s, u)
            b = gpu.frame(cache, effect, s, u)
            d = abs(a.astype(np.int16) - b.astype(np.int16))
            worst = max(worst, float(d.mean()))
            assert d.mean() < 0.1, (effect["key"], d.mean(), d.max())
            checked += 1
        end = cpu.frame(cache, effect, s, 1.0)
        beyond = cpu.frame(cache, effect, s, 1.25)
        assert np.array_equal(end, beyond), effect["key"]
        # 最后一帧应与分块批量路径的最后输出完全一致，不能留下未展开的一片。
        batch = gpu.export_tile(cache, effect, s, 0, 0, w, h, 6)
        expected = gpu.frame(cache, effect, s, 1.0)
        assert np.array_equal(batch[-1], expected), (effect["key"], discard)
# 真实素材的末帧，供观察昼夜分割与单侧阴影。
real = R / "build/mac-next/real-city"
city = FrameCache(real, json.loads((real / "cache.json").read_text()))
effect = next(e for e in EFFECTS if e["key"] == "freeze_vertical")
s = dict(
    mac_defaults(effect), dayNightSplit=True, discardRatio=0.60, outputWidth=3840, outputHeight=2160
)
Image.fromarray(cpu.frame(city, effect, s, 1.0)).save(W / "Shanghai-day-night-final.png")
city.close()
cpu.close()
gpu.close()
report = dict(
    freezeShapes=10,
    ratios=[0, 0.6, 0.9, 1.0],
    comparedFrames=checked,
    onlyFrozenSamplesSkipMiddle=True,
    backgroundContinuous=True,
    lastFrameFullyRevealed=True,
    noPostRevealMotion=True,
    cpuMetalWorstMean=worst,
)
(W / "report.json").write_text(json.dumps(report, indent=2))
print(json.dumps(report), flush=True)
