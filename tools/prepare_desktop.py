"""Assemble the current desktop UI with the complete, editable rendering core."""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DESKTOP = ROOT / "mac-5.0-redesign"


# 选择当前平台应使用的版本元数据文件。
def release_path(target=None):
    target = target or sys.platform
    name = "windows-release.json" if target == "win32" else "mac-release.json"
    path = DESKTOP / "resources" / name
    return path if target in ("darwin", "win32") and path.is_file() else ROOT / "release.json"


# 组织构建所需的源文件、资源和版本信息。
def prepare(destination=None, target=None):
    target = target or sys.platform
    # 两个桌面系统共用经用户定稿的界面与控制器，只替换必要的系统文案。
    desktop = DESKTOP
    stage = Path(destination) if destination else ROOT / "build/open-source/stage"
    app = stage / "app"
    if stage.exists():
        shutil.rmtree(stage)
    shutil.copytree(
        ROOT / "app",
        app,
        ignore=shutil.ignore_patterns(
            "__pycache__", "tests", "*.so", "*.pyd", "*.dylib", "*.dll", ".DS_Store"
        ),
    )
    # 顶层桌面模块全部来自同一份源码，新增模块不再遗漏于打包清单。
    for source in desktop.glob("*.py"):
        if source.name not in ("build_next_shaders.py", "make_icon.py"):
            shutil.copy2(source, app / source.name)
    (app / "ui").mkdir(parents=True, exist_ok=True)
    shutil.copy2(desktop / "ui/Main.qml", app / "ui/Main.qml")
    shutil.copytree(desktop / "resources", app / "resources", dirs_exist_ok=True)
    shutil.copy2(release_path(target), app / "resources/release.json")
    for entry in ("render", "fields"):
        shutil.copy2(DESKTOP / "core" / (entry + ".wgsl"), app / "core" / (entry + ".wgsl"))
    video_tool = ROOT / "build/full-102/ffmpeg/bin/ffmpeg"
    if target == "darwin" and video_tool.is_file():
        (app / "bin").mkdir(exist_ok=True)
        shutil.copy2(video_tool, app / "bin/ffmpeg")
    shutil.copytree(ROOT / "assets", stage / "assets", ignore=shutil.ignore_patterns(".DS_Store"))
    shutil.copytree(desktop / "assets", stage / "assets", dirs_exist_ok=True)
    for key in ("cloud", "fold"):
        for suffix in (".jpg", ".gif"):
            (stage / "assets/thumbnails" / (key + suffix)).unlink(missing_ok=True)
    if target == "win32":
        qml = app / "ui/Main.qml"
        qml.write_text(
            qml.read_text(encoding="utf-8")
            .replace("在访达中显示", "打开文件夹")
            .replace('"Metal GPU"', 'qsTr("GPU 加速")'),
            encoding="utf-8",
        )
    icon = stage / "assets/app-icon-glass.png"
    if not icon.exists() or not (stage / "时刃.icns").exists():
        subprocess.run(
            [
                sys.executable,
                str(DESKTOP / "make_icon.py"),
                str(DESKTOP / "assets/app-icon-glass.svg"),
                str(icon),
                str(stage / "时刃.icns"),
            ],
            check=True,
            env=dict(os.environ, QT_QPA_PLATFORM="offscreen"),
        )
    for name in ("LICENSE", "README.md", "THIRD_PARTY.md", "release.json"):
        if (ROOT / name).is_file():
            shutil.copy2(ROOT / name, stage / name)
    shutil.copy2(release_path(target), stage / "release.json")
    readme = DESKTOP / ("README_WINDOWS.md" if target == "win32" else "README_MAC.md")
    if readme.is_file():
        shutil.copy2(readme, stage / "README.md")
    # PR timing is required at runtime. Personal locations are not.
    reference = app / "resources/PRReference.json"
    data = json.loads(reference.read_text(encoding="utf-8"))
    data["source"] = "切片参考工程.prproj"
    for media in data.get("media", {}).values():
        if "originalPath" in media:
            media["originalPath"] = media.get("name", Path(media["originalPath"]).name)
    reference.write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )
    print(stage, flush=True)
    return stage


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--destination", type=Path)
    args = parser.parse_args()
    prepare(args.destination)
