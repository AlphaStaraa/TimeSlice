"""组装独立轻量版，只收纳视频切片依赖，完整版本继续使用原入口。"""

import argparse
import json
import os
import plistlib
import shutil
import subprocess
import sys
from importlib import metadata
from pathlib import Path

from build_desktop import build_native
from prune_lite_bundle import prune

ROOT = Path(__file__).resolve().parents[1]
LITE = ROOT / "lite"
DESKTOP = ROOT / "mac-5.0-redesign"
SHARED = (
    "effect_models.py",
    "i18n.py",
    "progress_estimator.py",
    "preview_render.py",
    "rounded_preview.py",
    "export_pipeline.py",
    "spatial_export.py",
)


def prepare(destination=None):
    """显式选择视频切片共享模块，保持轻量版依赖边界。"""
    stage = Path(destination or ROOT / "build/lite/stage").resolve()
    if stage.exists():
        shutil.rmtree(stage)
    app = stage / "app"
    app.mkdir(parents=True)
    release = json.loads((LITE / "release.json").read_text(encoding="utf-8"))
    for name in (
        "controller.py",
        "controller_media.py",
        "controller_preview.py",
        "controller_state.py",
        "model.py",
        "media.py",
        "export_quality.py",
        "video_color.py",
        "precision_pixels.py",
        "hevc_stream.py",
        "render.py",
        "windows_bootstrap.py",
        "source_video_cache.py",
    ):
        shutil.copy2(ROOT / "app" / name, app / name)
    (app / "core").mkdir()
    for name in ("__init__.py", "engine.py", "reference.py"):
        source = ROOT / "app/core" / name
        if source.exists():
            shutil.copy2(source, app / "core" / name)
    for name in ("render.wgsl", "fields.wgsl"):
        shutil.copy2(DESKTOP / "core" / name, app / "core" / name)
    for name in SHARED:
        shutil.copy2(DESKTOP / name, app / name)
    for source in LITE.glob("*.py"):
        shutil.copy2(source, app / source.name)
    shutil.copytree(LITE / "ui", app / "ui")
    shutil.copytree(ROOT / "app/resources", app / "resources")
    for name in ("mac42.json", "en.json", "LICENSE.en.txt", "许可与免责声明.txt"):
        shutil.copy2(DESKTOP / "resources" / name, app / "resources" / name)
    if (LITE / "resources/lite-en.json").exists():
        shutil.copy2(LITE / "resources/lite-en.json", app / "resources/lite-en.json")
    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    notice = (
        f"时刃 Lite · {release['displayVersion']}\n作者 AlphaStar\n"
        "完全免费开源 · AGPL-3.0-only\n\n"
        "软件按原样提供，使用前请备份素材并自行检查成片；作者不对使用后果承担担保。\n"
        "第三方组件保留各自许可。\n\n"
    )
    (app / "resources/许可与免责声明.txt").write_text(notice + license_text, encoding="utf-8")
    (app / "resources/LICENSE.en.txt").write_text(
        "TimeSlice Lite · Free and open source\nAuthor: AlphaStar\n"
        "AGPL-3.0-only · Provided as is, without warranty.\n\n" + license_text,
        encoding="utf-8",
    )
    if sys.platform == "win32":
        release["bundleIdentifier"] = "studio.timeslice.lite.windows"
    for path in (stage / "release.json", app / "resources/release.json"):
        path.write_text(json.dumps(release, ensure_ascii=False, indent=2), encoding="utf-8")
    assets = stage / "assets"
    (assets / "thumbnails").mkdir(parents=True)
    effects = json.loads((ROOT / "app/resources/effects.json").read_text(encoding="utf-8"))
    effects = [e for e in effects if e["id"] not in (405, 406)]
    effects += json.loads((DESKTOP / "resources/mac42.json").read_text(encoding="utf-8"))
    for effect in effects:
        for suffix in (".jpg", ".gif"):
            relative = Path("assets/thumbnails") / (effect["key"] + suffix)
            source = DESKTOP / relative
            if not source.exists():
                source = ROOT / relative
            shutil.copy2(source, stage / relative)
    for name in ("app-icon-glass.svg",):
        shutil.copy2(DESKTOP / "assets" / name, assets / name)
    example = LITE / "assets/example.mp4"
    if example.exists():
        shutil.copy2(example, assets / "example.mp4")
    subprocess.run(
        [
            sys.executable,
            str(DESKTOP / "make_icon.py"),
            str(assets / "app-icon-glass.svg"),
            str(assets / "app-icon-glass.png"),
            str(stage / "时刃.icns"),
        ],
        check=True,
        env=dict(os.environ, QT_QPA_PLATFORM="offscreen"),
    )
    compact = ROOT / "build/lite/ffmpeg/bin/ffmpeg"
    if sys.platform == "darwin" and compact.is_file():
        (app / "bin").mkdir(exist_ok=True)
        shutil.copy2(compact, app / "bin/ffmpeg")
        license_dir = stage / "FFmpeg-Licenses"
        license_dir.mkdir()
        for name in (
            "LICENSE.md",
            "COPYING.GPLv2",
            "COPYING.GPLv3",
            "COPYING.LGPLv2.1",
            "COPYING.LGPLv3",
        ):
            source = ROOT / "build/lite/dependencies/ffmpeg-9.0.2" / name
            if source.exists():
                shutil.copy2(source, license_dir / name)
        shutil.copy2(
            ROOT / "build/lite/dependencies/x264-stable/COPYING", license_dir / "x264-COPYING"
        )
        shutil.copy2(ROOT / "build/lite/ffmpeg/build.json", license_dir / "build.json")
    for name in ("LICENSE", "THIRD_PARTY.md"):
        shutil.copy2(ROOT / name, stage / name)
    print(stage, flush=True)
    return stage


