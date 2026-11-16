"""统一各桌面编码器的目标码率，按实际输出像素和帧率推荐画质。"""

import math

MAX_BITRATE_MBPS = 500


def recommended_bitrate(width, height, fps):
    """按像素面积与帧率推荐Mbps，横竖屏相同，兼顾渐变和切片细节。"""
    values = (width, height, fps)
    if any(not math.isfinite(float(v)) or float(v) <= 0 for v in values):
        raise ValueError("输出尺寸和帧率必须为正数")
    pixels = float(width) * float(height) / (1920 * 1080)
    estimate = 20 * pixels**0.8 * (float(fps) / 30) ** 0.75
    return min(MAX_BITRATE_MBPS, max(2, 5 * math.floor(estimate / 5 + 0.5)))


def validate_bitrate(value):
    """0代表推荐码率；手动值必须有限且处于1–500Mbps，不接受布尔值。"""
    if isinstance(value, bool):
        raise ValueError("码率必须为数字")
    number = float(value)
    if not math.isfinite(number) or (number != 0 and not 1 <= number <= MAX_BITRATE_MBPS):
        raise ValueError("码率范围为1–500 Mbps，0代表推荐")
    return number


def target_bitrate(width, height, fps, value=0):
    """解析自动或手动目标，返回编码器使用的每秒比特数。"""
    manual = validate_bitrate(value)
    return round((manual or recommended_bitrate(width, height, fps)) * 1_000_000)


def bitrate_report(width, height, fps, value=0):
    """记录实际采用的目标，VBR实际文件码率可能低于目标，不伪报成实测值。"""
    return dict(
        mode="custom" if validate_bitrate(value) else "recommended",
        targetMbps=target_bitrate(width, height, fps, value) / 1_000_000,
        rateControl="VBR",
        colorSpace="Rec.709",
        colorRange="limited",
        pixelFormat="yuv420p",
    )
