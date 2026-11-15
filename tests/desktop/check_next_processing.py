import json
import sys
import threading
from pathlib import Path

import cv2
import numpy as np

R = Path(__file__).resolve().parents[2]
WORK = R / "build/mac-next/tests"
WORK.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(R / "build/open-source/stage/app"))
from cache_helpers import copy_cache
from media import FrameCache
from source_processing import (
    DEFAULT_OPTIONS,
    banded_smooth,
    grade_frame,
    process_cache,
    registration_plan,
)

# Independently compare the banded solver with a dense second-difference solve.
rng = np.random.default_rng(80)
y = rng.normal(size=31)
sigma = 4.0
penalty = (sigma / 1.4) ** 4
d = np.diff(np.eye(len(y)), 2, axis=0)
gold = np.linalg.solve(np.eye(len(y)) + penalty * d.T @ d, y)
assert np.max(abs(gold - banded_smooth(y, sigma, robust=False))) < 1e-9

w, h, n = 384, 256, 40
texture = rng.integers(25, 160, (h, w, 3), dtype=np.uint8)
texture = cv2.GaussianBlur(texture, (0, 0), 0.7)
for x in range(20, w - 20, 32):
    cv2.rectangle(texture, (x, 45), (x + 18, h - 25), (160, 130, 110), 2)
base = np.empty((h, w, 4), np.uint8)
base[:, :, :3] = texture
base[:, :, 3] = 255
folder = WORK / "source"
folder.mkdir(exist_ok=True)
data = np.memmap(folder / "frames.rgba", mode="w+", dtype=np.uint8, shape=(n, h, w, 4))
matrices = []
ambient = np.linspace(0, -1.1, n)
flicker = 0.13 * np.sin(np.arange(n) * 2.1) + 0.07 * (-1.0) ** np.arange(n)
for i in range(n):
    matrix = cv2.getRotationMatrix2D(((w - 1) / 2, (h - 1) / 2), 0.065 * np.sin(i * 1.7), 1)
    matrix[:, 2] += [1.8 * np.sin(i * 2.3), 1.3 * (np.cos(i * 1.8) - 1)]
    matrices.append(np.vstack((matrix, [0, 0, 1])))
    frame = cv2.warpAffine(
        base, matrix, (w, h), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REFLECT_101
    )
    opts = dict(DEFAULT_OPTIONS, grade=False)
    data[i] = grade_frame(frame, opts, 0, ambient[i] + flicker[i])
data.flush()
data._mmap.close()
meta = dict(width=w, height=h, frames=n, fps=12, duration=n / 12, source="synthetic")
(folder / "cache.json").write_text(json.dumps(meta))
cache = FrameCache(folder, meta)
plan = registration_plan(cache.data, cache.fps, "extreme", threading.Event(), lambda p: None)
poses = np.array([np.vstack((m, [0, 0, 1])) for m in plan.transforms]) @ np.array(matrices)
points = np.array(
    [[w * 0.2, h * 0.2, 1], [w * 0.8, h * 0.2, 1], [w * 0.2, h * 0.8, 1], [w * 0.8, h * 0.8, 1]]
)
locations = (poses @ points.T)[:, :2]
residual = np.linalg.norm(locations - locations[0], axis=1)
p95 = float(np.quantile(residual, 0.95))
print("Known-motion registration P95", p95, flush=True)
assert p95 < 0.55, p95

flicker_results = []
for level in ("light", "standard", "extreme"):
    copied = copy_cache(cache, WORK / ("flicker_" + level))
    report = process_cache(copied, dict(DEFAULT_OPTIONS, deflicker=level), threading.Event())
    assert len(copied.data) == n
    metric = report["deflicker"]
    assert metric["afterJumpP95Ev"] < metric["beforeJumpP95Ev"] * 0.35, metric
    flicker_results.append(metric)
    copied.close()
print("Deflicker levels", flicker_results, flush=True)
identity = grade_frame(base, dict(DEFAULT_OPTIONS, grade=False), 0.5)
assert np.array_equal(identity, base)
warm = grade_frame(base, dict(DEFAULT_OPTIONS, grade=True), 0)
cool = grade_frame(base, dict(DEFAULT_OPTIONS, grade=True), 1)
assert warm[:, :, :3].mean((0, 1))[0] > cool[:, :, :3].mean((0, 1))[0]
assert warm[:, :, :3].mean((0, 1))[2] < cool[:, :, :3].mean((0, 1))[2]

cache.close()
report = dict(registrationP95=p95, deflicker=flicker_results, neutralGradeExact=True)
(WORK / "processing-check.json").write_text(json.dumps(report, indent=2))
print("Source processing and grading passed.", flush=True)
