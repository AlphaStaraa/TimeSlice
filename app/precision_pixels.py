"""RGB10打包与独立NumPy色彩参考，用于分析代理和数值验证。"""

import numpy as np

TO2020 = np.array(
    [
        [0.627404, 0.329282, 0.0433136],
        [0.069097, 0.919540, 0.0113612],
        [0.0163916, 0.0880132, 0.895595],
    ],
    np.float32,
)
TO709 = np.array(
    [
        [1.660491, -0.587641, -0.072850],
        [-0.124550, 1.132900, -0.008350],
        [-0.018151, -0.100579, 1.118730],
    ],
    np.float32,
)


def unpack_rgb10(frame):
    """解包FFmpeg x2rgb10le，三个颜色通道在进入浮点运算前不降为8位。"""
    packed = np.ascontiguousarray(frame).view("<u4").reshape(frame.shape[:-1])
    return (
        np.stack(((packed >> 20) & 1023, (packed >> 10) & 1023, packed & 1023), -1).astype(
            np.float32
        )
        / 1023
    )


def pack_rgb10(rgb):
    """仅在最终写缓存或成片时量化为10位，透明度置为不透明。"""
    v = np.rint(np.clip(rgb, 0, 1) * 1023).astype("<u4")
    packed = (v[..., 0] << 20) | (v[..., 1] << 10) | v[..., 2] | np.uint32(3 << 30)
    return np.ascontiguousarray(packed).view(np.uint8).reshape((*packed.shape, 4))


def pq_decode(value):
    """ST2084 EOTF，以绝对cd/m²返回亮度。"""
    p = np.maximum(value, 0) ** (32 / 2523)
    return 10000 * (
        np.maximum(p - 3424 / 4096, 0) / np.maximum(2413 / 128 - 2392 / 128 * p, 1e-9)
    ) ** (16384 / 2610)


def pq_encode(nits):
    """ST2084反EOTF，输入为绝对cd/m²而非任意SDR代码值。"""
    p = (np.maximum(nits, 0) / 10000) ** (2610 / 16384)
    return ((3424 / 4096 + 2413 / 128 * p) / (1 + 2392 / 128 * p)) ** (2523 / 32)


def to_linear(rgb, color):
    """将PQ/HLG/SDR代码值还原为相对203nit参考白的线性RGB。"""
    trc = color.get("transfer", "bt709")
    if trc == "smpte2084":
        return pq_decode(rgb) / 203
    if trc == "arib-std-b67":
        a, b, c = 0.17883277, 0.28466892, 0.55991073
        scene = np.where(rgb <= 0.5, rgb * rgb / 3, (np.exp((rgb - c) / a) + b) / 12)
        y = scene @ np.array([0.2627, 0.6780, 0.0593], np.float32)
        return scene * np.maximum(y, 1e-12)[..., None] ** 0.2 * (1000 / 203)
    if trc == "iec61966-2-1":
        return np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    return np.where(rgb <= 0.081, rgb / 4.5, ((rgb + 0.099) / 1.099) ** (1 / 0.45))


def from_linear(rgb, transfer="bt709"):
    """把参考白归一的线性RGB写成正确的目标传递函数。"""
    rgb = np.maximum(rgb, 0)
    if transfer == "smpte2084":
        return pq_encode(rgb * 203)
    if transfer == "arib-std-b67":
        display = rgb * (203 / 1000)
        y = np.maximum(display @ np.array([0.2627, 0.6780, 0.0593], np.float32), 1e-12)
        scene = display * y[..., None] ** (-1 / 6)
        a, b, c = 0.17883277, 0.28466892, 0.55991073
        return np.where(
            scene <= 1 / 12, np.sqrt(3 * scene), a * np.log(np.maximum(12 * scene - b, 1e-12)) + c
        )
    if transfer == "iec61966-2-1":
        return np.where(rgb <= 0.0031308, rgb * 12.92, 1.055 * rgb ** (1 / 2.4) - 0.055)
    return np.where(rgb < 0.018, rgb * 4.5, 1.099 * rgb**0.45 - 0.099)


def mobius(value, peak, transition=0.3):
    """保持低亮度的Mobius高光压缩；峰值不超过目标时保持原值。"""
    if peak <= 1.00001:
        return value
    j = transition
    a = -j * j * (peak - 1) / (j * j - 2 * j + peak)
    b = (j * j - 2 * j * peak + peak) / (peak - 1)
    mapped = (b + j) ** 2 / (b - a) * (value + a) / np.maximum(value + b, 1e-9)
    return np.where(value <= j, value, mapped)


def preview_rgb8(frame, color):
    """生成仅用于分析/显示的SDR代理，正式源缓存仍保持RGB10。"""
    rgb = unpack_rgb10(frame)
    hdr = color.get("transfer") in ("smpte2084", "arib-std-b67")
    wide = color.get("primaries") == "bt2020"
    if hdr or wide or color.get("transfer") == "iec61966-2-1":
        linear = to_linear(rgb, color)
        if wide:
            linear = linear @ TO709.T
        if hdr:
            peak = color.get("peakNits", 1000) / 203
            level = np.maximum(linear.max(-1), 1e-9)
            linear *= (mobius(level, peak) / level)[..., None]
        rgb = from_linear(np.maximum(linear, 0))
    out = np.empty((*frame.shape[:-1], 4), np.uint8)
    out[..., :3] = np.rint(np.clip(rgb, 0, 1) * 255).astype(np.uint8)
    out[..., 3] = 255
    return out
