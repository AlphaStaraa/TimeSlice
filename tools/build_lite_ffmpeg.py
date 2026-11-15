"""从固定上游源码编译轻量视频工具，保留硬件编码及软件回退。"""

import argparse
import hashlib
import json
import os
import shutil
import subprocess
from pathlib import Path

from prepare_lite_ffmpeg import prepare

ROOT = Path(__file__).resolve().parents[1]
DEPS = ROOT / "build/lite/dependencies"


def main():
    """裁剪未用组件并保留可重现配置、源码摘要与第三方许可。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--rebuild", action="store_true")
    options = parser.parse_args()
    prepare()
    source = DEPS / "ffmpeg-9.0.2"
    prefix = DEPS / "prefix"
    pkgconf = prefix / "bin/pkgconf"
    if not pkgconf.is_file() or not (prefix / "lib/libx264.a").is_file():
        raise SystemExit("Build the pinned pkgconf and x264 dependencies first")
    output = ROOT / "build/lite/ffmpeg"
    output.mkdir(parents=True, exist_ok=True)
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
        "--enable-zlib",
        "--enable-videotoolbox",
        "--enable-audiotoolbox",
        "--enable-pthreads",
        "--pkg-config=" + str(pkgconf),
        "--pkg-config-flags=--static",
        "--extra-cflags=-mmacosx-version-min=14.0 -I" + str(prefix / "include"),
        "--extra-ldflags=-mmacosx-version-min=14.0 -L" + str(prefix / "lib"),
        "--enable-protocol=file,pipe",
        "--enable-demuxer=mov,matroska,avi,h264,hevc,mpegvideo,mpegps,mpegts,aac,mp3,wav,image2,rawvideo,flac,ogg",
        "--enable-muxer=mp4,mov,matroska,rawvideo,null,framemd5,wav",
        "--enable-decoder=h264,hevc,mpeg4,prores,mjpeg,png,vp8,vp9,aac,mp3,pcm_s16le,pcm_s24le,pcm_s32le,pcm_f32le,alac,flac,opus,vorbis,rawvideo,wrapped_avframe",
        "--enable-encoder=libx264,h264_videotoolbox,hevc_videotoolbox,aac,rawvideo,pcm_s16le,wrapped_avframe",
        "--enable-parser=h264,hevc,mpeg4video,mpegaudio,aac,vorbis,opus,vp8,vp9,png,flac",
        "--enable-bsf=h264_mp4toannexb,hevc_mp4toannexb,extract_extradata,aac_adtstoasc",
        "--enable-filter=fps,scale,format,aresample,apad,trim,setpts,atrim,asetpts,transpose,hflip,vflip,color,testsrc2,null,anull,abuffer,buffer,buffersink,abuffersink",
        "--enable-indev=lavfi",
        "--enable-hwaccel=h264_videotoolbox,hevc_videotoolbox",
    ]
    environment = dict(
        os.environ, PKG_CONFIG_PATH=str(prefix / "lib/pkgconfig"), MACOSX_DEPLOYMENT_TARGET="14.0"
    )
    manifest_path = output / "build.json"
    binary = output / "bin/ffmpeg"
    if not options.rebuild and binary.is_file() and manifest_path.is_file():
        previous = json.loads(manifest_path.read_text(encoding="utf-8"))
        if (
            previous.get("binarySha256") == hashlib.sha256(binary.read_bytes()).hexdigest()
            and previous.get("arguments") == arguments
        ):
            print(binary, "already verified", flush=True)
            return
    with (output / "build.log").open("w", encoding="utf-8") as log:
        commands = [["make", "clean"]] if (source / "ffbuild/config.mak").exists() else []
        commands += [arguments, ["make", "-j6"], ["make", "install"]]
        for command in commands:
            subprocess.run(
                command,
                cwd=source,
                env=environment,
                stdout=log,
                stderr=subprocess.STDOUT,
                check=True,
            )
    binary = output / "bin/ffmpeg"
    subprocess.run(["strip", "-x", str(binary)], check=True)
    manifest = dict(
        version="9.0.2",
        arguments=arguments,
        binarySha256=hashlib.sha256(binary.read_bytes()).hexdigest(),
        bytes=binary.stat().st_size,
        sources=[],
    )
    vendor = ROOT / "lite/vendor"
    vendor.mkdir(exist_ok=True)
    for name, url in (
        ("ffmpeg-9.0.2.tar.xz", "https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz"),
        (
            "x264-stable.tar.bz2",
            "https://code.videolan.org/videolan/x264/-/archive/stable/x264-stable.tar.bz2",
        ),
        ("pkgconf-2.5.1.tar.xz", "https://distfiles.ariadne.space/pkgconf/pkgconf-2.5.1.tar.xz"),
    ):
        path = DEPS / name
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        shutil.copy2(path, vendor / name)
        manifest["sources"].append(dict(name=name, url=url, sha256=digest))
    (output / "build.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    portable = json.loads(json.dumps(manifest).replace(str(ROOT), "${PROJECT_ROOT}"))
    (vendor / "build.json").write_text(json.dumps(portable, indent=2), encoding="utf-8")
    print(binary, round(binary.stat().st_size / 1024**2, 2), "MiB", flush=True)


if __name__ == "__main__":
    main()
