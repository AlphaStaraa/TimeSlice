"""整理版本独立的Mac轻量交付，保留符号链接并验证解压后签名。"""

import argparse
import hashlib
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def archive_tree(source, target):
    """用UTF8文件名和Unix权限存档，避免跟随Qt框架符号链接造成重复收纳。"""
    with zipfile.ZipFile(target, "x", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(source.rglob("*")):
            name = path.relative_to(source.parent).as_posix()
            if path.is_symlink():
                entry = zipfile.ZipInfo(name)
                entry.create_system = 3
                entry.external_attr = (stat.S_IFLNK | 0o777) << 16
                archive.writestr(entry, os.readlink(path).encode("utf-8"))
            elif path.is_file():
                archive.write(path, name)
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None
        for entry in archive.infolist():
            if not entry.filename.isascii():
                assert entry.flag_bits & 0x800, entry.filename


def main():
    """仅接受通过真实打包自检的版本，在新目录生成应用、对应源码及校验清单。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence-dir", type=Path)
    args = parser.parse_args()
    release = json.loads((ROOT / "lite/release.json").read_text(encoding="utf-8"))
    version = release["version"].split("-")[0]
    bundle = ROOT / f"dist/Lite-{version}/macOS/时刃 Lite.app"
    checks = ROOT / f"build/lite/packaged-check-{version}"
    report = json.loads((checks / "report.json").read_text(encoding="utf-8"))
    assert report["passed"] and report["requireGpu"] and report["decodedFrames"] == 6
    assert report["engine"].startswith("GPU")
    output = ROOT / f"dist/时刃_Lite_{version}_交付"
    source = ROOT / f"build/lite/delivery-source-{version}"
    assert not output.exists() and not source.exists(), "交付目录必须为新目录，保留旧版本。"
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(bundle)], check=True)
    subprocess.run(
        [sys.executable, "tools/export_source.py", "--destination", str(source)],
        check=True,
        cwd=ROOT,
    )
    output.mkdir()
    app_zip = output / f"TimeSlice-Lite-Mac-{version}.zip"
    archive_tree(bundle, app_zip)
    with tempfile.TemporaryDirectory(dir=ROOT / "build/lite", prefix="zip-check-") as folder:
        subprocess.run(["ditto", "-x", "-k", str(app_zip), folder], check=True)
        subprocess.run(
            ["codesign", "--verify", "--deep", "--strict", str(Path(folder) / bundle.name)],
            check=True,
        )
    archive_tree(source, output / f"TimeSlice-Source-with-Lite-{version}.zip")
    for name in ("LICENSE", "LICENSE.en.txt", "THIRD_PARTY.md"):
        shutil.copy2(ROOT / name, output / name)
    readme = (
        (ROOT / "lite/README.md")
        .read_text(encoding="utf-8")
        .replace(f"../docs/Lite_{version}_验证.md", "验证说明.md")
    )
    (output / "README.md").write_text(readme, encoding="utf-8")
    shutil.copy2(ROOT / f"docs/Lite_{version}_验证.md", output / "验证说明.md")
    shutil.copy2(checks / "packaged-window.png", output / "界面预览.png")
    evidence = output / "验证资料"
    evidence.mkdir()
    performance = ROOT / f"build/lite/performance-{version}.json"
    render_check = ROOT / f"build/lite/render-check-{version}.log"
    for original in (
        checks / "report.json",
        checks / "console.log",
        performance
        if performance.exists()
        else ROOT / "build/lite/profile-4k-controlled/comparison.json",
        render_check if render_check.exists() else ROOT / "build/lite/tile-cache-gpu-check.log",
        ROOT / "build/lite/package-golden.json",
        ROOT / "build/lite/package-benchmark.json",
    ):
        if original.is_file():
            shutil.copy2(original, evidence / original.name)
    if args.evidence_dir:
        for original in args.evidence_dir.iterdir():
            if original.is_file() and not original.is_symlink():
                shutil.copy2(original, evidence / original.name)
    for original, name in (
        (ROOT / "build/lite/real-raw-check/report.json", "真实4K裸帧.json"),
        (ROOT / f"build/lite/4k-encoded-psnr-{version}.txt", "压缩视频PSNR.txt"),
        (ROOT / f"build/lite/4k-encoded-psnr-{version}.log", "压缩视频对照.log"),
    ):
        if original.exists():
            shutil.copy2(original, evidence / name)
    hashes = {
        path.relative_to(output).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(output.rglob("*"))
        if path.is_file()
    }
    (output / "SHA256.json").write_text(
        json.dumps(hashes, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(output)


if __name__ == "__main__":
    main()
