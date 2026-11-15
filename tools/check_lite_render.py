"""验证轻量 GPU 批量合成与既有逐批实现完全一致，覆盖全部效果和昼夜尾帧。"""

import importlib
import sys
import tempfile
import threading
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import numpy as np


def main():
    """逐项核对合成后的真实像素，并释放显存与线程资源。"""
    root = Path(__file__).resolve().parents[1]
    sys.path[:0] = [str(root / "build/lite/stage/app"), str(root / "tests")]
    model = importlib.import_module("model")
    defaults = importlib.import_module("effect_models").mac_defaults
    job_type = importlib.import_module("lite_render").LiteRenderJob
    cache = importlib.import_module("golden_input").source()
    engine = importlib.import_module("core.engine").GPUEngine()
    checked = 0
    try:
        with tempfile.TemporaryDirectory() as folder:
            job = job_type({}, [], folder, folder, threading.Event(), lambda *_: None, store=None)
            for effect in model.EFFECTS:
                variants = (False, True) if effect["family"] == 0 else (False,)
                for split in variants:
                    settings = dict(defaults(effect), dayNightSplit=split, discardRatio=0.6)
                    frames = np.stack(
                        list(
                            job.stream_frames(
                                engine, cache, effect, settings, 9, None, 0, "comparison"
                            )
                        )
                    )
                    expected = engine.export_batch(
                        cache, effect, settings, 0, 0, cache.width, cache.height, 0, 9, 9
                    )
                    np.testing.assert_array_equal(
                        frames, expected, err_msg=f"{effect['key']} split={split}"
                    )
                    checked += len(frames)
            # 强制走低显存分块路径，避免优化只在小素材有效。
            original_limit = engine.max_buffer
            engine.max_buffer = 128 * 1024
            tiled_checked = 0
            for effect in model.EFFECTS:
                variants = (False, True) if effect["family"] == 0 else (False,)
                for split in variants:
                    settings = dict(defaults(effect), dayNightSplit=split)
                    tiled = np.stack(
                        list(
                            job.stream_frames(engine, cache, effect, settings, 9, None, 0, "tiled")
                        )
                    )
                    expected = engine.export_batch(
                        cache, effect, settings, 0, 0, cache.width, cache.height, 0, 9, 9
                    )
                    np.testing.assert_array_equal(
                        tiled, expected, err_msg=f"tiled {effect['key']} split={split}"
                    )
                    tiled_checked += len(tiled)
            engine.max_buffer = original_limit
            check_tile_cleanup(engine, cache)
            check_spatial_frames(engine, cache, job, model, defaults)
            print(f"Lite GPU batching: {checked} resident + {tiled_checked} tiled frames exact.")
    finally:
        engine.close()


