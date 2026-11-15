"""对照独立时间公式验证昼夜冻结：底片连续，已冻结切片跳过中段。"""

import json
import sys
import threading
from pathlib import Path
from types import SimpleNamespace

import numpy as np

R = Path(__file__).resolve().parents[2]
W = R / "build/mac542/split-tests"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
from core.engine import CPUEngine, GPUEngine
from export_pipeline import StreamingExport
from model import BY_ID, EFFECTS, params
from next_controller import mac_defaults


def retained_time(t, discard):
    """按首尾各保留一半的规则计算冻结时刻，中央归前半段。"""
    return t * (1 - discard) + np.where(t > 0.5, discard, 0)


class StreamProbe(StreamingExport):
    """直接使用正式流式导出路径，检查常驻与分块 GPU 的时间进度。"""

    def __init__(self):
        """提供流式合成所需的取消事件，不改写正式实现。"""
        self.cancel = threading.Event()

    def update(self, *args):
        """本测试只核对输出帧，忽略界面进度通知。"""
        pass


def main():
    """验证十种形状、正倒放、入出点、原片视图以及正式导出路径。"""
    cpu = CPUEngine()
    gpu = GPUEngine()
    n, h, w = 101, 72, 160
    source = np.empty((n, h, w, 4), np.uint8)
    for i in range(n):
        source[i] = [round(i * 255 / (n - 1))] * 3 + [255]
    cache = SimpleNamespace(
        width=w, height=h, fps=100, duration=1, data=source, folder="daynight542"
    )
    worst = 0.0
    max_pixel = 0
    fields_checked = frames_checked = source_checked = 0
    shapes = [e for e in EFFECTS if e["family"] == 0]
    try:
        for effect in shapes:
            for reverse, start, end in ((False, 0.0, 1.0), (True, 0.1, 0.85)):
                base = dict(
                    mac_defaults(effect),
                    ending=0,
                    shadowEnabled=False,
                    sourceReverse=reverse,
                    sourceStart=start,
                    sourceEnd=end,
                    fps=12,
                    duration=1.0,
                )
                for discard in (0.0, 0.6, 0.9, 1.0):
                    settings = dict(base, dayNightSplit=True, discardRatio=discard)
                    for u in (0.0, 0.23, 0.49, 0.51, 0.79, 1.0):
                        # 标准冻结用相同展开进度作为独立的几何和未改时刻基准。
                        plain = cpu.field(
                            params(effect, base, w, h, u * base["build"], 100, n), w, h
                        )
                        field = cpu.field(params(effect, settings, w, h, u, 100, n), w, h)
                        np.testing.assert_allclose(field[..., 2:], plain[..., 2:], atol=1e-6)
                        for channel in (0, 1):
                            original = (plain[..., channel] - start) / (end - start)
                            if reverse:
                                original = 1 - original
                            original = np.where(np.abs(original - 0.5) < 1e-6, 0.5, original)
                            # 展开时 A 是连续底片、B 才是冻结片；完成后两路都是冻结片。
                            expected = (
                                retained_time(original, discard)
                                if channel == 1 or u == 1
                                else original
                            )
                            if reverse:
                                expected = 1 - expected
                            expected = start + expected * (end - start)
                            np.testing.assert_allclose(
                                field[..., channel],
                                expected,
                                atol=2e-6,
                                err_msg=(
                                    f"{effect['key']}: discard={discard}, u={u}, channel={channel}"
                                ),
                            )
                        gpu_field = gpu.field(params(effect, settings, w, h, u, 100, n), w, h)
                        np.testing.assert_allclose(gpu_field, field, atol=3e-5)
                        fields_checked += 1
                        a = cpu.frame(cache, effect, settings, u)
                        b = gpu.frame(cache, effect, settings, u)
                        delta = np.abs(a.astype(np.int16) - b.astype(np.int16))
                        worst = max(worst, float(delta.mean()))
                        max_pixel = max(max_pixel, int(delta.max()))
                        assert delta.mean() < 0.1, (effect["key"], discard, u, delta.mean())
                        assert delta.max() <= 3, (effect["key"], discard, u, delta.max())
                        frames_checked += 1
                    np.testing.assert_array_equal(
                        cpu.frame(cache, effect, settings, 1.0),
                        cpu.frame(cache, effect, settings, 1.25),
                    )
                    for engine in (cpu, gpu):
                        for u in (0.49, 0.51):
                            # 原片视图不能跟随冻结选帧跳时；正倒放和素材入出点仍生效。
                            actual = engine.frame(cache, effect, settings, u, view=1)
                            expected = engine.frame(cache, effect, base, u, view=1)
                            np.testing.assert_array_equal(actual, expected)
                            source_checked += 1
                    # 批量导出的最后一帧必须完整展开，并与单帧预览一致。
                    batch = gpu.export_tile(cache, effect, settings, 0, 0, w, h, 6)
                    np.testing.assert_array_equal(
                        batch[-1], gpu.frame(cache, effect, settings, 1.0)
                    )

        effect = BY_ID[100]
        settings = dict(
            mac_defaults(effect),
            dayNightSplit=True,
            discardRatio=0.6,
            shadowEnabled=False,
            sliceMode=1,
            sliceCount=60,
        )
        field = cpu.field(params(effect, settings, w, h, 0.51, 100, n), w, h)
        # 参考片的关键同屏关系：中央刚出现夜景片，右边仍是连续的中间时段。
        assert abs(float(field[h // 2, 150, 0]) - 0.51) < 1e-6
        assert (
            field[h // 2, 82, 2] == 1
            and abs(float(field[h // 2, 82, 1]) - (0.6 + 0.4 * 31 / 60)) < 1e-6
        )
        assert field[h // 2, 150, 2] == 0
        before = cpu.field(params(effect, settings, w, h, 0.49, 100, n), w, h)
        assert abs(float(field[0, 150, 0] - before[0, 150, 0]) - 0.02) < 1e-6

        # 100% 跳过中段只让冻结片取首末帧，未冻结区仍有中间亮度。
        endpoints = dict(settings, discardRatio=1.0)
        field = cpu.field(params(effect, endpoints, w, h, 0.51, 100, n), w, h)
        assert set(np.unique(field[..., 1])) <= {0.0, 1.0}
        assert abs(float(field[0, 150, 0]) - 0.51) < 1e-6

        # CPU、GPU常驻与强制分块三种正式流式路径均包含同一个最终时刻。
        stream = StreamProbe()
        expected = np.stack([cpu.frame(cache, effect, settings, i / 5) for i in range(6)])
        for engine in (cpu, gpu):
            actual = np.stack(
                list(stream.stream_frames(engine, cache, effect, settings, 6, None, 0, "test"))
            )
            assert np.abs(actual.astype(int) - expected.astype(int)).max() <= 1
        original_limit = gpu.max_buffer
        try:
            gpu.max_buffer = 256 * 1024
            actual = np.stack(
                list(stream.stream_frames(gpu, cache, effect, settings, 6, None, 0, "test"))
            )
            assert np.abs(actual.astype(int) - expected.astype(int)).max() <= 1
        finally:
            gpu.max_buffer = original_limit
        result = dict(
            freezeShapes=len(shapes),
            ratios=[0, 0.6, 0.9, 1.0],
            fieldCases=fields_checked,
            comparedFrames=frames_checked,
            sourceViewCases=source_checked,
            backgroundContinuous=True,
            onlyFrozenSamplesSkipMiddle=True,
            nightSliceOverMidtimeBackground=True,
            reverseAndTrim=True,
            finalFrameFullyRevealed=True,
            noPostRevealMotion=True,
            cpuResidentGpuTiledGpuStreams=True,
            cpuMetalWorstMean=worst,
            cpuMetalPixelMax=max_pixel,
        )
        (W / "report.json").write_text(json.dumps(result, indent=2))
        print(json.dumps(result), flush=True)
    finally:
        cpu.close()
        gpu.close()


if __name__ == "__main__":
    main()
