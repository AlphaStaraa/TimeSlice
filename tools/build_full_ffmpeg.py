"""为完整版裁剪视频工具，保留广泛原生解码、AV1软件解码与硬件编码。"""

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
from pathlib import Path, PurePosixPath

from prepare_lite_ffmpeg import prepare

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / "build/full-102"


def extract(archive, destination):
    """只解开受控源码归档中的普通文件与目录，拒绝路径越界。"""
    with tarfile.open(archive) as bundle:
        members = bundle.getmembers()
        assert all(
            not PurePosixPath(x.name).is_absolute()
            and ".." not in PurePosixPath(x.name).parts
            and (x.isfile() or x.isdir())
            for x in members
        )
        bundle.extractall(destination, members=members)


def main():
    """构建隔离的dav1d和FFmpeg，旧版视频工具及开发依赖保持可用。"""
    prefix = WORK / "prefix"
    deps = WORK / "dependencies"
    deps.mkdir(parents=True, exist_ok=True)
    dav_archive = deps / "dav1d-1.5.1.tar.bz2"
    if not dav_archive.is_file():
        shutil.copy2(ROOT / "mac-5.0-redesign/vendor/dav1d-1.5.1.tar.bz2", dav_archive)
    dav_hash = hashlib.sha256(dav_archive.read_bytes()).hexdigest()
    lock = ROOT / "mac-5.0-redesign/full-ffmpeg-source.json"
    sources = dict(
        dav1d=dict(
            version="1.5.1",
            sha256=dav_hash,
            url="https://code.videolan.org/videolan/dav1d/-/archive/1.5.1/dav1d-1.5.1.tar.bz2",
        )
    )
    old = json.loads((ROOT / "lite/vendor/build.json").read_text(encoding="utf-8"))
    sources["ffmpeg"] = next(x for x in old["sources"] if x["name"] == "ffmpeg-9.0.2.tar.xz")
    if json.loads(lock.read_text(encoding="utf-8")) != sources:
        raise ValueError("Full FFmpeg source checksum mismatch")
    prepare()
    ff_archive = ROOT / "lite/vendor/ffmpeg-9.0.2.tar.xz"
    assert hashlib.sha256(ff_archive.read_bytes()).hexdigest() == sources["ffmpeg"]["sha256"]
    dav = WORK / "dav1d-1.5.1"
    if not dav.exists():
        extract(dav_archive, WORK)
    ff = WORK / "ffmpeg-9.0.2"
    if not ff.exists():
        extract(ff_archive, WORK)
    env = dict(os.environ)
    env["PATH"] = str(Path(sys.executable).parent) + os.pathsep + env.get("PATH", "")
    env["CFLAGS"] = "-O3 -mmacosx-version-min=14.0"
    env["LDFLAGS"] = "-mmacosx-version-min=14.0"
    env["MACOSX_DEPLOYMENT_TARGET"] = "14.0"
    meson = Path(sys.executable).parent / "meson"
    build = WORK / "dav1d-build"
    with (WORK / "ffmpeg-build.log").open("w", encoding="utf-8") as log:
        if not (build / "build.ninja").exists():
            subprocess.run(
                [
                    str(meson),
                    "setup",
                    str(build),
                    str(dav),
                    "--prefix=" + str(prefix),
                    "--buildtype=release",
                    "--default-library=static",
                    "-Denable_tools=false",
                    "-Denable_tests=false",
                ],
                env=env,
                stdout=log,
                stderr=subprocess.STDOUT,
                check=True,
            )
        for command in (
            [str(meson), "compile", "-C", str(build), "-j", "6"],
            [str(meson), "install", "-C", str(build)],
        ):
            subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, check=True)
        x264 = ROOT / "build/lite/dependencies/prefix"
        output = WORK / "ffmpeg"
        arguments = [
            "./configure",
            "--prefix=" + str(output),
            "--disable-everything",
            "--disable-autodetect",
            "--disable-network",
            "--disable-doc",
            "--disable-debug",
            "--disable-ffplay",
            "--disable-ffprobe",
            "--disable-shared",
            "--enable-static",
            "--enable-small",
            "--enable-gpl",
            "--enable-libx264",
            "--enable-libdav1d",
            "--enable-zlib",
            "--enable-videotoolbox",
            "--enable-audiotoolbox",
            "--enable-pthreads",
            "--pkg-config=" + str(x264 / "bin/pkgconf"),
            "--pkg-config-flags=--static",
            "--extra-cflags=-mmacosx-version-min=14.0 -I"
            + str(prefix / "include")
            + " -I"
            + str(x264 / "include"),
            "--extra-ldflags=-mmacosx-version-min=14.0 -L"
            + str(prefix / "lib")
            + " -L"
            + str(x264 / "lib"),
            "--enable-protocol=file,pipe",
            "--enable-demuxers",
            "--enable-decoders",
            "--enable-parsers",
            "--enable-bsfs",
            "--enable-muxer=mp4,mov,matroska,rawvideo,null,framemd5,wav",
            "--enable-encoder=libx264,h264_videotoolbox,hevc_videotoolbox,aac,rawvideo,pcm_s16le,wrapped_avframe",
            "--enable-filter=fps,scale,format,aresample,apad,trim,setpts,atrim,asetpts,transpose,hflip,vflip,color,testsrc2,null,anull,abuffer,buffer,buffersink,abuffersink",
            "--enable-indev=lavfi",
            "--enable-hwaccel=h264_videotoolbox,hevc_videotoolbox",
        ]
        env["PKG_CONFIG_PATH"] = (
            str(prefix / "lib/pkgconfig") + os.pathsep + str(x264 / "lib/pkgconfig")
        )
        for command in (arguments, ["make", "-j6"], ["make", "install"]):
            subprocess.run(
                command, cwd=ff, env=env, stdout=log, stderr=subprocess.STDOUT, check=True
            )
    binary = output / "bin/ffmpeg"
    subprocess.run(["strip", "-x", str(binary)], check=True)
    manifest = dict(
        arguments=arguments,
        sources=sources,
        binary=str(binary),
        sha256=hashlib.sha256(binary.read_bytes()).hexdigest(),
        bytes=binary.stat().st_size,
    )
    (output / "build.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print("FFmpeg MiB", binary.stat().st_size / 1024**2, flush=True)


if __name__ == "__main__":
    main()
