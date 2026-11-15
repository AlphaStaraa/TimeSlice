"""验证正式缓存复用、流式 GPU 两条分支、取消和相同素材的导出耗时。"""

import json
import subprocess
import sys
import threading
import time
from pathlib import Path
from types import SimpleNamespace

import numpy as np

R = Path(__file__).resolve().parents[2]
W = R / "build/mac54/pipeline-tests"
W.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
import next_controller as module
from core.engine import GPUEngine
from mac_controller import MacRenderJob
from media import Cancelled, FrameCache, ffmpeg, probe, run
from model import BY_ID
from next_controller import ProcessedRenderJob, mac_defaults
from prepared_source import reopen, source_key
from source_processing import grade_config, normalized_options, process_cache

source = R / "build/mac-next/demo/Shanghai-proxy.mp4"
info = probe(str(source))
settings = dict(
    mac_defaults(BY_ID[102]),
    longEdge=640,
    quality="full",
    engine="gpu",
    encoder="cpu",
    fps=30,
    duration=2.0,
    reference=False,
)
options = normalized_options(
    dict(stabilize="off", deflicker="standard", grade=True, dayNight="day_to_night")
)
prepared_folder = W / "prepared"
cache = FrameCache.create(info, 640, 0, prepared_folder)
report = process_cache(cache, dict(options, grade=False))
key = source_key(info, settings, options)
cache.meta.update(preparedKey=key, sourceProcessing=report)
(prepared_folder / "cache.json").write_text(json.dumps(cache.meta))
descriptor = dict(key=key, folder=str(prepared_folder))
lease = reopen(descriptor, key)
assert lease is not None
lease.close()
assert reopen(descriptor, "wrong-key") is None
assert source_key(info, settings, dict(options, grade=False)) == key
assert source_key(info, dict(settings, longEdge=320), options) != key
output = W / "outputs"
output.mkdir(exist_ok=True)


# The baseline repeats full source preparation and writes a whole raw output before encoding.
class Baseline(MacRenderJob):
    # 准备可供正式合成读取的素材缓存并报告处理结果。
    def prepare_cache(self, first, workspace, root):
        cache = super().prepare_cache(first, workspace, root)
        process_cache(cache, options, self.cancel)
        return cache


start = time.perf_counter()
old = Baseline(info, [(BY_ID[102], settings)], output, W, threading.Event(), lambda *x: None).run()
before = time.perf_counter() - start
actual = module.process_cache
module.process_cache = lambda *a, **k: (_ for _ in ()).throw(
    AssertionError("Export must reuse source preprocessing")
)
try:
    start = time.perf_counter()
    new = ProcessedRenderJob(
        info,
        [(BY_ID[102], settings)],
        output,
        W,
        threading.Event(),
        lambda *x: None,
        source_options=options,
        prepared=descriptor,
    ).run()
    after = time.perf_counter() - start
finally:
    module.process_cache = actual
entry = json.loads((new / "渲染记录.json").read_text())[0]
assert entry["cacheReused"] and entry["temporaryOutputRGBABytes"] == 0
assert (prepared_folder / "frames.rgba").is_file()
for root in (old, new):
    movie = next(root.glob("*.mp4"))
    run([ffmpeg(), "-v", "error", "-i", str(movie), "-f", "null", "-"], check=True)


# 将导出视频解码为像素，核对有效帧及图像差异。
def decode(folder):
    movie = next(folder.glob("*.mp4"))
    return np.frombuffer(
        subprocess.run(
            [
                ffmpeg(),
                "-v",
                "error",
                "-i",
                str(movie),
                "-pix_fmt",
                "rgba",
                "-f",
                "rawvideo",
                "pipe:1",
            ],
            stdout=subprocess.PIPE,
            check=True,
        ).stdout,
        np.uint8,
    ).reshape(-1, 360, 640, 4)


a = decode(old)
b = decode(new)
difference = abs(a.astype(np.int16) - b.astype(np.int16))
assert difference.mean() < 4, (difference.mean(), difference.max())
# Force tiled batching even on a tiny synthetic source, checking the global time index.
gpu = GPUEngine()
original_limit = gpu.max_buffer
gpu.max_buffer = 256 * 1024
n, h, w = 17, 72, 96
data = np.empty((n, h, w, 4), np.uint8)
for i in range(n):
    data[i] = [i * 14, 100, 200, 255]
small = SimpleNamespace(
    width=w,
    height=h,
    duration=1,
    fps=16,
    data=data,
    folder="batch54",
    live_grade=grade_config(options, np.linspace(0, 1, n)),
)
s = dict(settings, outputWidth=w, outputHeight=h, duration=0.5, fps=12)
job = ProcessedRenderJob(
    info, [(BY_ID[102], s)], output, W, threading.Event(), lambda *x: None, source_options=options
)
frames = np.stack(list(job.stream_frames(gpu, small, BY_ID[102], s, 6, None, 0, "test")))
gpu.max_buffer = original_limit
expected = np.stack([gpu.frame(small, BY_ID[102], s, i / 6) for i in range(6)])
batch_error = int(abs(frames.astype(int) - expected).max())
assert batch_error <= 1, batch_error
gpu.close()
# Cancellation keeps the borrowed source cache and removes partial output files.
stop = threading.Event()


# 记录任务回报或在指定测试阶段触发取消。
def notify(index, status, p, detail):
    if index >= 0 and p > 0.25:
        stop.set()


job = ProcessedRenderJob(
    info,
    [(BY_ID[102], settings)],
    output,
    W,
    stop,
    notify,
    source_options=options,
    prepared=descriptor,
)
try:
    job.run()
    raise AssertionError("Expected cancellation")
except Cancelled:
    pass
assert (prepared_folder / "frames.rgba").is_file() and not list(output.rglob("*.partial.mp4"))
result = dict(
    preparedCacheReused=True,
    preprocessCallsAtExport=0,
    temporaryOutputRGBABytes=0,
    batchMatchesFrame=True,
    batchMaxDifference=batch_error,
    cancelKeepsCache=True,
    baselineSeconds=before,
    streamedReuseSeconds=after,
    speedup=before / after,
    decodedMeanDifference=float(difference.mean()),
    decodedMaxDifference=int(difference.max()),
    source=str(source),
    size=[640, 360],
    outputSeconds=2,
    fps=30,
    encoder="libx264",
    note=(
        "Export timing: new path starts with completed source preprocessing; "
        "preprocessing time is excluded from the new export measurement."
    ),
)
(W / "report.json").write_text(json.dumps(result, indent=2))
print(json.dumps(result), flush=True)
cache.close()
