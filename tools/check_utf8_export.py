"""模拟 GBK 默认文本编码，回归中文/表情路径下的真实缓存与导出记录。"""

import argparse
import importlib
import json
import sys
import tempfile
import threading
from pathlib import Path


def main():
    """不改系统区域设置，用实际导出证明文件格式不再依赖默认代码页。"""
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", type=Path, default=root / "build/check/stage/app")
    args = parser.parse_args()
    sys.path.insert(0, str(args.stage.resolve()))
    media = importlib.import_module("media")
    model = importlib.import_module("model")
    defaults = importlib.import_module("effect_models").mac_defaults
    lite = (
        json.loads((args.stage / "resources/release.json").read_text(encoding="utf-8")).get(
            "profile"
        )
        == "lite"
    )
    render = (
        importlib.import_module("lite_render").LiteRenderJob
        if lite
        else importlib.import_module("processed_render").ProcessedRenderJob
    )
    original_open = Path.open

    def gbk_default(path, mode="r", buffering=-1, encoding=None, errors=None, newline=None):
        """只替换未明确指定编码的文本打开方式，二进制和显式UTF8保持原行为。"""
        if "b" not in mode and encoding in (None, "locale"):
            encoding = "gbk"
        return original_open(path, mode, buffering, encoding, errors, newline)

    with tempfile.TemporaryDirectory(prefix="timeslice-utf8-") as temporary:
        work = Path(temporary)
        source = work / "日夜🌙.mp4"
        source.write_bytes((root / "tests/benchmark/source.mp4").read_bytes())
        output, cache = work / "成片🌆", work / "缓存📁"
        output.mkdir()
        cache.mkdir()
        info = media.probe(str(source))
        settings = dict(
            defaults(model.BY_ID[100]),
            duration=0.5,
            fps=12,
            longEdge=160,
            engine="cpu",
            encoder="cpu",
            quality="full",
        )
        try:
            Path.open = gbk_default
            store = importlib.import_module("video_cache").VideoCache(cache) if lite else None
            extra = (
                {"store": store}
                if lite
                else {"source_options": dict(stabilize="off", deflicker="off", grade=False)}
            )
            job = render(
                info,
                [(model.BY_ID[100], settings)],
                output,
                cache,
                threading.Event(),
                lambda *_: None,
                **extra,
            )
            folder = job.run()
        finally:
            Path.open = original_open
        for name in ("渲染记录.json",) if lite else ("渲染记录.json", "素材处理.json"):
            text = (folder / name).read_bytes().decode("utf-8", errors="strict")
            json.loads(text)
            if name == "渲染记录.json":
                assert "日夜🌙.mp4" in text, text
        if store is not None:
            store.close()
        movie = next(folder.glob("*.mp4"))
        media.run([media.ffmpeg(), "-v", "error", "-i", str(movie), "-f", "null", "-"], check=True)
        report = dict(
            defaultEncoding="GBK simulated",
            unicodeSourceAndOutput=True,
            recordsStrictUtf8=True,
            actualExportDecoded=True,
        )
        target = root / "build/windows-physical-20261114/utf8-fix-regression.json"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps(report, ensure_ascii=False))


if __name__ == "__main__":
    main()
