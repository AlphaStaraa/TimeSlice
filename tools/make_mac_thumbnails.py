"""使用实际渲染内核生成 Mac 效果封面；昼夜分割单独生成，避免示意与模式不符。"""

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "build/open-source/stage/app"))
from core.engine import GPUEngine
from media import FrameCache
from model import EFFECTS
from next_controller import mac_defaults
from preview_render import PreviewRenderer
from source_processing import grade_config, normalized_options


# 为一个模式输出静态末帧和仅在悬停时播放的动画。
def make(cache, engine, renderer, effect, folder, split=False):
    settings = dict(
        mac_defaults(effect),
        outputWidth=3840,
        outputHeight=2160,
        dayNightSplit=split,
        discardRatio=0.60,
    )
    grade = grade_config(normalized_options({}), np.linspace(0, 1, len(cache.data)))
    frames = [
        Image.fromarray(
            renderer.frame(engine, cache, effect, settings, float(u), (240, 135), grade)
        ).convert("RGB")
        for u in np.linspace(0, 1, 20)
    ]
    key = effect["key"] + ("_daynight" if split else "")
    poster = frames[-1] if effect["family"] == 0 else frames[14]
    poster.save(folder / (key + ".jpg"), quality=92)
    frames[0].save(
        folder / (key + ".gif"),
        save_all=True,
        append_images=frames[1:],
        duration=100,
        loop=0,
        optimize=True,
    )


# 接受本机帧缓存，统一生成全部标准效果及十种昼夜冻结资源。
def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cache", type=Path, required=True)
    parser.add_argument("--destination", type=Path, required=True)
    args = parser.parse_args()
    args.destination.mkdir(parents=True, exist_ok=True)
    cache = FrameCache(args.cache, json.loads((args.cache / "cache.json").read_text()))
    engine = GPUEngine()
    renderer = PreviewRenderer()
    try:
        for effect in EFFECTS:
            make(cache, engine, renderer, effect, args.destination)
            if effect["family"] == 0:
                make(cache, engine, renderer, effect, args.destination, True)
    finally:
        renderer.close()
        engine.close()
        cache.close()
    print("Generated 46 standard and 10 day/night preview pairs.", flush=True)


if __name__ == "__main__":
    main()
