"""Build the open-source desktop application using the host platform's toolchain."""

import argparse
import json
import os
import plistlib
import shutil
import subprocess
import sys
from importlib import metadata
from pathlib import Path

from prepare_desktop import DESKTOP, ROOT, prepare, release_path
from prune_lite_bundle import prune


# 执行当前任务的主流程并把结果或失败交给调用方。
def run(args, **options):
    subprocess.run([str(a) for a in args], check=True, **options)


# 编译当前平台的原生渲染内核并验证工具链失败。
def build_native(stage):
    app = stage / "app"
    native = app / "native"
    native.mkdir(exist_ok=True)
    source = ROOT / "app/core/cpu.cpp"
    include = DESKTOP / "core"
    if sys.platform == "darwin":
        sdk = subprocess.check_output(
            ["xcrun", "--sdk", "macosx", "--show-sdk-path"], text=True
        ).strip()
        run(
            [
                "clang++",
                "-isystem",
                Path(sdk) / "usr/include/c++/v1",
                "-std=c++17",
                "-O3",
                "-dynamiclib",
                "-mmacosx-version-min=14.0",
                "-DSHIREN_MAC42=1",
                "-DSHIREN_MAC_NEXT=1",
                "-I",
                include,
                source,
                "-o",
                native / "libtimefield.dylib",
            ]
        )
    elif sys.platform == "win32":
        run(
            [
                "cl",
                "/nologo",
                "/O2",
                "/LD",
                "/std:c++17",
                "/utf-8",
                "/EHsc",
                "/DSHIREN_MAC42=1",
                "/DSHIREN_MAC_NEXT=1",
                "/I" + str(include),
                source,
                "/link",
                "/OUT:" + str(native / "timefield.dll"),
            ],
            cwd=native,
        )
    elif sys.platform.startswith("linux"):
        # Linux 仅用于 CI 数值核对，不代表发布 Linux 桌面安装包。
        run(
            [
                "c++",
                "-O3",
                "-std=c++17",
                "-shared",
                "-fPIC",
                "-DSHIREN_MAC42=1",
                "-DSHIREN_MAC_NEXT=1",
                "-I",
                include,
                source,
                "-o",
                native / "libtimefield.so",
            ]
        )
    else:
        raise RuntimeError("Unsupported native compiler platform.")


