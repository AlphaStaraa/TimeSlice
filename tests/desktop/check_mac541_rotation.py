"""验证旋转以起始角度控制、圆心不被旧起点选项改变，且扇形逻辑保持。"""

import json
import sys
from pathlib import Path
from types import SimpleNamespace

import numpy as np

R = Path(__file__).resolve().parents[2]
W = R / "build/mac541/rotation-tests"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
from core.engine import CPUEngine, GPUEngine
from model import BY_ID, center, params
from next_controller import mac_defaults

cpu = CPUEngine()
gpu = GPUEngine()
w = h = 201
n = 17
source = np.empty((n, h, w, 4), np.uint8)
for i in range(n):
    source[i] = [i * 14, 100, 210 - i * 9, 255]
cache = SimpleNamespace(
    width=w, height=h, duration=1, fps=16, data=source, folder="rotation-start-541"
)
y, x = np.mgrid[:h, :w]
mask = (x - w // 2) ** 2 + (y - h // 2) ** 2 > 4
worst = 0
cases = 0
try:
    for eid in (0, 104):
        effect = BY_ID[eid]
        settings = dict(
            mac_defaults(effect), turns=0, sliceMode=1, sliceCount=8, ending=0, shadowEnabled=False
        )
        fields = []
        for angle in (0, 37.5, 90, 180, 270, 360):
            s = dict(settings, rotationStartAngle=angle)
            # 即使有旧版本的位置枚举，起始角度也不再把圆心移到边缘。
            for origin in (-1, 0, 1, 2, 3, 4):
                assert center(effect, dict(s, origin=origin)) == (0.5, 0.5, 4)
            field = cpu.field(params(effect, s, w, h, 0.8, 16, n), w, h)
            fields.append(field)
            a = cpu.frame(cache, effect, s, 0.8)
            b = gpu.frame(cache, effect, s, 0.8)
            delta = abs(a.astype(np.int16) - b.astype(np.int16))
            worst = max(worst, float(delta.mean()))
            assert delta.mean() < 0.12, (eid, angle, delta.mean(), delta.max())
            cases += 1
        first = fields[0][..., :3]
        right = fields[2][..., :3]
        assert np.max(abs(right[mask] - np.rot90(first, -1)[mask])) < 1e-4, (
            eid,
            "90-degree rotation",
        )
        assert np.max(abs(fields[-1][..., :3][mask] - first[mask])) < 1e-4, (eid, "360 equals 0")
        # 0度上方的首片取样，应等于90度右方的首片取样。
        assert np.max(abs(first[20, 100] - right[100, 180])) < 1e-5
    fan = BY_ID[4]
    s = mac_defaults(fan)
    assert center(fan, dict(s, origin=0))[:2] == (0.5, 1.0)
    assert center(fan, dict(s, origin=1))[:2] == (0.5, 0.0)
    result = dict(
        effects=["旋转切片", "旋转冻结"],
        startAngleRange=[0, 360],
        zeroAtTop=True,
        positiveClockwise=True,
        fixedDefaultCentre=True,
        ninetyDegreeFieldRotation=True,
        fullTurnEqualsZero=True,
        fanOriginsUnchanged=True,
        comparedFrames=cases,
        cpuMetalMeanMax=worst,
    )
    (W / "report.json").write_text(json.dumps(result, ensure_ascii=False, indent=2))
    print(json.dumps(result, ensure_ascii=False), flush=True)
finally:
    cpu.close()
    gpu.close()
