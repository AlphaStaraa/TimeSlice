"""Numerically check equal-width freeze strips against an independent tent-filter oracle."""

import sys
from pathlib import Path
from types import SimpleNamespace

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "build/open-source/stage/app"
sys.path.insert(0, str(STAGE))
from core.engine import CPUEngine
from model import BY_ID, default_settings


# 为测试建立可重复的合成帧缓存。
def cache(width, count, white=False, horizontal=False):
    w, h = (8, width) if horizontal else (width, 8)
    data = np.zeros((count + 1, h, w, 4), np.uint8)
    for frame in range(count + 1):
        data[frame, :, :, :3] = 255 if white or frame % 2 else 0
        data[frame, :, :, 3] = 255
    return SimpleNamespace(width=w, height=h, duration=1, fps=count, data=data, folder="spacing")


# 用独立参考计算核对算法输出。
def oracle(width, count, output, strength, white=False, side=0, direction=0, physical_shadow=False):
    offsets = (np.arange(4096) + 0.5) / 4096 * 2 - 1
    kernel = 1 - np.abs(offsets)
    q = (np.arange(width)[:, None] + 0.5 + offsets) / width
    valid = (q >= 0) & (q <= 1)
    q = np.clip(q, 0, 1 - 1e-12)
    physical = q.copy()
    if direction == 1:
        q = 1 - q
    index = np.minimum(np.floor(q * count), count - 1)
    phase = physical * count - np.floor(physical * count) if physical_shadow else q * count - index
    distance = phase if side else 1 - phase
    shadow_width = 0.2
    feather = shadow_width * 0.82
    solid = shadow_width - feather
    t = np.clip((distance - solid) / feather, 0, 1)
    dark = 1 - t * t * (3 - 2 * t)
    fade = np.clip((output / count - 1) / 1.5, 0, 1)
    fade = fade * fade * (3 - 2 * fade)
    color = np.ones_like(q) * 255 if white else ((index + 1) % 2) * 255
    color *= 1 - strength * fade * dark
    weights = kernel * valid
    return np.sum(color * weights, axis=1) / np.sum(weights, axis=1)


# 检测条形图中的切缝位置以量化间距误差。
def crossings(row):
    z = row.astype(float) - 127.5
    ids = np.flatnonzero(z[:-1] * z[1:] < 0)
    return ids + 0.5 - z[ids] / (z[ids + 1] - z[ids])


# 组织此入口的初始化、主流程和退出清理。
def main():
    cpu = CPUEngine()
    try:
        for width, count, output in ((270, 100, 1080), (480, 100, 1920), (270, 300, 1080)):
            for horizontal in (False, True):
                effect = BY_ID[101 if horizontal else 100]
                c = cache(width, count, horizontal=horizontal)
                for direction in (0, 1):
                    for side in (0, 1):
                        settings = dict(
                            default_settings(effect),
                            sliceMode=1,
                            sliceCount=count,
                            ending=0,
                            shadowEnabled=True,
                            shadowStrength=0.33,
                            shadowWidth=0.2,
                            shadowSoftness=0.82,
                            shadowSide=side,
                            direction=direction,
                            outputWidth=output,
                            outputHeight=output,
                        )
                        image = cpu.frame(c, effect, settings, 0.75)
                        row = image[:, 0, 0] if horizontal else image[0, :, 0]
                        expected = oracle(
                            width,
                            count,
                            output,
                            0.33,
                            side=side,
                            direction=direction,
                            physical_shadow=(STAGE / "resources/mac-release.json").is_file(),
                        )
                        error = np.abs(row - expected)
                        assert error.mean() < 0.4 and error.max() < 1.1, (
                            width,
                            count,
                            horizontal,
                            direction,
                            side,
                            error.max(),
                        )
        c = cache(270, 100)
        settings = dict(
            default_settings(BY_ID[100]),
            sliceMode=1,
            sliceCount=100,
            ending=0,
            shadowEnabled=False,
            outputWidth=1080,
            outputHeight=1920,
        )
        positions = crossings(cpu.frame(c, BY_ID[100], settings, 0.75)[0, :, 0])
        assert len(positions) == 99 and np.std(np.diff(positions) - 2.7) < 0.12
        print("Freeze strip coverage, shadow integration and subpixel spacing passed.")
    finally:
        cpu.close()


if __name__ == "__main__":
    main()