def check_spatial_frames(engine, cache, job, model, defaults):
    """逐像素核对空间优先路径，覆盖全部效果、映射、取消与临时文件清理。"""
    from media import Cancelled
    from spatial_export import spatial_frames

    original_limit = engine.max_buffer
    engine.max_buffer = 128 * 1024
    checked = 0
    for effect in model.EFFECTS:
        for split in (False, True) if effect["family"] == 0 else (False,):
            settings = dict(defaults(effect), dayNightSplit=split)
            actual = np.stack(
                list(spatial_frames(job, engine, cache, effect, settings, 9, None, 0, "spatial"))
            )
            expected = engine.export_batch(
                cache, effect, settings, 0, 0, cache.width, cache.height, 0, 9, 9
            )
            np.testing.assert_array_equal(actual, expected, err_msg=f"spatial {effect['key']}")
            assert not list(job.cache_root.glob("spatial_*"))
            checked += len(actual)
    effect = model.BY_ID[104]
    settings = dict(
        defaults(effect),
        rotationStartAngle=37.5,
        sourceStart=0.1,
        sourceEnd=0.9,
        sourceReverse=True,
        direction=1,
        customMap=True,
    )
    mapping = np.linspace(0, 1, cache.width * cache.height, dtype=np.float32).reshape(
        cache.height, cache.width
    )
    actual = np.stack(
        list(spatial_frames(job, engine, cache, effect, settings, 9, mapping, 0, "mapping"))
    )
    np.testing.assert_array_equal(
        actual,
        engine.export_batch(
            cache,
            effect,
            settings,
            0,
            0,
            cache.width,
            cache.height,
            0,
            9,
            9,
            mapping,
        ),
    )
    stream = spatial_frames(job, engine, cache, effect, settings, 9, None, 0, "cancel")
    first = next(stream)
    before = first.copy()
    job.cancel.set()
    try:
        next(stream)
    except Cancelled:
        pass
    else:
        raise AssertionError("取消未中断空间缓存输出")
    finally:
        stream.close()
        job.cancel.clear()
    np.testing.assert_array_equal(first, before)
    assert not list(job.cache_root.glob("spatial_*"))
    original_notify = job.notify

    def cancel_on_progress(*_):
        """在首块真正完成后取消，核对生成第一帧之前也能中断并清理。"""
        job.cancel.set()

    job.notify = cancel_on_progress
    stream = spatial_frames(job, engine, cache, effect, settings, 9, None, 0, "early-cancel")
    try:
        next(stream)
    except Cancelled:
        pass
    else:
        raise AssertionError("首帧之前的取消未生效")
    finally:
        stream.close()
        job.notify = original_notify
        job.cancel.clear()
    assert not list(job.cache_root.glob("spatial_*"))
    # 多个时间组、最后不足一组，以及横向/纵向都分块的边界一起核对。
    engine.max_buffer = 8 * 1024
    settings = dict(defaults(effect), dayNightSplit=True)
    actual = np.stack(
        list(spatial_frames(job, engine, cache, effect, settings, 35, None, 0, "slabs"))
    )
    expected = engine.export_batch(
        cache, effect, settings, 0, 0, cache.width, cache.height, 0, 35, 35
    )
    np.testing.assert_array_equal(actual, expected)
    engine.max_buffer = original_limit
    # 长时间轴与4K所用的8帧时间组采用相同分组规则，绕开有损编码核对裸帧。
    count, h, w = 1200, 18, 32
    t, y, x = np.indices((count, h, w))
    long_cache = SimpleNamespace(
        width=w,
        height=h,
        duration=20,
        fps=60,
        folder="long-golden",
        data=np.stack(
            (
                (t * 13 + x * 2) % 256,
                (t // 256 * 47 + y * 4 + t * 11) % 256,
                (t * 9 + x + y) % 256,
                np.full_like(t, 255),
            ),
            -1,
        ).astype(np.uint8),
    )
    for split in (False, True):
        settings = dict(defaults(model.BY_ID[100]), dayNightSplit=split)
        engine.max_buffer = 512 * 1024
        with (
            patch("spatial_export.STAGING_GROUP_BYTES", w * h * 4 * 8),
            patch(
                "spatial_export.SOURCE_PARALLEL_BYTES",
                1,
            ),
        ):
            actual = np.stack(
                list(
                    spatial_frames(
                        job,
                        engine,
                        long_cache,
                        model.BY_ID[100],
                        settings,
                        count,
                        None,
                        0,
                        "long",
                    )
                )
            )
        engine.max_buffer = original_limit
        expected = engine.export_batch(
            long_cache,
            model.BY_ID[100],
            settings,
            0,
            0,
            w,
            h,
            0,
            count,
            count,
        )
        np.testing.assert_array_equal(actual, expected, err_msg=f"1200 frames split={split}")
    print("Long timeline: 2 x 1200 uncompressed frames exact across 8-frame groups.")
    print(f"Spatial order: {checked} frames exact; map, source trim and cancellation passed.")


def check_tile_cleanup(engine, cache):
    """用真实GPU分配验证预上传/渲染中取消，以及显存不足与设备错误的资源回收。"""
    from media import Cancelled
    from source_tiles import source_tiles

    original = engine.buffer
    cancel = threading.Event()
    allocated, destroyed = [], []
    for scenario in ("normal", "memory", "gpu-memory", "device", "cancel", "early-close"):
        allocated.clear()
        destroyed.clear()

        def tracked(data, uniform=False):
            """只拦截第二次分配的故障，先前分配仍由真实GPU创建与释放。"""
            if len(allocated) == 1:
                if scenario == "memory":
                    raise MemoryError("injected allocation failure")
                if scenario == "gpu-memory":
                    raise engine.wgpu.GPUOutOfMemoryError("injected GPU allocation failure")
                if scenario == "device":
                    raise RuntimeError("injected device failure")
            buffer = original(data, uniform)
            destroy = buffer.destroy

            def recorded_destroy():
                """记录真实释放调用，检测重复释放及泄漏。"""
                destroyed.append(id(buffer))
                destroy()

            buffer.destroy = recorded_destroy
            allocated.append(id(buffer))
            if scenario == "cancel":
                cancel.set()
            return buffer

        engine.buffer = tracked
        try:
            with source_tiles(engine, cache, cache.width, 8, cache.data.nbytes, cancel) as buffers:
                if scenario in ("memory", "gpu-memory"):
                    assert not buffers
                elif scenario == "early-close":
                    cancel.set()
                    raise Cancelled("cancel during rendering")
                else:
                    assert buffers
        except Cancelled:
            assert scenario in ("cancel", "early-close")
        except RuntimeError:
            assert scenario == "device"
        else:
            assert scenario not in ("device", "cancel", "early-close")
        finally:
            engine.buffer = original
            cancel.clear()
        assert sorted(allocated) == sorted(destroyed), (scenario, allocated, destroyed)
    print("Source tiles: allocation fallback, cancellation and device failure cleanup passed.")


if __name__ == "__main__":
    main()
