"""使用经过校验的Android NDK构建共用桌面内核。"""

import hashlib
import json
import stat
import subprocess
import zipfile
from pathlib import Path

R = Path(__file__).resolve().parents[2]
D = R / "mobile/build/stable-deps"
B = R / "mobile/build/stable-native"


def ndk():
    """按Google仓库元数据校验压缩包，保留可执行位和NDK内部相对链接。"""
    marker = D / "ndk-ready.json"
    if marker.is_file():
        return Path(json.loads(marker.read_text())["path"])
    info = json.loads((D / "ndk-download.json").read_text())
    package = D / "ndk-r29.zip"
    assert package.stat().st_size == int(info["size"])
    digest = hashlib.sha1()
    with package.open("rb") as stream:
        for block in iter(lambda: stream.read(1024**2), b""):
            digest.update(block)
    assert digest.hexdigest() == info["checksum"], "Android NDK checksum mismatch"
    with zipfile.ZipFile(package) as archive:
        folder = archive.namelist()[0].split("/")[0]
        for item in archive.infolist():
            output = D / item.filename
            assert output.resolve().is_relative_to(D.resolve()), item.filename
            mode = item.external_attr >> 16
            if stat.S_ISLNK(mode):
                target = archive.read(item).decode()
                assert (output.parent / target).resolve().is_relative_to(D.resolve())
                output.parent.mkdir(parents=True, exist_ok=True)
                if not output.exists() and not output.is_symlink():
                    output.symlink_to(target)
            else:
                archive.extract(item, D)
                if mode and not item.is_dir():
                    output.chmod(stat.S_IMODE(mode))
    path = D / folder
    marker.write_text(
        json.dumps(dict(path=str(path), sha1=digest.hexdigest(), url=info["url"]), indent=2)
    )
    return path


def main():
    """只编译视频切片共用内核，支持ARM64与x86_64。"""
    toolchain = ndk() / "toolchains/llvm/prebuilt/darwin-x86_64"
    binary = toolchain / "bin"
    B.mkdir(parents=True, exist_ok=True)
    for abi, target in (("arm64-v8a", "aarch64-linux-android"), ("x86_64", "x86_64-linux-android")):
        compiler = binary / (target + "29-clang++")
        out = R / "mobile/android/app/src/main/jniLibs" / abi
        out.mkdir(parents=True, exist_ok=True)
        common = [
            str(compiler),
            "-O3",
            "-std=c++17",
            "-fPIC",
            "-fvisibility=hidden",
            "-Wl,-z,max-page-size=16384",
            "-static-libstdc++",
        ]
        subprocess.run(
            [
                *common,
                "-shared",
                "-DSHIREN_MAC42=1",
                "-DSHIREN_MAC_NEXT=1",
                "-I",
                str(R / "mac-5.0-redesign/core"),
                str(R / "mobile/android-core/android_bridge.cpp"),
                "-o",
                str(out / "libshiren.so"),
            ],
            check=True,
        )
        print(abi + " video core ready", flush=True)


if __name__ == "__main__":
    main()
