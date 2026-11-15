"""下载并校验Android正式版构建依赖，只写项目内的可重建目录。"""

import hashlib
import json
import subprocess
import zipfile
from pathlib import Path

R = Path(__file__).resolve().parents[2]
D = R / "mobile/build/stable-deps"


def fetch(url, path, expected, algorithm="sha256"):
    """使用系统TLS信任下载固定依赖，哈希不匹配时拒绝构建。"""
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        subprocess.run(
            ["curl", "-fL", "--retry", "3", "--connect-timeout", "20", url, "-o", str(path)],
            check=True,
        )
    digest = hashlib.new(algorithm)
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024**2), b""):
            digest.update(block)
    if digest.hexdigest() != expected:
        raise ValueError("Dependency checksum mismatch: " + path.name)


def main():
    """准备视频处理所用OpenCV、NDK和编码依赖。"""
    lock = json.loads((R / "mobile/dependencies.json").read_text())
    libs = R / "mobile/android/app/libs"
    opencv = lock["opencv"]
    aar = D / ("opencv-" + opencv["version"] + ".aar")
    fetch(opencv["url"], aar, opencv["sha256"])
    with zipfile.ZipFile(aar) as archive:
        libs.mkdir(parents=True, exist_ok=True)
        (libs / ("opencv-" + opencv["version"] + ".jar")).write_bytes(archive.read("classes.jar"))
        for abi in lock["nativeABIs"]:
            for name in ("libopencv_java4.so", "libc++_shared.so"):
                out = R / "mobile/android/app/src/main/jniLibs" / abi / name
                out.parent.mkdir(parents=True, exist_ok=True)
                out.write_bytes(archive.read("jni/" + abi + "/" + name))
    ndk = lock["androidNDK"]
    package = D / "ndk-r29.zip"
    if not (D / "ndk-ready.json").is_file():
        fetch(ndk["url"], package, ndk["checksum"], "sha1")
    (D / "ndk-download.json").write_text(json.dumps(ndk, indent=2))
    codec = lock["jcodec"]
    fetch(codec["url"], libs / ("jcodec-" + codec["version"] + ".jar"), codec["sha256"])
    print("Android stable dependencies verified.", flush=True)


if __name__ == "__main__":
    main()
