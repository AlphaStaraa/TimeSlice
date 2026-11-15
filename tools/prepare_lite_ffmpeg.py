"""从随源码提供的固定归档准备编译依赖，构建不依赖用户旧缓存。"""

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def prepare():
    """验证归档后解包，在项目目录编译pkgconf和x264，不安装到系统。"""
    if sys.platform != "darwin":
        raise RuntimeError("The compact FFmpeg profile currently builds on macOS")
    vendor = ROOT / "lite/vendor"
    lock = json.loads((vendor / "build.json").read_text(encoding="utf-8"))
    dependencies = ROOT / "build/lite/dependencies"
    dependencies.mkdir(parents=True, exist_ok=True)
    for entry in lock["sources"]:
        archive = dependencies / entry["name"]
        if not archive.is_file():
            shutil.copy2(vendor / entry["name"], archive)
        if hashlib.sha256(archive.read_bytes()).hexdigest() != entry["sha256"]:
            raise ValueError("Source archive checksum mismatch: " + entry["name"])
        with tarfile.open(archive) as source:
            members = source.getmembers()
            top = members[0].name.split("/")[0]
            if not (dependencies / top).exists():
                for member in members:
                    if (
                        not (dependencies / member.name).resolve().is_relative_to(dependencies)
                        or member.issym()
                        or member.islnk()
                    ):
                        raise ValueError("Unsafe source archive entry")
                source.extractall(dependencies)
    prefix = dependencies / "prefix"
    environment = dict(os.environ, MACOSX_DEPLOYMENT_TARGET="14.0")
    commands = [
        (
            dependencies / "pkgconf-2.5.1",
            prefix / "bin/pkgconf",
            ["./configure", "--prefix=" + str(prefix), "--disable-shared", "--enable-static"],
        ),
        (
            dependencies / "x264-stable",
            prefix / "lib/libx264.a",
            [
                "./configure",
                "--prefix=" + str(prefix),
                "--enable-static",
                "--disable-cli",
                "--disable-opencl",
            ],
        ),
    ]
    with (dependencies / "prepare.log").open("w", encoding="utf-8") as log:
        for source, artifact, configure in commands:
            if artifact.is_file():
                continue
            for command in (configure, ["make", "-j6"], ["make", "install"]):
                subprocess.run(
                    command,
                    cwd=source,
                    env=environment,
                    check=True,
                    stdout=log,
                    stderr=subprocess.STDOUT,
                )
    print("Pinned compact-video dependencies ready.", flush=True)
    return dependencies


if __name__ == "__main__":
    prepare()
