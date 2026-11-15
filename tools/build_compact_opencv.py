"""从固定源码构建只含实际图像处理模块的OpenCV，不重复收纳视频编解码库。"""

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tarfile
from pathlib import Path, PurePosixPath

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / "build/full-101/opencv"
LOCK = ROOT / "mac-5.0-redesign/compact-opencv.json"


def main():
    """源码校验、独立编译、生成便携加载配置；不覆盖开发环境原OpenCV。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--record-source", action="store_true")
    args = parser.parse_args()
    archive = args.archive.resolve()
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    source_info = dict(
        version="4.13.0",
        sha256=digest,
        url="https://codeload.github.com/opencv/opencv/tar.gz/refs/tags/4.13.0",
    )
    if args.record_source:
        assert not LOCK.exists(), "源码锁已有记录，不能静默改动"
        LOCK.write_text(json.dumps(source_info, indent=2), encoding="utf-8")
    assert json.loads(LOCK.read_text(encoding="utf-8")) == source_info
    WORK.mkdir(parents=True, exist_ok=True)
    source = WORK / "opencv-4.13.0"
    if not source.exists():
        with tarfile.open(archive) as bundle:
            members = bundle.getmembers()
            assert all(
                x.name.startswith("opencv-4.13.0/") or x.name == "opencv-4.13.0" for x in members
            )
            assert all(
                not PurePosixPath(x.name).is_absolute()
                and ".." not in PurePosixPath(x.name).parts
                and (x.isfile() or x.isdir())
                for x in members
            ), "源码归档必须只含根目录内的普通文件与目录"
            bundle.extractall(WORK, members=members)
    prefix = WORK / "install"
    build = WORK / "build"
    cmake = Path(sys.executable).parent / "cmake"
    ninja = Path(sys.executable).parent / "ninja"
    arguments = [
        str(cmake),
        "-S",
        str(source),
        "-B",
        str(build),
        "-G",
        "Ninja",
        "-DCMAKE_MAKE_PROGRAM=" + str(ninja),
        "-DCMAKE_BUILD_TYPE=Release",
        "-DCMAKE_INSTALL_PREFIX=" + str(prefix),
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=14.0",
        "-DBUILD_LIST=core,imgproc,flann,features2d,calib3d,video,python3",
        "-DBUILD_SHARED_LIBS=OFF",
        "-DBUILD_TESTS=OFF",
        "-DBUILD_PERF_TESTS=OFF",
        "-DBUILD_EXAMPLES=OFF",
        "-DBUILD_JAVA=OFF",
        "-DBUILD_opencv_apps=OFF",
        "-DBUILD_opencv_python2=OFF",
        "-DBUILD_DOCS=OFF",
        "-DWITH_FFMPEG=OFF",
        "-DWITH_AVFOUNDATION=OFF",
        "-DWITH_GSTREAMER=OFF",
        "-DWITH_OPENCL=OFF",
        "-DWITH_IPP=OFF",
        "-DWITH_ITT=OFF",
        "-DWITH_EIGEN=OFF",
        "-DWITH_TBB=OFF",
        "-DWITH_OPENMP=OFF",
        "-DWITH_PROTOBUF=OFF",
        "-DBUILD_PROTOBUF=OFF",
        "-DBUILD_opencv_dnn=OFF",
        "-DPYTHON3_EXECUTABLE=" + str(Path(sys.executable).absolute()),
        "-DPYTHON3_NUMPY_INCLUDE_DIRS=" + np.get_include(),
        "-DPYTHON3_PACKAGES_PATH=" + str(prefix / "python"),
    ]
    with (WORK / "build.log").open("w", encoding="utf-8") as log:
        for command in (
            arguments,
            [str(cmake), "--build", str(build), "--parallel", "6"],
            [str(cmake), "--install", str(build)],
        ):
            subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True)
    package = prefix / "python/cv2"
    binaries = list(package.rglob("cv2*.so"))
    assert len(binaries) == 1, binaries
    runtime = WORK / "runtime/cv2"
    if runtime.exists():
        shutil.rmtree(runtime)
    shutil.copytree(package, runtime, ignore=shutil.ignore_patterns("__pycache__", "*.so"))
    native = WORK / "native"
    native.mkdir(exist_ok=True)
    binary = native / binaries[0].name
    shutil.copy2(binaries[0], binary)
    subprocess.run(["strip", "-x", str(binary)], check=True)
    # Python包装与二进制分开收纳，打包器可正确改写Mach-O依赖和签名。
    (runtime / "config.py").write_text(
        "# Frameworks与Resources可能通过符号链接混合，原生扩展路径必须优先。\n"
        "sys.OpenCV_REPLACE_SYS_PATH_0 = True\nBINARIES_PATHS = []\n",
        encoding="utf-8",
    )
    config = "PYTHON_EXTENSIONS_PATHS = [os.path.join(LOADER_DIR, 'python-3.11')]\n"
    for name in ("config-3.py", "config-3.11.py"):
        (runtime / name).write_text(config, encoding="utf-8")
    license_path = ROOT / "LICENSES/OpenCV-4.13.0.txt"
    shutil.copy2(source / "LICENSE", license_path)
    report = dict(
        source=source_info,
        arguments=arguments,
        pythonPackage=str(runtime),
        binary=str(binary),
        binarySha256=hashlib.sha256(binary.read_bytes()).hexdigest(),
        bytes=binary.stat().st_size,
    )
    (WORK / "build.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(dict(binary=str(binary), MiB=report["bytes"] / 1024**2)), flush=True)


if __name__ == "__main__":
    main()