def package(stage):
    """打包必需 Qt、视频和 GPU 依赖，显式排除重型图像/RAW 处理包。"""
    release = json.loads((stage / "release.json").read_text(encoding="utf-8"))
    name = "时刃 Lite"
    platform_name = "macOS" if sys.platform == "darwin" else "Windows"
    version = release["version"].split("-")[0]
    output = ROOT / f"dist/Lite-{version}" / platform_name
    work = ROOT / "build/lite/pyinstaller"
    app = stage / "app"
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
        str(output),
        "--workpath",
        str(work),
        "--specpath",
        str(work),
        "--paths",
        str(app),
    ]
    for source, target in (
        (app / "ui", "app/ui"),
        (app / "resources", "app/resources"),
        (stage / "assets", "assets"),
        (app / "core/render.wgsl", "app/core"),
        (app / "core/fields.wgsl", "app/core"),
        (stage / "release.json", "."),
    ):
        args += ["--add-data", f"{source}{os.pathsep}{target}"]
    for module in (
        "cv2",
        "rawpy",
        "exifread",
        "scipy",
        "matplotlib",
        "PySide6.QtWebEngineCore",
        "PySide6.QtWebEngineQuick",
        "PySide6.QtQuick3D",
        "PySide6.Qt3DCore",
        "wgpu.utils.imgui",
        "photo_job",
        "source_processing",
        "timelapse_finish",
    ):
        args += ["--exclude-module", module]
    args += ["--collect-all", "wgpu"]
    if (app / "bin/ffmpeg").is_file():
        args += [
            "--exclude-module",
            "imageio_ffmpeg",
            "--add-binary",
            f"{app / 'bin/ffmpeg'}{os.pathsep}app/bin",
        ]
    else:
        args += ["--collect-all", "imageio_ffmpeg"]
    for module in ("PySide6.QtQuickControls2", "PySide6.QtSvg"):
        args += ["--hidden-import", module]
    if sys.platform == "darwin":
        args += [
            "--osx-bundle-identifier",
            release["bundleIdentifier"],
            "--icon",
            str(stage / "时刃.icns"),
            "--add-binary",
            f"{app / 'native/libtimefield.dylib'}:app/native",
        ]
    else:
        from PIL import Image

        icon = stage / "app.ico"
        Image.open(stage / "assets/app-icon-glass.png").save(icon, sizes=[(256, 256)])
        args += ["--icon", str(icon), "--add-binary", f"{app / 'native/timefield.dll'};app/native"]
    subprocess.run(
        args + [str(app / "main.py")],
        check=True,
        cwd=ROOT,
        env=dict(os.environ, PYINSTALLER_CONFIG_DIR=str(ROOT / "build/pyinstaller-cache")),
    )
    bundle = output / (name + ".app" if sys.platform == "darwin" else name)
    resources = bundle / "Contents/Resources" if sys.platform == "darwin" else bundle
    for name in ("LICENSE", "THIRD_PARTY.md", "release.json"):
        shutil.copy2(stage / name, resources / name)
    for name in ("PySide6-Essentials", "shiboken6", "wgpu", "numpy", "Pillow", "imageio-ffmpeg"):
        distribution = metadata.distribution(name)
        for item in distribution.files or ():
            text = str(item).upper()
            if ".DIST-INFO/" in text and any(
                word in text for word in ("LICENSE", "COPYING", "NOTICE")
            ):
                target = resources / "Licenses" / name / Path(str(item)).name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(distribution.locate_file(item), target)
    if (stage / "FFmpeg-Licenses").is_dir():
        shutil.copytree(
            stage / "FFmpeg-Licenses", resources / "Licenses/FFmpeg", dirs_exist_ok=True
        )
    if sys.platform == "darwin":
        audit = prune(bundle)
        (ROOT / "build/lite/prune-report.json").write_text(
            json.dumps(audit, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        path = bundle / "Contents/Info.plist"
        info = plistlib.loads(path.read_bytes())
        info.update(
            CFBundleShortVersionString=version,
            CFBundleVersion=str(release["build"]),
            CFBundleDisplayName="时刃 Lite",
            LSMinimumSystemVersion="14.0",
        )
        path.write_bytes(plistlib.dumps(info))
        subprocess.run(["codesign", "--force", "--deep", "--sign", "-", str(bundle)], check=True)
        subprocess.run(["codesign", "--verify", "--deep", "--strict", str(bundle)], check=True)
    print(bundle, flush=True)
    return bundle


def main():
    """用同一入口完成开发运行、原生构建和独立打包。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--package", action="store_true")
    parser.add_argument("--run", action="store_true")
    args = parser.parse_args()
    stage = prepare()
    build_native(stage)
    if args.package:
        # 默认出包先经过功能、标准帧、Unicode路径和性能检查。
        for command in (
            [
                sys.executable,
                "tools/golden.py",
                "--stage",
                str(stage / "app"),
                "--report",
                "build/lite/package-golden.json",
            ],
            [sys.executable, "tools/check_utf8_export.py", "--stage", str(stage / "app")],
            [sys.executable, "tools/check_lite.py"],
            [
                sys.executable,
                "tools/benchmark.py",
                "--baseline",
                "build/lite/performance-baseline.json",
                "--output",
                "build/lite/package-benchmark.json",
                "--repeats",
                "3",
            ],
        ):
            subprocess.run(command, check=True, cwd=ROOT)
        package(stage)
        result = json.loads(
            (ROOT / "build/lite/package-benchmark.json").read_text(encoding="utf-8")
        )
        if result["comparison"] in ("no-baseline", "comparable") and not result["regressions"]:
            shutil.copy2(
                ROOT / "build/lite/package-benchmark.json",
                ROOT / "build/lite/performance-baseline.json",
            )
    if args.run:
        subprocess.run([sys.executable, "-X", "utf8", str(stage / "app/main.py")], check=True)


if __name__ == "__main__":
    main()
