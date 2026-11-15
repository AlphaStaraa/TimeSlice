"""将通过真实自检的Mac完整版整理为可转发测试包，保留所有旧交付。"""

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from package_lite_delivery import archive_tree

ROOT = Path(__file__).resolve().parents[1]


def main():
    """核验应用、收纳对应源码与使用说明，再验证解压签名及文件清单。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--checks", type=Path, required=True)
    parser.add_argument("--evidence-dir", type=Path)
    args = parser.parse_args()
    release = json.loads(
        (ROOT / "mac-5.0-redesign/resources/mac-release.json").read_text(encoding="utf-8")
    )
    version = release["version"]
    work = ROOT / "build" / ("full-" + version.replace(".", ""))
    source = work / "delivery/Source"
    checks = args.checks.resolve()
    report = json.loads((checks / "report.json").read_text(encoding="utf-8"))
    for key in (
        "passed",
        "preprocessingCacheReused",
        "realtimeHsl",
        "decodedSessionReused",
        "decodedSessionPixelsUnchanged",
    ):
        assert report[key], key
    assert not report["qmlWarnings"]
    assert not Path(report["decodedSessionFolder"]).exists(), "退出后应清理视频会话缓存"
    app = ROOT / f"dist/完整版_{version}_优化/macOS-{version}/时刃.app"
    output = ROOT / f"dist/时刃_完整版_{version}_测试交付"
    assert not output.exists() and not source.exists(), "新版本必须使用新交付目录"
    output.mkdir()
    folder = output / f"时刃_Mac完整版_{version}_测试包"
    folder.mkdir()
    resources = app / "Contents/Resources"
    shutil.copytree(ROOT / "docs", resources / "docs", dirs_exist_ok=True)
    for name in ("THIRD_PARTY.md", "LICENSE"):
        shutil.copy2(ROOT / name, resources / name)
    shutil.copy2(ROOT / "mac-5.0-redesign/README_MAC.md", resources / "README.md")
    subprocess.run(["codesign", "--force", "--deep", "--sign", "-", str(app)], check=True)
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    shutil.copytree(app, folder / "时刃.app", symlinks=True)
    subprocess.run(
        [sys.executable, "tools/export_source.py", "--destination", str(source)],
        cwd=ROOT,
        check=True,
    )
    archive_tree(source, folder / "对应源码.zip")
    (folder / "先读我.txt").write_text(
        f"""时刃 Mac 完整版 {version} · 测试包
作者 AlphaStar · 完全免费开源 · AGPL-3.0-only
适用：Apple Silicon（M1及以后）、macOS 14及以后。

1. 完整解压，打开“时刃.app”。无需Python、PR或其他运行依赖。
2. 拖入“示例延时.mp4”即可试用。首次导出请在软件里选择保存目录。
3. 保留全部切片、稳定、三级去闪、视频调色/HSL。
4. 同一会话修改切片或调色后，导出可复用原片解码结果；换素材或退出会清理。
5. 4K完整精度仍需要较多工作盘空间，建议本地SSD。临时成片完成或取消即清理。
6. 如macOS提示无法验证开发者，先尝试打开，
   再到“系统设置→隐私与安全性→仍要打开”。本包有本地签名，尚未做Apple公证。
7. 请保留旧版作对照；问题填入“测试反馈.txt”，可附导出目录的渲染记录JSON。

完整对应源码、许可、示例同包提供，转发时保持整个测试包完整。
本软件按原样提供，请备份原片并检查成片。详见优化与验证说明。
""",
        encoding="utf-8",
    )
    (folder / "测试反馈.txt").write_text(
        "电脑芯片/内存：\nmacOS版本：\n素材规格：\n所用效果/参数：\n输出规格：\n"
        "首次/重复导出耗时：\n是否成功：\n问题与复现步骤：\n可附截图和渲染记录。\n",
        encoding="utf-8",
    )
    shutil.copy2(ROOT / "lite/assets/example.mp4", folder / "示例延时.mp4")
    shutil.copy2(ROOT / f"docs/完整版_{version}_验证.md", folder / "优化与验证说明.md")
    for name in ("LICENSE", "LICENSE.en.txt", "THIRD_PARTY.md"):
        shutil.copy2(ROOT / name, folder / name)
    evidence = output / "验证资料"
    evidence.mkdir()
    for original, name in (
        (checks / "report.json", "独立应用自检.json"),
        (work / "golden.json", "92标准帧.json"),
        (work / "performance/report.json", "4K实测.json"),
        (work / "performance-full20/report.json", "完整20秒首次与重复导出.json"),
        (work / "codec-check/report.json", "视频格式检查.json"),
        (work / "reproducible-check.json", "空目录重建视频工具.json"),
        (work / "regression-gpu.log", "GPU回归.log"),
    ):
        if original.is_file():
            shutil.copy2(original, evidence / name)
    if args.evidence_dir:
        for original in args.evidence_dir.iterdir():
            if original.is_file() and not original.is_symlink():
                shutil.copy2(original, evidence / original.name)
    archive = output / f"时刃_Mac完整版_{version}_可转发测试包.zip"
    archive_tree(folder, archive)
    with tempfile.TemporaryDirectory(dir=work, prefix="zip-check-") as temporary:
        subprocess.run(["ditto", "-x", "-k", str(archive), temporary], check=True)
        extracted = Path(temporary) / folder.name / "时刃.app"
        subprocess.run(["codesign", "--verify", "--deep", "--strict", str(extracted)], check=True)
    hashes = {
        path.relative_to(output).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in output.rglob("*")
        if path.is_file() and not path.is_symlink() and not path.is_relative_to(folder / "时刃.app")
    }
    (output / "SHA256.json").write_text(
        json.dumps(hashes, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(archive, archive.stat().st_size / 1024**2, "MiB", flush=True)


if __name__ == "__main__":
    main()
