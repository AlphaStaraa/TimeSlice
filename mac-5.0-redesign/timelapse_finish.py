"""Lock a fixed-camera timelapse to its reference and finish the exposure ramp."""

from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass

import cv2
import numpy as np
from media import check

cv2.setNumThreads(1)
LEVELS = np.arange(256, dtype=np.float32) / 255
LINEAR = np.where(LEVELS <= 0.04045, LEVELS / 12.92, ((LEVELS + 0.055) / 1.055) ** 2.4)
LUMA = np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)


# 用中值和高斯平滑去除测量中的短时跳变。
def smooth_track(values, sigma, median_width=5):
    half = median_width // 2
    windows = np.lib.stride_tricks.sliding_window_view(
        np.pad(values, (half, half), mode="edge"), median_width
    )
    median = np.median(windows, axis=-1)
    radius = round(3 * sigma)
    kernel = np.exp(-0.5 * (np.arange(-radius, radius + 1) / sigma) ** 2)
    return np.convolve(np.pad(median, radius, mode="edge"), kernel / kernel.sum(), mode="valid")


# 提取归一化细节，降低光照变化对特征匹配的影响。
def detail_image(frame, size):
    scaled = cv2.resize(frame, size, interpolation=cv2.INTER_AREA)
    gray = cv2.cvtColor(scaled, cv2.COLOR_RGBA2GRAY)
    levels = np.log1p(gray.astype(np.float32) * 0.12)
    detail = levels - cv2.GaussianBlur(levels, (0, 0), 2.1)
    rms = cv2.GaussianBlur(detail * detail, (0, 0), 3.2)
    return detail / np.sqrt(np.maximum(rms, 0.0015))


# 使用仿射矩阵变换跟踪点坐标。
def warp_points(points, transform):
    return points @ transform[:, :2].T + transform[:, 2]


# 根据局部相关峰值估计亚像素位置。
def subpixel(a, b, c):
    curvature = a - 2 * b + c
    return np.clip(0.5 * (a - c) / curvature, -0.5, 0.5) if curvature < -1e-6 else 0.0


class Landmarks:
    # 建立对象所需的状态、资源句柄和默认配置。
    def __init__(self, reference):
        h, w = reference.shape
        self.radius = max(9, min(20, round(w * 0.026)))
        self.search = max(10, round(w * 0.068))
        edge = self.radius + self.search + 2
        mask = np.zeros((h, w), np.uint8)
        mask[edge : h - edge, edge : w - edge] = 255
        points = cv2.goodFeaturesToTrack(
            reference, maxCorners=100, qualityLevel=0.009, minDistance=max(14, w * 0.055), mask=mask
        )
        if points is None or len(points) < 12:
            raise ValueError("画面锁定需要至少 12 个清晰、可跟踪的固定边角。")
        self.points = np.rint(points.reshape(-1, 2)).astype(np.int32)
        r = self.radius
        self.templates = [
            reference[y - r : y + r + 1, x - r : x + r + 1].copy() for x, y in self.points
        ]

    # 在当前画面匹配参考特征并排除低可信点。
    def match(self, image, ids):
        r, s = self.radius, self.search
        valid, positions, scores = [], [], []
        for i in ids:
            x, y = self.points[i]
            patch = image[y - r - s : y + r + s + 1, x - r - s : x + r + s + 1]
            response = cv2.matchTemplate(patch, self.templates[i], cv2.TM_CCOEFF_NORMED)
            _, score, _, (u, v) = cv2.minMaxLoc(response)
            if score < 0.48 or min(u, v) <= 0 or max(u, v) >= 2 * s:
                continue
            dx = subpixel(response[v, u - 1], score, response[v, u + 1])
            dy = subpixel(response[v - 1, u], score, response[v + 1, u])
            valid.append(i)
            positions.append((x + u - s + dx, y + v - s + dy))
            scores.append(score)
        return (
            np.asarray(valid, dtype=int),
            np.asarray(positions, dtype=np.float32).reshape(-1, 2),
            np.asarray(scores),
        )

    # 利用可靠特征估计相似变换与残余误差。
    def estimate(self, image, ids):
        valid, positions, _ = self.match(image, ids)
        if len(valid) < 6:
            return None, np.empty(0, int)
        target = self.points[valid].astype(np.float32)
        affine, inliers = cv2.estimateAffinePartial2D(
            positions,
            target,
            method=cv2.RANSAC,
            ransacReprojThreshold=0.52,
            maxIters=500,
            confidence=0.99,
            refineIters=12,
        )
        if affine is None:
            return None, np.empty(0, int)
        kept = inliers[:, 0].astype(bool)
        if kept.sum() < 6 or min(np.ptp(target[kept], axis=0)) < self.radius * 2:
            return None, np.empty(0, int)
        return affine, valid[kept]


