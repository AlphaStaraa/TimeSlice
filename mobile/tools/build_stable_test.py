"""构建只含测试类的仪器化包，正式APK不含调试路由或测试活动。"""

import argparse
import os
import shutil
import subprocess
import zipfile
from pathlib import Path

R = Path(__file__).resolve().parents[1]
B = R / "build/stable-test"
B.mkdir(parents=True, exist_ok=True)
T = R / "build/android-sdk/build-tools/android-16"
A = R / "build/android-sdk/platforms/android-36/android.jar"
J = Path("/Library/Java/JavaVirtualMachines/jdk-19.jdk/Contents/Home/bin")


def run(args):
    """立即报告编译或签名失败，避免混用上一次的测试产物。"""
    subprocess.run([str(x) for x in args], check=True)


def main():
    """只依赖正式应用的类签名，在目标进程调用已发布的真实实现。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--physical-fixtures", type=Path)
    args = parser.parse_args()
    classes = B / "classes"
    dex = B / "dex"
    for path in (classes, dex):
        shutil.rmtree(path, ignore_errors=True)
        path.mkdir()
    run(
        [
            T / "aapt2",
            "link",
            "-o",
            B / "base.apk",
            "-I",
            A,
            "--manifest",
            R / "tests/StableManifest.xml",
        ]
    )
    dependencies = [R / "build/android/classes", *sorted((R / "android/app/libs").glob("*.jar"))]
    run(
        [
            J / "javac",
            "-encoding",
            "UTF-8",
            "-source",
            "8",
            "-target",
            "8",
            "-Xlint:-options",
            "-bootclasspath",
            str(T / "core-lambda-stubs.jar") + os.pathsep + str(A),
            "-classpath",
            os.pathsep.join(str(p) for p in dependencies),
            "-d",
            classes,
            R / "tests/StableInstrumentation.java",
            R / "tests/UiDesignInstrumentation.java",
            R / "tests/PhysicalInstrumentation.java",
            R / "tests/UiReviewInstrumentation.java",
        ]
    )
    with zipfile.ZipFile(B / "classes.jar", "w") as archive:
        for p in classes.rglob("*.class"):
            archive.write(p, str(p.relative_to(classes)))
    run(
        [
            J / "java",
            "-cp",
            T / "lib/d8.jar",
            "com.android.tools.r8.D8",
            "--min-api",
            "29",
            "--lib",
            A,
            "--classpath",
            R / "build/android/classes.jar",
            "--output",
            dex,
            B / "classes.jar",
        ]
    )
    shutil.copy2(B / "base.apk", B / "unsigned.apk")
    with zipfile.ZipFile(B / "unsigned.apk", "a") as archive:
        for p in dex.glob("*.dex"):
            archive.write(p, p.name)
        if args.physical_fixtures:
            for name in ("source.mp4", "jitter.rgba", "map16.png", "stress.mov"):
                p = args.physical_fixtures / name
                if p.is_file():
                    archive.write(
                        p, "assets/validation/" + name, compress_type=zipfile.ZIP_DEFLATED
                    )
    run([T / "zipalign", "-f", "-P", "16", "4", B / "unsigned.apk", B / "aligned.apk"])
    run(
        [
            J / "java",
            "-jar",
            T / "lib/apksigner.jar",
            "sign",
            "--ks",
            R / "build/local-preview.keystore",
            "--ks-key-alias",
            "local-preview",
            "--ks-pass",
            "pass:android",
            "--key-pass",
            "pass:android",
            "--out",
            B / "test.apk",
            B / "aligned.apk",
        ]
    )


if __name__ == "__main__":
    main()
