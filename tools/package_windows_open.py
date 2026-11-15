"""Cross-package Windows using an existing verified embedded CPython cache."""

import argparse
import hashlib
import json
import os
import shutil
import subprocess
from pathlib import Path

from PIL import Image
from prepare_desktop import DESKTOP, ROOT, prepare, release_path


# 组织此入口的初始化、主流程和退出清理。
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-root", type=Path)
    parser.add_argument("--runtime", type=Path)
    args = parser.parse_args()
    release = json.loads(release_path("win32").read_text(encoding="utf-8"))
    stage = prepare(ROOT / "build/open-source/windows-stage", "win32")
    output = (args.output_root or ROOT / "dist").resolve() / f"Windows-{release['version']}-x64"
    output.mkdir(parents=True, exist_ok=True)
    runtime = output / "runtime"
    if not runtime.exists():
        source_runtime = args.runtime or ROOT / "dist/Windows-1.0.0-x64/runtime"
        shutil.copytree(source_runtime, runtime)
    for name in ("app", "assets"):
        target = output / name
        if target.exists():
            shutil.rmtree(target)
        shutil.copytree(stage / name, target)
    zig = next((ROOT / "build/zig").glob("*/zig"))
    work = ROOT / "build/open-source/windows-native"
    work.mkdir(parents=True, exist_ok=True)
    env = dict(
        os.environ,
        ZIG_GLOBAL_CACHE_DIR=str(ROOT / "build/zig-cache"),
        ZIG_LOCAL_CACHE_DIR=str(work / "zig-cache"),
    )

    # 执行当前任务的主流程并把结果或失败交给调用方。
    def run(args):
        subprocess.run([str(x) for x in args], cwd=work, env=env, check=True)

    native = output / "app/native"
    native.mkdir(exist_ok=True)
    run(
        [
            zig,
            "c++",
            "-target",
            "x86_64-windows-gnu",
            "-O3",
            "-s",
            "-std=c++17",
            "-shared",
            "-DSHIREN_MAC42=1",
            "-DSHIREN_MAC_NEXT=1",
            "-I",
            DESKTOP / "core",
            ROOT / "app/core/cpu.cpp",
            "-o",
            native / "timefield.dll",
        ]
    )
    with Image.open(output / "assets/app-icon-glass.png") as image:
        image.save(work / "app.ico", sizes=[(16, 16), (32, 32), (48, 48), (256, 256)])
    resource = (ROOT / "tools/app.rc").read_text(encoding="utf-8")
    numeric_version = release["version"].split("-")[0]
    resource_version = numeric_version.replace(".", ",") + "," + str(release["build"])
    resource = resource.replace("../assets/app.ico", "app.ico").replace("4,0,0,0", resource_version)
    resource = resource.replace("4.0.0-preview", release["version"]).replace(
        "4.0.0", numeric_version
    )
    (work / "app.rc").write_text(resource, encoding="utf-8")
    shutil.copy2(ROOT / "tools/app.manifest", work / "app.manifest")
    run([zig, "rc", "/fo", work / "app.res", work / "app.rc"])
    run(
        [
            zig,
            "cc",
            "-target",
            "x86_64-windows-gnu",
            "-O2",
            "-s",
            "-municode",
            "-Wl,--subsystem,windows",
            ROOT / "tools/launcher.c",
            work / "app.res",
            "-o",
            output / "时刃.exe",
            "-luser32",
        ]
    )
    (output / "启动诊断.cmd").write_text(
        '@echo off\nchcp 65001 >nul\ncd /d "%~dp0"\n'
        '"runtime\\python.exe" -X utf8 "app\\diagnose.py"\npause\n',
        encoding="utf-8",
    )
    for name in ("LICENSE", "README.md", "THIRD_PARTY.md", "release.json"):
        shutil.copy2(
            stage / name if name in ("README.md", "release.json") else ROOT / name, output / name
        )
    (output / "CPU兼容模式.cmd").write_text(
        '@echo off\r\ncd /d "%~dp0"\r\nset QT_QUICK_BACKEND=software\r\n'
        "set TIMESLICE_FORCE_CPU=1\r\n"
        '"runtime\\pythonw.exe" -X utf8 "app\\main.py"\r\n',
        encoding="utf-8",
    )
    shutil.copytree(ROOT / "docs", output / "docs", dirs_exist_ok=True)
    manifest = {
        str(p.relative_to(output)): hashlib.sha256(p.read_bytes()).hexdigest()
        for p in sorted(output.rglob("*"))
        if p.is_file() and p.name != "SHA256.json"
    }
    (output / "SHA256.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(shutil.make_archive(str(output), "zip", output.parent, output.name), flush=True)


if __name__ == "__main__":
    main()
