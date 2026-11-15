"""Compare the same timed render-and-encode job across two builds."""

import argparse
import json
import statistics
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("app", type=Path)
parser.add_argument("report", type=Path)
parser.add_argument("--source", type=Path, default=ROOT / "mobile/tests/source_android.mp4")
parser.add_argument("--edge", type=int, default=640)
parser.add_argument("--quality", choices=("full", "standard"), default="full")
args = parser.parse_args()
sys.path.insert(0, str(args.app.resolve()))
from media import probe
from model import BY_ID, DEFAULTS
from render import RenderJob

info = probe(str(args.source.resolve()))
results = {}
with tempfile.TemporaryDirectory(prefix="shiren-speed-", dir="/private/tmp") as folder:
    directory = Path(folder)
    for engine in ("cpu", "gpu"):
        samples = []
        for _ in range(3):
            settings = dict(
                DEFAULTS,
                engine=engine,
                encoder="cpu",
                longEdge=args.edge,
                duration=2,
                fps=30,
                keepAudio=False,
                shadowEnabled=False,
                quality=args.quality,
            )
            result = RenderJob(
                info, [(BY_ID[2], settings)], directory, directory, None, lambda *_: None
            ).run()
            item = json.loads((result / "渲染记录.json").read_text())[0]
            samples.append(item["seconds"])
            print(engine, item["seconds"], item["engine"], flush=True)
        results[engine] = {"samples": samples, "median": statistics.median(samples)}
args.report.write_text(json.dumps(results, ensure_ascii=False, indent=2))
