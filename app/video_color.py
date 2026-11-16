"""输出规格与源色彩描述，RGB10缓存每像素仍占四字节。"""

import math

FORMATS = {
    "h264": dict(codec="h264", bits=8, primaries="bt709", transfer="bt709", matrix="bt709"),
    "hevc10": dict(codec="hevc", bits=10, primaries="bt709", transfer="bt709", matrix="bt709"),
    "hdr_pq": dict(
        codec="hevc", bits=10, primaries="bt2020", transfer="smpte2084", matrix="bt2020"
    ),
    "hdr_hlg": dict(
        codec="hevc", bits=10, primaries="bt2020", transfer="arib-std-b67", matrix="bt2020"
    ),
}
SOURCE10 = 8192
OUTPUT10 = 16384
SOURCE_PQ = 32768
SOURCE_HLG = 65536
OUTPUT_PQ = 131072
OUTPUT_HLG = 262144
SOURCE2020 = 524288
SOURCE_SRGB = 1048576
PAPER_WHITE = 203.0


def output_spec(name="h264"):
    """只接受明确支持的格式，禁止把未知格式静默降为8位。"""
    if name not in FORMATS:
        raise ValueError("不支持的输出格式：" + str(name))
    return FORMATS[name]


def source_color(info):
    """补齐未标注的常规SDR描述，HDR必须有明确的PQ或HLG传递函数。"""
    color = dict(info.get("color", {}))
    color.setdefault("transfer", "bt709")
    color.setdefault("primaries", "bt2020" if info.get("hdr") else "bt709")
    color.setdefault("matrix", "bt2020nc" if info.get("hdr") else "bt709")
    color.setdefault("bits", 8)
    color.setdefault("range", "tv")
    color["hdr"] = color["transfer"] in ("smpte2084", "arib-std-b67")
    peak = float(color.get("peakNits") or (1000 if color["hdr"] else PAPER_WHITE))
    color["peakNits"] = max(PAPER_WHITE, min(10000, peak)) if math.isfinite(peak) else 1000
    return color


def precision_required(info, settings):
    """10位输出或HDR输入必须从解码起保留高精度，不能先走RGBA8缓存。"""
    return (
        output_spec(settings.get("exportFormat", "h264"))["bits"] == 10 or source_color(info)["hdr"]
    )


def input_flags(color):
    """将源色彩编码为共用内核标志，不改变参数中已有几何位。"""
    flags = SOURCE_PQ if color["transfer"] == "smpte2084" else 0
    flags |= SOURCE_HLG if color["transfer"] == "arib-std-b67" else 0
    flags |= SOURCE2020 if color["primaries"] == "bt2020" else 0
    flags |= SOURCE_SRGB if color["transfer"] == "iec61966-2-1" else 0
    return flags


def color_settings(cache, settings):
    """从缓存描述建立渲染配置；普通预览始终输出SDR RGBA8。"""
    meta = getattr(cache, "meta", {})
    pixel_format = meta.get("pixelFormat", settings.get("_sourcePixelFormat", "rgba"))
    color = source_color(dict(color=meta.get("color", settings.get("_sourceColor", {}))))
    mode = settings.get("_exportFormat", "h264")
    spec = output_spec(mode)
    flags = input_flags(color)
    flags |= SOURCE10 if pixel_format == "x2rgb10le" else 0
    if flags and not flags & SOURCE10:
        if color["hdr"]:
            raise ValueError("HDR渲染需要高精度源缓存，请重新准备素材")
    flags |= OUTPUT10 if spec["bits"] == 10 else 0
    flags |= OUTPUT_PQ if mode == "hdr_pq" else 0
    flags |= OUTPUT_HLG if mode == "hdr_hlg" else 0
    return dict(
        settings,
        _sourcePixelFormat=pixel_format,
        _sourceColor=color,
        _colorFlags=flags,
        _sourcePeak=color["peakNits"],
    )


def color_report(mode="h264"):
    """记录真正的目标位深与色彩，不把HDR标签当成位深证明。"""
    spec = output_spec(mode)
    return dict(
        codec=spec["codec"],
        bitDepth=spec["bits"],
        primaries=spec["primaries"],
        transfer=spec["transfer"],
        matrix=spec["matrix"],
        range="limited",
        inputPixelFormat="x2rgb10le" if spec["bits"] == 10 else "rgba",
        pixelFormat="yuv420p10le" if spec["bits"] == 10 else "yuv420p",
    )
