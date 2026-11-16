"""整理本地GitHub候选源码、发行附件和校验清单，不连接远程仓库。"""

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from audit_publication import inspect
from package_lite_delivery import archive_tree

ROOT = Path(__file__).resolve().parents[1]


def sha256(path):
    """分块计算附件指纹，避免把大型应用压缩包一次读入内存。"""
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024**2), b""):
            value.update(block)
    return value.hexdigest()


def run(command, **options):
    """执行本地步骤，任何检查失败立即停止后续发布准备。"""
    subprocess.run([str(x) for x in command], check=True, **options)


def copy_docs(destination):
    """只更新发行包的文档，保留程序执行文件和已验证的运行逻辑。"""
    target = destination / "docs"
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(ROOT / "docs", target, ignore=shutil.ignore_patterns("media"))
    for name in ("LICENSE", "LICENSE.en.txt", "THIRD_PARTY.md", "NOTICE.md", "CHANGELOG.md"):
        shutil.copy2(ROOT / name, destination / name)


def package_mac(profile, assets, work, version):
    """复制已验证App后刷新文档、重新本地签名，并保留解压后签名校验。"""
    lite = profile == "lite"
    name = "时刃 Lite.app" if lite else "时刃.app"
    source = (
        ROOT / f"dist/Lite-{version}/macOS" / name
        if lite
        else ROOT / f"dist/完整版_{version}_优化/macOS-{version}" / name
    )
    if not source.is_dir():
        raise FileNotFoundError(f"Build the {profile} application first: {source}")
    stage = work / profile
    stage.mkdir()
    app = stage / name
    shutil.copytree(source, app, symlinks=True)
    copy_docs(app / "Contents/Resources")
    readme = ROOT / ("lite/README.md" if lite else "mac-5.0-redesign/README_MAC.md")
    (app / "Contents/Resources/README.md").write_text(
        readme.read_text(encoding="utf-8").replace("../docs/", "docs/"), encoding="utf-8"
    )
    original = source / "Contents/MacOS" / ("时刃 Lite" if lite else "时刃")
    copied = app / "Contents/MacOS" / original.name
    assert sha256(original) == sha256(copied)
    run(["codesign", "--force", "--deep", "--sign", "-", app])
    run(["codesign", "--verify", "--deep", "--strict", app])
    (stage / "Read-me.txt").write_text(
        "TimeSlice by AlphaStar · Free / AGPL-3.0-only\n"
        "Extract the archive and open the application. Apple Silicon / macOS14+.\n"
        "This test build is locally signed and not notarized by Apple.\n"
        "若系统拦截，尝试打开后前往系统设置→隐私与安全性→仍要打开。\n"
        f"Full corresponding project source: TimeSlice-source-{version}.zip in the same Release.\n"
        "Keep source access and all notices available when redistributing.\n",
        encoding="utf-8",
    )
    shutil.copy2(ROOT / "LICENSE", stage / "LICENSE")
    archive = assets / f"TimeSlice-macOS-{'Lite' if lite else 'full'}-{version}-AppleSilicon.zip"
    archive_tree(stage, archive)
    with tempfile.TemporaryDirectory(dir=work, prefix="signature-") as temporary:
        run(["ditto", "-x", "-k", archive, temporary])
        run(["codesign", "--verify", "--deep", "--strict", Path(temporary) / profile / name])
    return dict(
        platform="macOS",
        edition=profile,
        file=archive.name,
        executableSha256=sha256(copied),
        buildExecutableSha256=sha256(original),
        notarized=False,
    )


