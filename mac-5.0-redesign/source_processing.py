"""Local source finishing before time slicing: fixed-view registration, deflicker and grading."""

import json
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy

import cv2
import numpy as np
from media import check
from timelapse_finish import (
    LINEAR,
    LUMA,
    Landmarks,
    LockPlan,
    detail_image,
    homogeneous,
    lock_plan,
    safe_zoom,
)

DEFAULT_OPTIONS = dict(
    stabilize="off",
    deflicker="off",
    grade=False,
    dayNight="auto",
    look="cinematic",
    startTemperature=24.0,
    startTint=3.0,
    startSaturation=1.08,
    startExposure=0.0,
    startContrast=1.03,
    endTemperature=-24.0,
    endTint=-7.0,
    endSaturation=1.08,
    endExposure=0.0,
    endContrast=1.04,
    hsl=[dict(hue=0.0, saturation=0.0, luminance=0.0) for _ in range(8)],
)
GRADE_KEYS = ("Temperature", "Tint", "Saturation", "Exposure", "Contrast")
RANGES = dict(
    Temperature=(-100.0, 100.0),
    Tint=(-100.0, 100.0),
    Saturation=(0.0, 2.0),
    Exposure=(-2.0, 2.0),
    Contrast=(0.6, 1.5),
)


# 校验并归一化素材处理参数，拒绝无效数值。
def normalized_options(options):
    out = deepcopy(DEFAULT_OPTIONS)
    out.update(options or {})
    for name, allowed in (
        ("stabilize", ("off", "lock", "extreme")),
        ("deflicker", ("off", "light", "standard", "extreme")),
        ("dayNight", ("auto", "day_to_night", "night_to_day")),
        ("look", ("cinematic", "natural", "amber", "custom")),
    ):
        if out[name] not in allowed:
            raise ValueError("无效的素材处理选项")
    out["grade"] = bool(out["grade"])
    for endpoint in ("start", "end"):
        for key in GRADE_KEYS:
            value = float(out[endpoint + key])
            if not np.isfinite(value):
                raise ValueError("调色参数必须是有效数字")
            out[endpoint + key] = float(np.clip(value, *RANGES[key]))
    bands = out.get("hsl", [])
    out["hsl"] = [
        {
            key: float(
                np.clip(
                    float((bands[i] if i < len(bands) else {}).get(key, 0)),
                    -60 if key == "hue" else -100,
                    60 if key == "hue" else 100,
                )
            )
            for key in ("hue", "saturation", "luminance")
        }
        for i in range(8)
    ]
    if not all(np.isfinite(v) for band in out["hsl"] for v in band.values()):
        raise ValueError("调色参数必须是有效数字")
    return out


# 判断是否启用了实际素材处理。
def enabled(options):
    o = normalized_options(options)
    return o["stabilize"] != "off" or o["deflicker"] != "off" or o["grade"]


# 按昼夜方向展开风格预设的首尾参数。
def preset_options(options, look, direction):
    out = normalized_options(options)
    out["look"] = look
    pairs = dict(
        cinematic=((24, 3, 1.08, 0, 1.03), (-24, -7, 1.08, 0, 1.04)),
        natural=((8, 0, 1.02, 0, 1.0), (-8, -2, 1.02, 0, 1.0)),
        amber=((38, 5, 1.12, 0, 1.06), (-30, -10, 1.1, 0, 1.06)),
    )
    if look not in pairs:
        return out
    first, last = pairs[look]
    if direction == "night_to_day":
        first, last = last, first
    for endpoint, values in (("start", first), ("end", last)):
        out.update({endpoint + key: float(value) for key, value in zip(GRADE_KEYS, values)})
    return out


# 把小尺寸画面转换成线性亮度用于分析。
def luminance(frame, size=(96, 64)):
    rgb = cv2.resize(frame[..., :3], size, interpolation=cv2.INTER_AREA)
    return LINEAR[rgb] @ LUMA


