"""固定、自生成、可随源码再分发的黄金样本输入。"""

from types import SimpleNamespace

import numpy as np


def source():
    """逐像素生成含空间纹理和时间变化的 17 帧素材，不依赖视频解码差异。"""
    count, height, width = 17, 54, 96
    time, y, x = np.indices((count, height, width))
    data = np.stack(
        (
            (time * 13 + x * 2) % 256,
            (y * 4 + time * 11) % 256,
            (x + y * 2 + time * 9) % 256,
            np.full_like(time, 255),
        ),
        axis=-1,
    ).astype(np.uint8)
    return SimpleNamespace(
        width=width,
        height=height,
        duration=1.0,
        fps=count - 1,
        data=data,
        folder="golden-fixture-v1",
    )