@dataclass
class LockPlan:
    transforms: np.ndarray
    zoom: float
    replacements: dict
    measurements: dict


@dataclass
class Reference:
    frame: int
    landmarks: Landmarks
    fit: np.ndarray
    verify: np.ndarray
    to_first: np.ndarray


# 把二维仿射矩阵补齐为三阶齐次矩阵。
def homogeneous(matrix):
    return np.vstack((matrix, [0.0, 0.0, 1.0]))


# 分段选择稳定参照，兼顾日夜光照变化。
def reference_frames(frames, size, cancel):
    count = len(frames)
    spacing = max(12, min(100, round(count / 7)))
    locations = np.unique(
        np.linspace(0, count - 1, max(2, round(count / spacing) + 1)).round().astype(int)
    )
    references = []
    for i in locations:
        check(cancel)
        image = detail_image(frames[i], size)
        # Use a few overlapping observations to keep moving highlights out of the model.
        try:
            landmarks = Landmarks(image)
        except ValueError:
            if references:
                continue
            raise
        ids = np.arange(len(landmarks.points))
        near = np.unique(
            np.linspace(max(0, i - spacing // 2), min(count - 1, i + spacing // 2), 5)
            .round()
            .astype(int)
        )
        votes = np.zeros(len(ids), dtype=int)
        for j in near:
            _, accepted = landmarks.estimate(detail_image(frames[j], size), ids)
            votes[accepted] += 1
        reliable = ids[votes >= 3]
        if len(reliable) < 12:
            if references:
                continue
            raise ValueError("起始画面缺少可稳定跟踪的固定边角。")
        mapping = np.eye(3)
        if references:
            bridges = []
            previous = [references[0], *references[-2:]] if len(references) > 2 else references
            for ref in previous:
                affine, matched = ref.landmarks.estimate(image, ref.fit)
                if affine is not None:
                    bridges.append((len(matched), ref.to_first @ homogeneous(affine)))
            if not bridges:
                continue
            mapping = max(bridges, key=lambda item: item[0])[1]
        verify = reliable[::4]
        fit = np.setdiff1d(reliable, verify)
        references.append(Reference(int(i), landmarks, fit, verify, mapping))
    return references


# 对短暂跟踪失败的区间进行受控补偿。
def replace_short_gaps(transforms, fps):
    good = np.flatnonzero(np.isfinite(transforms[:, 0, 0]))
    missing = np.flatnonzero(~np.isfinite(transforms[:, 0, 0]))
    gaps = np.split(missing, np.flatnonzero(np.diff(missing) > 1) + 1)
    if len(good) < 0.95 * len(transforms) or max(map(len, gaps)) > max(1, round(0.12 * fps)):
        raise ValueError("有连续画面无法可靠锁定，请检查遮挡、模糊或机位移动。")
    replacements = {}
    for i in missing:
        neighbor = good[np.argmin(abs(good - i))]
        transforms[i] = transforms[neighbor]
        replacements[int(i)] = int(neighbor)
    return replacements


# 求解固定机位到共同参考坐标的完整锁定方案。
def lock_plan(frames, fps=30, cancel=None, progress=lambda *_: None):
    count, height, width, _ = frames.shape
    ratio = min(1.0, 960 / max(width, height))
    size = (round(width * ratio), round(height * ratio))
    references = reference_frames(frames, size, cancel)
    locations = np.array([ref.frame for ref in references])
    transform = np.full((count, 2, 3), np.nan, dtype=np.float64)
    transform[0] = np.eye(2, 3)
    before, after = [], []
    reference_count = 0
    scale = np.array([width / size[0], height / size[1]])

    # 利用可靠特征估计相似变换与残余误差。
    def estimate(i):
        check(cancel)
        image = detail_image(frames[i], size)
        right = min(np.searchsorted(locations, i), len(locations) - 1)
        left = max(0, right - 1)
        if left == right:
            positions = [(right, 1.0)]
        else:
            span = locations[right] - locations[left]
            mix = np.clip((i - locations[left]) / span, 0, 1)
            mix = mix * mix * (3 - 2 * mix)
            positions = [(left, 1 - mix), (right, mix)]
        candidates = []
        for j, weight in positions:
            ref = references[j]
            affine, _ = ref.landmarks.estimate(image, ref.fit)
            if affine is not None:
                candidates.append((weight, (ref.to_first @ homogeneous(affine))[:2], ref))
        if not candidates:
            return None, np.empty((0, 2)), np.empty((0, 2))
        matrix = np.average(
            [m for _, m, _ in candidates], axis=0, weights=[max(0.001, w) for w, _, _ in candidates]
        )
        # Measure residuals on points held out from both fits.
        ref = max(candidates, key=lambda item: item[0])[2]
        ids, points, scores = ref.landmarks.match(image, ref.verify)
        target = warp_points(ref.landmarks.points[ids], ref.to_first[:2])
        residual = warp_points(points, matrix) - target
        good = (scores >= 0.58) & (np.linalg.norm(residual, axis=1) < 1.6)
        return matrix, (points - target)[good] * scale, residual[good] * scale

    with ThreadPoolExecutor(max_workers=5) as pool:
        for i, (matrix, raw, aligned) in enumerate(pool.map(estimate, range(1, count)), 1):
            if matrix is not None:
                transform[i] = matrix
            if len(aligned):
                reference_count += 1
                before.extend(np.linalg.norm(raw, axis=1).tolist())
                after.extend(np.linalg.norm(aligned, axis=1).tolist())
            if i % 24 == 0 or i == count - 1:
                progress(i / (count - 1))
    if not after or reference_count < 0.80 * (count - 1):
        raise ValueError("固定点复核覆盖不足，请换用机位一致、固定边角清晰的素材。")
    replacements = replace_short_gaps(transform, fps)
    proxy_to_full = np.eye(3)
    proxy_to_full[0, 0], proxy_to_full[1, 1] = scale
    proxy_to_full[:2, 2] = (scale - 1) * 0.5
    full = np.concatenate((transform, np.tile([[[0.0, 0.0, 1.0]]], (count, 1, 1))), axis=1)
    full = proxy_to_full @ full @ np.linalg.inv(proxy_to_full)
    zoom = safe_zoom(full, width, height)
    center = (np.array([width, height]) - 1) * 0.5
    crop = np.diag([zoom, zoom, 1.0])
    crop[:2, 2] = center * (1 - zoom)
    full = (crop @ full)[:, :2]
    return LockPlan(
        full,
        zoom,
        replacements,
        dict(
            references=len(references),
            verified_frames=int(reference_count),
            motion_p95_px=float(np.quantile(before, 0.95)),
            residual_p95_px=float(np.quantile(after, 0.95)) * zoom,
            replaced_frames=sorted(i + 1 for i in replacements),
        ),
    )


# 计算统一安全裁切，避免变换后出现画面空边。
def safe_zoom(matrices, width, height):
    # Check every inverse mapping so the same crop works across the entire clip.
    corners = np.array(
        [[0, 0], [width - 1, 0], [0, height - 1], [width - 1, height - 1]], dtype=float
    )
    center = (np.array([width, height]) - 1) * 0.5
    inverses = np.linalg.inv(matrices)

    # 检查变换是否满足尺度、位移与可靠性约束。
    def fits(zoom):
        target = np.column_stack((center + (corners - center) / zoom, np.ones(4)))
        mapped = (inverses @ target.T)[:, :2, :]
        return np.all(mapped >= 4) and np.all(
            mapped <= np.array([width - 5, height - 5])[None, :, None]
        )

    lo, hi = 1.0, 1.12
    if not fits(hi):
        raise ValueError("锁定所需裁切超过 12%，请核对序列是否移动了机位。")
    for _ in range(22):
        mid = (lo + hi) * 0.5
        if fits(mid):
            hi = mid
        else:
            lo = mid
    return hi