# 比较序列首尾亮度，估计昼夜方向和可信度。
def analyze_direction(data):
    n = len(data)
    ids = np.unique(np.linspace(0, n - 1, min(n, 24)).round().astype(int))
    levels = np.array([np.median(luminance(data[i])) for i in ids])
    ev = np.log2(np.maximum(levels, 0.0001))
    k = max(1, len(ev) // 4)
    change = float(np.median(ev[-k:]) - np.median(ev[:k]))
    direction = "night_to_day" if change > 0 else "day_to_night"
    return dict(
        direction=direction,
        confidence=min(1.0, abs(change) / 1.2),
        changeEv=change,
        ambiguous=abs(change) < 0.2,
    )


# 求解稳健带状平滑系统，保留自然曝光趋势。
def banded_smooth(values, sigma, robust=True):
    """以稳健二阶差分平滑变化曲线，使用五对角 LDL 分解求解。"""
    y = np.asarray(values, dtype=np.float64)
    n = len(y)
    if n < 4:
        return y.copy()
    penalty = max(1.0, (sigma / 1.4) ** 4)
    base = np.full(n, 6.0)
    base[:2] = [1, 5]
    base[-2:] = [5, 1]
    one = np.full(n - 1, -4.0) * penalty
    one[[0, -1]] = -2 * penalty
    two = np.full(n - 2, penalty)
    weights = np.ones(n)
    fit = y.copy()
    for _ in range(3 if robust else 1):
        diagonal = weights + penalty * base
        d = np.empty(n)
        a = np.zeros(n)
        b = np.zeros(n)
        d[0] = diagonal[0]
        a[1] = one[0] / d[0]
        d[1] = diagonal[1] - a[1] ** 2 * d[0]
        for i in range(2, n):
            b[i] = two[i - 2] / d[i - 2]
            a[i] = (one[i - 1] - b[i] * d[i - 2] * a[i - 1]) / d[i - 1]
            d[i] = diagonal[i] - a[i] ** 2 * d[i - 1] - b[i] ** 2 * d[i - 2]
        z = weights * y
        z[1] -= a[1] * z[0]
        for i in range(2, n):
            z[i] -= a[i] * z[i - 1] + b[i] * z[i - 2]
        fit = z / d
        for i in range(n - 2, -1, -1):
            fit[i] -= a[i + 1] * fit[i + 1]
            if i + 2 < n:
                fit[i] -= b[i + 2] * fit[i + 2]
        if robust:
            residual = y - fit
            scale = max(0.008, float(np.median(np.abs(residual - np.median(residual)))) * 1.4826)
            weights = np.maximum(0.08, 1 / np.maximum(1, np.abs(residual) / (2.5 * scale)))
    return fit


# 对少量缺失的变换插值，可靠帧不足时明确失败。
def fill_transform_gaps(matrices):
    good = np.flatnonzero(np.isfinite(matrices[:, 0, 0]))
    missing = np.flatnonzero(~np.isfinite(matrices[:, 0, 0]))
    if len(good) < 0.95 * len(matrices):
        raise ValueError("可可靠锁定的画面不足，请检查遮挡或机位变化。")
    for row in range(2):
        for col in range(3):
            matrices[:, row, col] = np.interp(
                np.arange(len(matrices)), good, matrices[good, row, col]
            )
    return missing.tolist()


# 使用 SIFT 特征和 RANSAC 构建备用稳像方案。
def feature_plan(data, fps, cancel, notify):
    """使用 SIFT 特征与稳健相似变换，处理较大的光照或纹理变化。"""
    n, h, w, _ = data.shape
    scale = min(1.0, 1100 / max(w, h))
    size = (round(w * scale), round(h * scale))
    sift = cv2.SIFT_create(nfeatures=2200, contrastThreshold=0.015)
    matcher = cv2.BFMatcher(cv2.NORM_L2)
    transforms = np.full((n, 2, 3), np.nan)
    transforms[0] = np.eye(2, 3)
    refs = []
    residuals = []
    for i in range(n):
        check(cancel)
        detail = detail_image(data[i], size)
        gray = np.clip((detail + 2) * 60, 0, 255).astype(np.uint8)
        points, desc = sift.detectAndCompute(gray, None)
        if desc is None or len(points) < 16:
            continue
        xy = np.array([p.pt for p in points], np.float32)
        pose = None
        best = 0
        if i == 0:
            pose = np.eye(3)
        else:
            candidates = [refs[0], *refs[-3:]] if refs else []
            for refxy, refdesc, refpose in candidates:
                pairs = matcher.knnMatch(desc, refdesc, k=2)
                pairs = [
                    a
                    for pair in pairs
                    if len(pair) == 2
                    for a, b in [pair]
                    if a.distance < 0.72 * b.distance
                ]
                if len(pairs) < 16:
                    continue
                source = np.array([xy[m.queryIdx] for m in pairs])
                target = np.array([refxy[m.trainIdx] for m in pairs])
                # Keep validation points out of the fit.
                valid = np.arange(len(source)) % 4 == 0
                matrix, mask = cv2.estimateAffinePartial2D(
                    source[~valid],
                    target[~valid],
                    method=cv2.RANSAC,
                    ransacReprojThreshold=1.0,
                    maxIters=2500,
                    confidence=0.995,
                    refineIters=20,
                )
                if matrix is None or int(mask.sum()) < 12:
                    continue
                score = int(mask.sum())
                if score > best:
                    pose = refpose @ homogeneous(matrix)
                    best = score
                    delta = source[valid] @ matrix[:, :2].T + matrix[:, 2] - target[valid]
                    residuals.extend(np.linalg.norm(delta, axis=1).tolist())
        if pose is not None:
            transforms[i] = pose[:2]
            if not refs or i % max(8, n // 12) == 0:
                refs.append((xy, desc, pose))
        if i % 12 == 0:
            notify(i / max(1, n - 1))
    missing = fill_transform_gaps(transforms)
    full = np.tile(np.eye(3), (n, 1, 1))
    full[:, :2] = transforms
    proxy = np.diag([size[0] / w, size[1] / h, 1.0])
    proxy[:2, 2] = (np.diag(proxy)[:2] - 1) * 0.5
    full = np.linalg.inv(proxy) @ full @ proxy
    zoom = safe_zoom(full, w, h)
    crop = np.diag([zoom, zoom, 1.0])
    crop[:2, 2] = (np.array([w, h]) - 1) * 0.5 * (1 - zoom)
    return LockPlan(
        (crop @ full)[:, :2],
        zoom,
        {},
        dict(
            algorithm="SIFT + RANSAC similarity",
            references=len(refs),
            interpolatedTransforms=missing,
            residual_p95_px=float(np.quantile(residuals, 0.95) / scale) if residuals else 0.0,
        ),
    )


# 用 ECC 亚像素对齐精修稳像，并以独立点验证改进。
def refine_plan(data, plan, cancel, notify):
    n, h, w, _ = data.shape
    ratio = min(1.0, 1100 / max(w, h))
    size = (round(w * ratio), round(h * ratio))
    scale = np.diag([size[0] / w, size[1] / h, 1.0])
    scale[:2, 2] = (np.diag(scale)[:2] - 1) * 0.5
    inverse = np.linalg.inv(scale)
    ids = np.unique(np.linspace(0, n - 1, min(9, n)).round().astype(int))
    references = {}
    for i in ids:
        matrix = (scale @ homogeneous(plan.transforms[i]) @ inverse)[:2]
        references[int(i)] = cv2.warpAffine(detail_image(data[i], size), matrix, size)
    accepted = 0
    before_errors = []
    after_errors = []
    for i in range(n):
        check(cancel)
        ref = references[int(ids[np.argmin(abs(ids - i))])]
        matrix = (scale @ homogeneous(plan.transforms[i]) @ inverse)[:2]
        image = cv2.warpAffine(detail_image(data[i], size), matrix, size)
        delta = np.abs(ref - image)
        mask = ((delta < np.quantile(delta, 0.72)) & (np.abs(ref) > 0.12)).astype(np.uint8) * 255
        border = min(18, max(4, min(size) // 12))
        mask[:border] = 0
        mask[-border:] = 0
        mask[:, :border] = 0
        mask[:, -border:] = 0
        try:
            verifier = Landmarks(ref)
            held = np.arange(len(verifier.points))[::2]
            matched, locations, _ = verifier.match(image, held)
            if len(matched) < 6:
                continue
            old = float(np.median(np.linalg.norm(locations - verifier.points[matched], axis=1)))
            _, warp = cv2.findTransformECC(
                ref.astype(np.float32),
                image.astype(np.float32),
                np.eye(2, 3, dtype=np.float32),
                cv2.MOTION_EUCLIDEAN,
                (cv2.TERM_CRITERIA_COUNT | cv2.TERM_CRITERIA_EPS, 70, 1e-7),
                mask,
                5,
            )
            correction = cv2.invertAffineTransform(warp)
            if np.linalg.norm(correction[:, 2]) > 2.5:
                continue
            corrected = cv2.warpAffine(image, correction, size)
            kept, positions, _ = verifier.match(corrected, held)
            if len(kept) < 6:
                continue
            new = float(np.median(np.linalg.norm(positions - verifier.points[kept], axis=1)))
            before_errors.append(old / ratio)
            after_errors.append(min(old, new) / ratio)
            if new < old - 0.005:
                plan.transforms[i] = (
                    inverse @ homogeneous(correction) @ scale @ homogeneous(plan.transforms[i])
                )[:2]
                accepted += 1
        except (cv2.error, ValueError):
            pass
        finally:
            if i % 12 == 0:
                notify(i / max(1, n - 1))
    extra = safe_zoom(np.array([homogeneous(m) for m in plan.transforms]), w, h)
    crop = np.diag([extra, extra, 1.0])
    crop[:2, 2] = (np.array([w, h]) - 1) * 0.5 * (1 - extra)
    plan.transforms = (crop @ np.array([homogeneous(m) for m in plan.transforms]))[:, :2]
    plan.zoom *= extra
    plan.measurements.update(
        eccRefinedFrames=accepted,
        eccValidationBeforePx=float(np.median(before_errors)) if before_errors else None,
        eccValidationAfterPx=float(np.median(after_errors)) if after_errors else None,
    )
    return plan


# 组织主跟踪、备用特征和极致精修，保持进度单调。
def registration_plan(data, fps, mode, cancel, notify):
    last = [0.0]

    # 把内部阶段进度映射到对外可显示的范围。
    def progress(value):
        last[0] = max(last[0], float(value))
        notify(last[0])

    first_weight = 0.7 if mode == "extreme" else 1.0
    try:
        plan = lock_plan(data, fps, cancel, lambda p: progress(first_weight * p))
        if plan.replacements:
            missing = np.array(list(plan.replacements))
            plan.transforms[missing] = np.nan
            fill_transform_gaps(plan.transforms)
            plan.measurements["interpolatedTransforms"] = missing.tolist()
            plan.measurements["replaced_frames"] = []
            plan.replacements = {}
        plan.measurements["algorithm"] = "multi-reference normalized landmarks + RANSAC"
    except ValueError:
        plan = feature_plan(data, fps, cancel, lambda p: progress(first_weight * p))
    if mode == "extreme":
        plan = refine_plan(data, plan, cancel, lambda p: progress(0.7 + 0.3 * p))
        plan.measurements["algorithm"] += " + ECC"
    progress(1.0)
    return plan


# 估计去闪曝光与通道修正，保留日夜变化。
def exposure_plan(data, transforms, fps, level, cancel, notify):
    n, h, w, _ = data.shape
    size = (96, 64)
    S = np.diag([96 / w, 64 / h, 1.0])
    S[:2, 2] = (np.diag(S)[:2] - 1) * 0.5
    inv = np.linalg.inv(S)
    tiles = []
    chroma = []
    for i in range(n):
        check(cancel)
        rgb = cv2.resize(data[i, :, :, :3], size, interpolation=cv2.INTER_AREA)
        if transforms is not None:
            rgb = cv2.warpAffine(
                rgb, (S @ homogeneous(transforms[i]) @ inv)[:2], size, flags=cv2.INTER_LINEAR
            )
        linear = LINEAR[rgb]
        y = linear @ LUMA
        grid = []
        for yy in range(0, 64, 8):
            for xx in range(0, 96, 12):
                patch = y[yy : yy + 8, xx : xx + 12]
                good = patch[(patch > 0.006) & (patch < 0.85)]
                grid.append(
                    float(np.median(np.log2(np.maximum(good, 0.0001))))
                    if len(good) > 24
                    else np.nan
                )
        tiles.append(grid)
        valid = (
            (y > 0.025) & (y < 0.65) & (linear.max(-1) < 2.2 * np.maximum(0.001, linear.min(-1)))
        )
        ratios = np.log2((linear[..., [0, 2]] + 0.002) / (linear[..., 1:2] + 0.002))
        chroma.append(np.median(ratios[valid], axis=0) if valid.sum() > 64 else [np.nan, np.nan])
        if i % 24 == 0:
            notify(i / max(1, n - 1))
    tiles = np.asarray(tiles)
    steps = np.nanmedian(np.diff(tiles, axis=0), axis=1)
    steps = np.nan_to_num(steps)
    curve = np.r_[0, np.cumsum(steps)]
    sigma, limit = {
        "light": (max(2.0, fps * 0.10), 0.18),
        "standard": (max(4.0, fps * 0.25), 0.4),
        "extreme": (max(8.0, fps * 0.5), 0.8),
    }[level]
    target = banded_smooth(curve, sigma)
    gain = np.clip(target - curve, -limit, limit)
    chroma_gain = np.zeros((n, 3))
    if level == "extreme":
        channels = np.asarray(chroma)
        for col, channel in enumerate((0, 2)):
            good = np.flatnonzero(np.isfinite(channels[:, col]))
            if len(good) > 4:
                track = np.interp(np.arange(n), good, channels[good, col])
                chroma_gain[:, channel] = np.clip(
                    banded_smooth(track, sigma) - track, -0.055, 0.055
                )
    before = float(np.quantile(np.abs(np.diff(curve)), 0.95))
    after = float(np.quantile(np.abs(np.diff(curve + gain)), 0.95))
    return (
        gain,
        chroma_gain,
        curve,
        dict(
            level=level,
            beforeJumpP95Ev=before,
            afterJumpP95Ev=after,
            maximumCorrectionEv=float(np.max(abs(gain))),
            frameBlending=False,
        ),
    )


# 生成随原片时间平滑单调变化的调色进度。
def color_progress(curve, count):
    time = np.linspace(0, 1, count)
    if (
        len(curve) < 8
        or abs(np.median(curve[-max(2, count // 8) :]) - np.median(curve[: max(2, count // 8)]))
        < 0.2
    ):
        return time * time * (3 - 2 * time)
    trend = banded_smooth(curve, max(4, count * 0.06), robust=False)
    direction = 1 if trend[-1] > trend[0] else -1
    movement = np.maximum(0, direction * np.gradient(trend)) + 0.15 / max(1, count)
    cumulative = np.cumsum(movement)
    cumulative -= cumulative[0]
    cumulative /= max(1e-6, cumulative[-1])
    # A temporal component keeps cloud plateaus from freezing the grade.
    progress = 0.35 * time + 0.65 * cumulative
    return progress * progress * (3 - 2 * progress)


# 把线性颜色转换到 sRGB 显示编码。
def to_srgb(linear):
    value = np.maximum(linear, 0)
    return np.where(value <= 0.0031308, 12.92 * value, 1.055 * value ** (1 / 2.4) - 0.055)


# 为八个连续色带生成色相、饱和度与明度查找表。
def hsl_lut(options):
    centers = np.array([0, 30, 60, 120, 180, 240, 270, 300], np.float32)
    hue = np.arange(1024, dtype=np.float32) * 360 / 1024
    distances = np.abs((hue[:, None] - centers + 180) % 360 - 180)
    weights = np.exp(-0.5 * (distances / 19.0) ** 2)
    weights /= weights.sum(1, keepdims=True)
    values = np.array(
        [[band[k] for k in ("hue", "saturation", "luminance")] for band in options["hsl"]],
        np.float32,
    )
    values[:, 1:] /= 100
    return np.ascontiguousarray(weights @ values, dtype=np.float32)


# 在颜色空间中应用连续色带调整，减弱中性色偏色。
def apply_hsl(rgb, lut):
    hls = cv2.cvtColor(np.ascontiguousarray(rgb, dtype=np.float32), cv2.COLOR_RGB2HLS)
    position = hls[..., 0] * (1024 / 360)
    lo = np.floor(position).astype(np.int32) % 1024
    mix = (position - np.floor(position))[..., None]
    shift = lut[lo] * (1 - mix) + lut[(lo + 1) % 1024] * mix
    # Hue corrections fade near neutral colours instead of tinting grey pixels.
    chroma = np.clip(hls[..., 2] / 0.12, 0, 1)
    hls[..., 0] = (hls[..., 0] + shift[..., 0] * chroma) % 360
    hls[..., 2] = np.clip(hls[..., 2] * (1 + shift[..., 1] * chroma), 0, 1)
    change = shift[..., 2] * chroma
    hls[..., 1] += np.where(change >= 0, (1 - hls[..., 1]) * change, hls[..., 1] * change)
    return np.clip(cv2.cvtColor(hls.astype(np.float32), cv2.COLOR_HLS2RGB), 0, 1)


# 分析代表帧并生成与源时间一致的调色关键帧曲线。
def source_color_curve(data):
    n = len(data)
    ids = np.unique(np.linspace(0, n - 1, min(n, 96)).round().astype(int))
    levels = [np.log2(max(0.0001, float(np.median(luminance(data[i]))))) for i in ids]
    return color_progress(np.interp(np.arange(n), ids, levels), n).astype(np.float32)


# 把首尾调色、时间曲线和 HSL 表打包为实时配置。
def grade_config(options, curve):
    o = normalized_options(options)
    n = len(curve)
    data = np.zeros(16 + n + 3072, np.float32)
    data[0] = o["grade"]
    data[1] = n
    data[2:7] = [o["start" + k] for k in GRADE_KEYS]
    data[7:12] = [o["end" + k] for k in GRADE_KEYS]
    data[12] = any(abs(v) > 1e-6 for band in o["hsl"] for v in band.values())
    data[16 : 16 + n] = curve
    data[16 + n :] = hsl_lut(o).ravel()
    return data


# 在线性空间应用曝光与调色，再转回八位显示像素。
def grade_frame(frame, options, progress, ev=0.0, chroma=None):
    linear = LINEAR[frame[..., :3]].astype(np.float32)
    if options["grade"]:
        values = {
            key: options["start" + key] * (1 - progress) + options["end" + key] * progress
            for key in GRADE_KEYS
        }
        temperature = values["Temperature"]
        tint = values["Tint"]
        gains = np.exp2(
            np.array(
                [
                    temperature * 0.006 + tint * 0.002,
                    -tint * 0.004,
                    -temperature * 0.006 + tint * 0.002,
                ]
            )
        )
        gains /= float(gains @ LUMA)
        linear *= gains.astype(np.float32)
        y = np.maximum(linear @ LUMA, 0.0001)
        linear *= np.power(y / 0.18, values["Contrast"] - 1)[..., None]
        luma = linear @ LUMA
        linear = luma[..., None] + values["Saturation"] * (linear - luma[..., None])
        ev += values["Exposure"]
    gains = np.exp2(ev + (np.zeros(3) if chroma is None else chroma))
    linear *= gains.astype(np.float32)
    # Preserve highlight hue if a gain pushes a channel outside SDR gamut.
    linear /= np.maximum(1.0, linear.max(axis=-1))[..., None]
    out = np.empty_like(frame)
    rgb = np.clip(to_srgb(linear), 0, 1)
    if options["grade"] and any(abs(v) > 1e-6 for band in options["hsl"] for v in band.values()):
        rgb = apply_hsl(rgb, hsl_lut(options))
    out[..., :3] = np.rint(rgb * 255).astype(np.uint8)
    out[..., 3] = 255
    return out


# 先完成分析，再原位应用稳定去闪与可选调色。
def process_cache(cache, options, cancel=None, notify=lambda *_: None):
    o = normalized_options(options)
    data = cache.data
    n, h, w, _ = data.shape
    analysis = analyze_direction(data)
    if o["grade"] and o["dayNight"] == "auto" and analysis["ambiguous"]:
        raise ValueError("日夜变化不明显，请先手动选择日转夜或夜转日。")
    resolved = analysis["direction"] if o["dayNight"] == "auto" else o["dayNight"]
    if o["look"] != "custom":
        o = preset_options(o, o["look"], resolved)
    report = dict(options=o, dayNight=analysis, resolvedDirection=resolved)
    if not enabled(o):
        return report
    plan = None
    if o["stabilize"] != "off":
        if n < 8 or min(w, h) < 96:
            raise ValueError("稳定需要至少 8 帧，画面短边至少 96 像素。")
        notify("固定点锁定", 0)
        plan = registration_plan(
            data, cache.fps, o["stabilize"], cancel, lambda p: notify("固定点锁定", 0.5 * p)
        )
        report["stabilization"] = dict(plan.measurements, zoom=plan.zoom, framesRetained=n)
    correction = np.zeros(n)
    chroma = np.zeros((n, 3))
    if o["deflicker"] != "off":
        correction, chroma, _curve, metrics = exposure_plan(
            data,
            None if plan is None else plan.transforms,
            cache.fps,
            o["deflicker"],
            cancel,
            lambda p: notify("去闪分析", 0.5 + 0.22 * p),
        )
        report["deflicker"] = metrics
    progress = source_color_curve(data)
    report["colorProgress"] = progress.tolist()
    report["colorKeyframes"] = [
        dict(frame=int(i), position=float(progress[i]))
        for i in np.unique(np.linspace(0, n - 1, min(n, 7)).round().astype(int))
    ]
    target = np.memmap(cache.folder / "frames.rgba", mode="r+", dtype=np.uint8, shape=data.shape)

    # 对当前帧应用已经分析完成的变换与修正。
    def apply(i):
        check(cancel)
        frame = data[i]
        if plan is not None:
            frame = cv2.warpAffine(
                frame,
                plan.transforms[i],
                (w, h),
                flags=cv2.INTER_LANCZOS4,
                borderMode=cv2.BORDER_REFLECT_101,
            )
        if o["grade"] or abs(correction[i]) > 1e-7 or np.any(chroma[i]):
            frame = grade_frame(frame, o, float(progress[i]), float(correction[i]), chroma[i])
        target[i] = frame

    try:
        with ThreadPoolExecutor(max_workers=3) as pool:
            for i, _ in enumerate(pool.map(apply, range(n)), 1):
                if i % 12 == 0 or i == n:
                    notify("应用画面处理", 0.72 + 0.28 * i / n)
        target.flush()
    finally:
        target._mmap.close()
    cache.meta["sourceProcessing"] = report
    (cache.folder / "processing.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return report