def package_windows(assets, work, metadata, source=None):
    """整理已实测的Windows代码/运行时，源码单独随Release提供以减小下载。"""
    version = metadata["version"]
    if source is None:
        candidates = [
            p
            for p in (ROOT / "dist").rglob(f"Windows-{version}-x64")
            if (p / "runtime/python.exe").is_file()
        ]
        if len(candidates) != 1:
            raise ValueError("Use --windows-bundle to select one verified Windows directory")
        source = candidates[0]
    source = Path(source)
    if not source.is_dir():
        raise FileNotFoundError(f"Build the Windows preview first: {source}")
    stage = work / "TimeSlice-Windows"
    shutil.copytree(source, stage)
    for name in ("对应源码.zip", "SHA256.json"):
        (stage / name).unlink(missing_ok=True)
    copy_docs(stage)
    (stage / "README.md").write_text(
        "# TimeSlice · Windows preview\n\n"
        "Extract the entire folder, then open 时刃.exe. Windows10 22H2 / 11 x64.\n"
        "完整解压后打开时刃.exe，保留runtime与app文件夹。\n\n"
        f"Source: TimeSlice-source-{version.split('-')[0]}.zip in the same GitHub Release.\n"
        "Author AlphaStar · Free · AGPL-3.0-only.\n",
        encoding="utf-8",
    )
    for relative in ("时刃.exe", "app/native/timefield.dll", "app/ui/Main.qml"):
        assert sha256(source / relative) == sha256(stage / relative)
    manifest = {
        path.relative_to(stage).as_posix(): sha256(path)
        for path in stage.rglob("*")
        if path.is_file()
    }
    (stage / "SHA256.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    archive = assets / f"TimeSlice-Windows-{version.split('-')[0]}-preview-x64.zip"
    archive_tree(stage, archive)
    return dict(
        platform="Windows",
        edition="preview",
        file=archive.name,
        executableSha256=sha256(source / "时刃.exe"),
        nativeDllSha256=sha256(source / "app/native/timefield.dll"),
        qmlSha256=sha256(source / "app/ui/Main.qml"),
        validation="Cross-built on Mac; this version still needs Windows physical validation",
    )


def main():
    """导出源码并暂存Git文件，按需生成本地发行候选，始终不提交或推送远程。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--with-assets", action="store_true")
    parser.add_argument("--windows-bundle", type=Path)
    args = parser.parse_args()
    output = args.destination.resolve()
    if output.exists():
        raise ValueError("Use a new destination to preserve earlier preparation work")
    output.mkdir(parents=True)
    repository, assets, evidence = output / "TimeSlice", output / "发布附件", output / "审计报告"
    assets.mkdir()
    evidence.mkdir()
    run([sys.executable, ROOT / "tools/export_source.py", "--destination", repository])
    report = inspect(repository)
    assert report["passed"], report["issues"]
    (evidence / "源码审计.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    version = json.loads((ROOT / "mac-5.0-redesign/resources/mac-release.json").read_text())[
        "version"
    ]
    archive_tree(repository, assets / f"TimeSlice-source-{version}.zip")
    run(["git", "init", "--initial-branch=main", repository])
    run(["git", "-C", repository, "config", "core.autocrlf", "false"])
    run(["git", "-C", repository, "config", "core.quotepath", "false"])
    run(["git", "-C", repository, "add", "."])
    staged = inspect(repository)
    assert staged["passed"], staged["issues"]
    (evidence / "Git暂存审计.json").write_text(
        json.dumps(staged, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    builds = []
    if args.with_assets:
        with tempfile.TemporaryDirectory(dir=output, prefix="package-") as temporary:
            work = Path(temporary)
            builds += [package_mac(profile, assets, work, version) for profile in ("full", "lite")]
            windows = json.loads(
                (ROOT / "mac-5.0-redesign/resources/windows-release.json").read_text()
            )
            builds.append(package_windows(assets, work, windows, args.windows_bundle))
        android = json.loads((ROOT / "mobile/android-release.json").read_text())
        apk = ROOT / "mobile/dist" / ("时刃_Android_" + android["version"] + ".apk")
        target = assets / f"TimeSlice-Android-{android['version'].split('-')[0]}-preview.apk"
        shutil.copy2(apk, target)
        builds.append(dict(platform="Android", file=target.name, apkSha256=sha256(apk)))
    hashes = {p.name: sha256(p) for p in sorted(assets.iterdir()) if p.is_file()}
    (assets / "SHA256SUMS.txt").write_text(
        "".join(f"{value}  {name}\n" for name, value in hashes.items()), encoding="utf-8"
    )
    (output / "release-manifest.json").write_text(
        json.dumps(
            dict(
                tag="v" + version,
                draft=True,
                prerelease=True,
                published=False,
                repositoryRemote=None,
                builds=builds,
                sha256=hashes,
            ),
            indent=2,
        ),
        encoding="utf-8",
    )
    print(f"GitHub preparation ready: {output}. No commit, remote, push or release created.")


if __name__ == "__main__":
    main()