# 把应用、依赖、资源与许可打包成可运行发布物。
def package(stage, output_root=None):
    release = json.loads(release_path().read_text(encoding="utf-8"))
    name = "时刃"
    platform_name = "macOS" if sys.platform == "darwin" else "Windows"
    out = Path(output_root or ROOT / "dist") / f"{platform_name}-{release['version']}"
    work = ROOT / "build/open-source/pyinstaller"
    app = stage / "app"
    compact = ROOT / "build/full-101/opencv/build.json"
    compact_cv = (
        json.loads(compact.read_text(encoding="utf-8"))
        if sys.platform == "darwin" and compact.exists()
        else None
    )
    args = [
        sys.executable,
        "-m",
        "PyInstaller",
        "--noconfirm",
        "--windowed",
        "--python-option",
        "X utf8",
        "--name",
        name,
        "--distpath",
        out,
        "--workpath",
        work,
        "--specpath",
        work,
        "--paths",
        app,
        "--add-data",
        f"{app / 'ui'}{os.pathsep}app/ui",
        "--add-data",
        f"{app / 'resources'}{os.pathsep}app/resources",
        "--add-data",
        f"{stage / 'assets'}{os.pathsep}assets",
        "--add-data",
        f"{app / 'core/render.wgsl'}{os.pathsep}app/core",
        "--add-data",
        f"{app / 'core/fields.wgsl'}{os.pathsep}app/core",
        "--collect-all",
        "wgpu",
    ]
    if (app / "bin/ffmpeg").is_file():
        args += [
            "--exclude-module",
            "imageio_ffmpeg",
            "--add-binary",
            f"{app / 'bin/ffmpeg'}{os.pathsep}app/bin",
        ]
    else:
        args += ["--collect-all", "imageio_ffmpeg"]
    args += ["--exclude-module", "wgpu.utils.imgui", "--exclude-module", "rendercanvas"]
    if compact_cv:
        args += [
            "--exclude-module",
            "cv2",
            "--add-data",
            f"{compact_cv['pythonPackage']}{os.pathsep}app/cv2",
            "--add-binary",
            f"{compact_cv['binary']}{os.pathsep}app/cv2/python-3.11",
        ]
    for entry in ("LICENSE", "THIRD_PARTY.md", "release.json"):
        source = stage / entry if entry in ("release.json", "README.md") else ROOT / entry
        args += ["--add-data", f"{source}{os.pathsep}."]
    if sys.platform == "darwin":
        args += [
            "--osx-bundle-identifier",
            release.get("bundleIdentifier", "studio.shiren.opensource"),
            "--icon",
            stage / "时刃.icns",
            "--add-binary",
            f"{app / 'native/libtimefield.dylib'}:app/native",
        ]
    else:
        from PIL import Image

        icon = stage / "app.ico"
        Image.open(stage / "assets/app-icon-glass.png").save(icon, sizes=[(256, 256)])
        args += ["--icon", icon, "--add-binary", f"{app / 'native/timefield.dll'};app/native"]
    for module in (
        "model",
        "render",
        "core.engine",
        "core.reference",
        "timelapse_finish",
        "wave",
        "cv2",
        "PIL.ImageCms",
        "numpy.core.multiarray",
        "numpy.core._multiarray_umath",
        "numpy._core.multiarray",
        "numpy._core._multiarray_umath",
        "PySide6.QtQuickControls2",
        "PySide6.QtSvg",
    ):
        if module == "cv2" and compact_cv:
            continue
        args += ["--hidden-import", module]
    run(
        [*args, app / "main.py"],
        cwd=ROOT,
        env=dict(os.environ, PYINSTALLER_CONFIG_DIR=str(ROOT / "build/pyinstaller-cache")),
    )
    result = out / (name + ".app" if sys.platform == "darwin" else name)
    license_root = (
        result / "Contents/Resources/Licenses" if sys.platform == "darwin" else result / "Licenses"
    )
    for name in (
        "PySide6-Essentials",
        "shiboken6",
        "wgpu",
        "numpy",
        "Pillow",
        "imageio-ffmpeg",
        "rendercanvas",
        "opencv-python-headless",
    ):
        distribution = metadata.distribution(name)
        for item in distribution.files or ():
            parts = str(item).upper()
            if ".DIST-INFO/" in parts and any(
                word in parts for word in ("LICENSE", "COPYING", "NOTICE")
            ):
                target = license_root / name / Path(str(item)).name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(distribution.locate_file(item), target)
    # 单一说明入口随独立安装包附带，避免打包后文档链接失效。
    docs_root = result / "Contents/Resources" if sys.platform == "darwin" else result
    shutil.copytree(ROOT / "docs", docs_root / "docs", dirs_exist_ok=True)
    if sys.platform == "darwin":
        audit = prune(result)
        (ROOT / "build/full-101/qt-prune.json").write_text(
            json.dumps(audit, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        if compact_cv:
            shutil.copy2(ROOT / "LICENSES/OpenCV-4.13.0.txt", license_root / "OpenCV-4.13.0.txt")
            shutil.copy2(
                ROOT / "mac-5.0-redesign/compact-opencv.json", license_root / "OpenCV-source.json"
            )
        ffmpeg_source = ROOT / "build/full-102/ffmpeg-9.0.2"
        if (app / "bin/ffmpeg").is_file():
            ff_license = license_root / "FFmpeg-full"
            ff_license.mkdir(exist_ok=True)
            for name in (
                "LICENSE.md",
                "COPYING.GPLv2",
                "COPYING.GPLv3",
                "COPYING.LGPLv2.1",
                "COPYING.LGPLv3",
            ):
                shutil.copy2(ffmpeg_source / name, ff_license / name)
            shutil.copy2(ROOT / "build/full-102/dav1d-1.5.1/COPYING", ff_license / "dav1d-COPYING")
            shutil.copy2(
                ROOT / "mac-5.0-redesign/full-ffmpeg-source.json", ff_license / "source-lock.json"
            )
        info_file = result / "Contents/Info.plist"
        info = plistlib.loads(info_file.read_bytes())
        info.update(
            CFBundleShortVersionString=release["version"].split("-")[0],
            CFBundleVersion=str(release["build"]),
            LSMinimumSystemVersion="14.0",
            CFBundleDisplayName="时刃 " + release["displayVersion"],
            NSHumanReadableCopyright="Copyright (C) 2026 AlphaStar · " + release["license"],
        )
        info_file.write_bytes(plistlib.dumps(info))
        for entry in ("LICENSE", "README.md", "THIRD_PARTY.md", "release.json"):
            source = stage / entry if entry in ("release.json", "README.md") else ROOT / entry
            shutil.copy2(source, result / "Contents/Resources" / entry)
        run(["codesign", "--force", "--deep", "--sign", "-", result])
        run(["codesign", "--verify", "--deep", "--strict", result])
    else:
        for entry in ("LICENSE", "README.md", "THIRD_PARTY.md", "release.json"):
            source = stage / entry if entry in ("README.md", "release.json") else ROOT / entry
            shutil.copy2(source, result / entry)
    print(result, flush=True)
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run", action="store_true")
    parser.add_argument("--package", action="store_true")
    parser.add_argument("--output-root", type=Path)
    args = parser.parse_args()
    stage = prepare()
    build_native(stage)
    if args.run:
        run([sys.executable, "-X", "utf8", stage / "app/main.py"])
    if args.package:
        package(stage, args.output_root)
