"""在同一真实4K源与参数下记录轻量导出的阶段耗时。"""

import argparse
import hashlib
import importlib
import json
import platform
import statistics
import subprocess
import sys
import threading
import time
from pathlib import Path

from benchmark import peak_memory


def compare(args):
    """交替先后顺序，用独立进程各测冷/热缓存，避免把历史单次结果当稳定提升。"""
    runs = []
    for repeat in range(args.repeats):
        modes = ("baseline", "cached") if repeat % 2 == 0 else ("cached", "baseline")
        for mode in modes:
            output = args.output / f"trial-{repeat}-{mode}"
            subprocess.run(
                [
                    sys.executable,
                    str(Path(__file__).resolve()),
                    "--mode",
                    mode,
                    "--source",
                    str(args.source),
                    "--stage",
                    str(args.stage),
                    "--duration",
                    str(args.duration),
                    "--output",
                    str(output),
                ],
                check=True,
            )
            for row in json.loads((output / "summary.json").read_text(encoding="utf-8")):
                runs.append(dict(repeat=repeat, mode=mode, **row))
        (args.output / "comparison.json").write_text(
            json.dumps(dict(runs=runs), ensure_ascii=False, indent=2), encoding="utf-8"
        )
    medians = {}
    for mode in ("baseline", "cached"):
        medians[mode] = {
            label: statistics.median(
                row["profile"]["total"]
                for row in runs
                if row["mode"] == mode and row["cacheReused"] == reused
            )
            for label, reused in (("coldSeconds", False), ("warmSeconds", True))
        }
        medians[mode]["parentPeakMiB"] = statistics.median(
            row["parentPeakMiB"] for row in runs if row["mode"] == mode and row["cacheReused"]
        )
    result = dict(
        sourceSha256=hashlib.sha256(args.source.read_bytes()).hexdigest(),
        system=platform.platform(),
        repeats=args.repeats,
        output=(
            f"3 effects x {args.duration}s, 3840x2160, 60fps, "
            "60 slices, full sampling, auto encoder"
        ),
        timing="job total includes source preparation and encoding; excludes later full decode",
        memory="parent process only, includes mapped source pages; excludes ffmpeg subprocess",
        medians=medians,
        runs=runs,
    )
    (args.output / "comparison.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(json.dumps(medians), flush=True)


def main():
    """强制真实GPU及4K60输出，冷/复用缓存分开记，不降低输出规格。"""
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--passes", type=int, default=2)
    parser.add_argument("--stage", type=Path, default=root / "build/lite/stage/app")
    parser.add_argument("--duration", type=float, default=1.0)
    parser.add_argument("--effects", type=int, nargs="+", default=[100, 104, 300])
    parser.add_argument("--mode", choices=("baseline", "cached", "compare"), default="cached")
    parser.add_argument("--repeats", type=int, default=3)
    parser.add_argument(
        "--source",
        type=Path,
        required=True,
        help="Path to your timelapse video; private media is not distributed.",
    )
    args = parser.parse_args()
    args.source, args.output = args.source.resolve(), args.output.resolve()
    if not 1 <= args.repeats <= 9 or not 1 <= args.passes <= 2 or not 0 < args.duration <= 60:
        parser.error("repeats must be 1–9, passes 1–2, duration 0–60s")
    if args.mode == "compare" and (args.passes != 2 or args.effects != [100, 104, 300]):
        parser.error("comparison requires cold/warm passes and the standard three effects")
    args.output.mkdir(parents=True, exist_ok=True)
    if args.mode == "compare":
        return compare(args)
    sys.path.insert(0, str(args.stage.resolve()))
    media = importlib.import_module("media")
    model = importlib.import_module("model")
    defaults = importlib.import_module("effect_models").mac_defaults
    render_module = importlib.import_module("lite_render")
    render = render_module.LiteRenderJob
    if args.mode == "baseline":
        # 以1.0.1的短源驻留/长源流式策略为对照，仅关闭新增空间优先路径。
        render_module.use_spatial_cache = lambda *_args, **_kwargs: False
    store_type = importlib.import_module("video_cache").VideoCache
    source = args.source
    info = media.probe(str(source))
    work = args.output.resolve()
    work.mkdir(parents=True, exist_ok=True)
    (work / "cache").mkdir(exist_ok=True)
    store = store_type(work / "cache")
    runs = []
    try:
        for index in range(args.passes):
            jobs = [
                (
                    model.BY_ID[eid],
                    dict(
                        defaults(model.BY_ID[eid]),
                        duration=args.duration,
                        fps=60,
                        longEdge=3840,
                        quality="full",
                        engine="gpu",
                        encoder="auto",
                        sliceMode=1,
                        sliceCount=60,
                    ),
                )
                for eid in args.effects
            ]
            last_stage = [""]

            def progress(job, stage, fraction, detail):
                """每阶段只输出一次，保留可读进度而不刷屏。"""
                label = str(job) + ":" + stage
                if label != last_stage[0]:
                    print(index, label, flush=True)
                    last_stage[0] = label

            job = render(
                info,
                jobs,
                work,
                work / "cache",
                threading.Event(),
                progress,
                store=store,
                order=args.effects,
                profiling=True,
            )
            started = time.perf_counter()
            folder = job.run()
            record = json.loads((folder / "渲染记录.json").read_text(encoding="utf-8"))
            videos = []
            for path in sorted(folder.glob("*.mp4")):
                metadata = media.probe(str(path))
                decoded = media.run(
                    [
                        media.ffmpeg(),
                        "-v",
                        "error",
                        "-threads",
                        "2",
                        "-i",
                        str(path),
                        "-map",
                        "0:v:0",
                        "-f",
                        "framemd5",
                        "-",
                    ],
                    capture_output=True,
                    text=True,
                    check=True,
                )
                frames = sum(
                    bool(line) and not line.startswith("#") for line in decoded.stdout.splitlines()
                )
                assert metadata["width"] == 3840 and metadata["height"] == 2160
                assert frames == round(args.duration * 60), (frames, args.duration)
                videos.append(dict(path=str(path), frames=frames))
            row = dict(
                passIndex=index,
                cacheReused=job.cache_reused,
                wall=time.perf_counter() - started,
                profile=dict(job.timings),
                parentPeakMiB=peak_memory(),
                records=record,
                videos=videos,
            )
            runs.append(row)
            (work / "summary.json").write_text(
                json.dumps(runs, ensure_ascii=False, indent=2), encoding="utf-8"
            )
            print(json.dumps(dict(passIndex=index, profile=dict(job.timings))), flush=True)
    finally:
        store.close()


if __name__ == "__main__":
    main()
