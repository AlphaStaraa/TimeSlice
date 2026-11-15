import os
import shutil
import subprocess
import zipfile
from pathlib import Path

R = Path(__file__).resolve().parents[1]
B = R / "build/android-test"
B.mkdir(parents=True, exist_ok=True)
T = R / "build/android-sdk/build-tools/android-16"
A = R / "build/android-sdk/platforms/android-36/android.jar"
J = Path("/Library/Java/JavaVirtualMachines/jdk-19.jdk/Contents/Home/bin")
S = R / "android/app/src/main"
classes = B / "classes"
classes.mkdir(exist_ok=True)
dex = B / "dex"
dex.mkdir(exist_ok=True)


# 执行当前任务的主流程并把结果或失败交给调用方。
def run(args):
    subprocess.run([str(x) for x in args], check=True)


run(
    [
        T / "aapt2",
        "link",
        "-o",
        B / "base.apk",
        "-I",
        A,
        "--manifest",
        R / "tests/TestManifest.xml",
        "-A",
        S / "assets",
    ]
)
run(
    [
        J / "javac",
        "-source",
        "8",
        "-target",
        "8",
        "-Xlint:-options",
        "-bootclasspath",
        str(T / "core-lambda-stubs.jar") + os.pathsep + str(A),
        "-classpath",
        R / "android/app/libs/jcodec-0.2.5.jar",
        "-d",
        classes,
        *sorted((S / "java").rglob("*.java")),
        R / "tests/TestActivity.java",
        R / "tests/CodecSanityActivity.java",
        R / "tests/WorkflowInstrumentation.java",
    ]
)
with zipfile.ZipFile(B / "classes.jar", "w") as z:
    for p in classes.rglob("*.class"):
        z.write(p, str(p.relative_to(classes)))
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
        "--output",
        dex,
        B / "classes.jar",
        R / "android/app/libs/jcodec-0.2.5.jar",
    ]
)
shutil.copy2(B / "base.apk", B / "unsigned.apk")
with zipfile.ZipFile(B / "unsigned.apk", "a", zipfile.ZIP_DEFLATED) as z:
    for p in dex.glob("*.dex"):
        z.write(p, p.name)
    for p in (S / "jniLibs").rglob("*.so"):
        z.write(p, "lib/" + str(p.relative_to(S / "jniLibs")))
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
