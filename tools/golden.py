"""对 46 款效果的固定输出做发布门禁，更新基准必须显式选择记录模式。"""

import argparse
import hashlib
import importlib
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    """读取已构建内核并比较全部标准帧；任何基准缺失或超差都会失败。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", type=Path, default=ROOT / "build/check/stage/app")
    parser.add_argument("--record", action="store_true")
    parser.add_argument("--accept-new-baseline", action="store_true")
    parser.add_argument("--baseline-label", default="")
    parser.add_argument("--report", type=Path, default=ROOT / "build/golden/report.json")
    args = parser.parse_args()
    if args.record and (not args.accept_new_baseline or not args.baseline_label):
        parser.error("Recording needs --accept-new-baseline and --baseline-label")
    sys.path[:0] = [str(args.stage.resolve()), str(ROOT / "tests")]
    model = importlib.import_module("model")
    try:
        defaults = importlib.import_module("effect_models").mac_defaults
    except ModuleNotFoundError:
        defaults = importlib.import_module("next_controller").mac_defaults
    engine = importlib.import_module("core.engine").CPUEngine()
    cache = importlib.import_module("golden_input").source()
    folder = ROOT / "tests/golden"
    manifest_path = folder / "manifest.json"
    fixture_sha = hashlib.sha256(cache.data.tobytes()).hexdigest()
    manifest = dict(
        format=1,
        baseline=args.baseline_label,
        fixtureSha256=fixture_sha,
        meanTolerance=0.05,
        p99Tolerance=1,
        outlierTolerance=0.001,
        cases=[],
    )
    if not args.record:
        manifest = json.loads(manifest_path.read_text())
        assert manifest["fixtureSha256"] == fixture_sha, "Golden input changed"
    else:
        folder.mkdir(parents=True, exist_ok=True)
    results, failures = [], []
    expected = {entry["name"]: entry for entry in manifest["cases"]}
    try:
        for effect in model.EFFECTS:
            for position in (0.23, 0.79):
                name = f"{effect['id']}-{round(position * 100):02d}.png"
                settings = defaults(effect)
                image = engine.frame(cache, effect, settings, position)
                if args.record:
                    Image.fromarray(image).save(folder / name)
                    manifest["cases"].append(
                        dict(
                            name=name,
                            effect=effect["id"],
                            position=position,
                            settings=settings,
                            sha256=hashlib.sha256((folder / name).read_bytes()).hexdigest(),
                        )
                    )
                    continue
                assert name in expected, f"Missing golden frame: {name}"
                entry = expected[name]
                assert entry["settings"] == settings, f"Defaults changed: {effect['key']}"
                assert hashlib.sha256((folder / name).read_bytes()).hexdigest() == entry["sha256"]
                reference = np.asarray(Image.open(folder / name).convert("RGBA"))
                difference = np.abs(image.astype(np.int16) - reference.astype(np.int16))
                row = dict(
                    effect=effect["key"],
                    position=position,
                    mean=float(difference.mean()),
                    p99=float(np.quantile(difference, 0.99)),
                    maximum=int(difference.max()),
                    outliers=float((difference > 3).mean()),
                )
                passed = (
                    row["mean"] <= manifest["meanTolerance"]
                    and row["p99"] <= manifest["p99Tolerance"]
                    and row["outliers"] <= manifest["outlierTolerance"]
                )
                row["passed"] = bool(passed)
                results.append(row)
                if not passed:
                    failures.append(name)
                    diagnostic = args.report.parent / "differences"
                    diagnostic.mkdir(parents=True, exist_ok=True)
                    Image.fromarray(image).save(diagnostic / name)
        if args.record:
            manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
            print(f"Recorded {len(manifest['cases'])} golden frames: {args.baseline_label}")
        else:
            assert len(expected) == len(results) == 92, "Effect coverage changed"
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(
                json.dumps(
                    dict(
                        baseline=manifest["baseline"],
                        fixtureSha256=fixture_sha,
                        frames=results,
                        failures=failures,
                    ),
                    indent=2,
                )
            )
            if failures:
                raise SystemExit(f"Golden gate failed: {failures}")
            print("Golden gate passed: 46 effects, 92 frames.")
    finally:
        engine.close()


if __name__ == "__main__":
    main()
