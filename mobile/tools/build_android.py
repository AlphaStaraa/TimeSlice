import os
import shutil
import subprocess
import zipfile
from pathlib import Path

R = Path(__file__).resolve().parents[1]
release = __import__("json").loads(
    (
        (R / "android-release.json")
        if (R / "android-release.json").exists()
        else (R.parent / "release.json")
    ).read_text()
)
B = R / "build/android"
B.mkdir(parents=True, exist_ok=True)
sdk = R / "build/android-sdk"
tools = sdk / "build-tools/android-16"
jar = sdk / "platforms/android-36/android.jar"
jdk = Path(
    os.environ.get("JAVA_HOME") or "/Library/Java/JavaVirtualMachines/jdk-19.jdk/Contents/Home"
)
env = dict(os.environ, JAVA_HOME=str(jdk))
env["PATH"] = str(jdk / "bin") + os.pathsep + env.get("PATH", "")
for name in ("aapt2", "zipalign", "apksigner", "d8"):
    (tools / name).chmod(0o755)
src = R / "android/app/src/main"
classes = B / "classes"
shutil.rmtree(classes, ignore_errors=True)
classes.mkdir(exist_ok=True)
dex = B / "dex"
shutil.rmtree(dex, ignore_errors=True)
dex.mkdir(exist_ok=True)


# 执行当前任务的主流程并把结果或失败交给调用方。
def run(a):
    subprocess.run([str(x) for x in a], check=True, env=env)


run([tools / "aapt2", "compile", "--dir", src / "res", "-o", B / "resources.zip"])
run(
    [
        tools / "aapt2",
        "link",
        "-o",
        B / "resources.apk",
        "-I",
        jar,
        "--manifest",
        src / "AndroidManifest.xml",
        "--min-sdk-version",
        "29",
        "--target-sdk-version",
        "36",
        "-A",
        src / "assets",
        B / "resources.zip",
    ]
)
run(
    [
        jdk / "bin/javac",
        "-encoding",
        "UTF-8",
        "-source",
        "8",
        "-target",
        "8",
        "-Xlint:-options",
        "-bootclasspath",
        str(tools / "core-lambda-stubs.jar") + os.pathsep + str(jar),
        "-classpath",
        os.pathsep.join(str(p) for p in sorted((R / "android/app/libs").glob("*.jar"))),
        "-d",
        classes,
        *sorted((src / "java").rglob("*.java")),
    ]
)
with zipfile.ZipFile(B / "classes.jar", "w") as z:
    for p in classes.rglob("*.class"):
        z.write(p, str(p.relative_to(classes)))
run(
    [
        jdk / "bin/java",
        "-cp",
        tools / "lib/d8.jar",
        "com.android.tools.r8.D8",
        "--min-api",
        "29",
        "--lib",
        jar,
        "--output",
        dex,
        B / "classes.jar",
        *sorted((R / "android/app/libs").glob("*.jar")),
    ]
)
shutil.copy2(B / "resources.apk", B / "unsigned.apk")
# 在签名前确认法律声明与界面资源确实进入APK，不能仅检查源码目录存在。
with zipfile.ZipFile(B / "resources.apk") as resources:
    for name in (
        "notice-zh.txt",
        "LICENSE.en.txt",
        "THIRD-PARTY-Stable.txt",
        "brand.png",
        "effects.json",
        "field.comp",
    ):
        assert resources.read("assets/" + name), "Missing packaged asset: " + name
with zipfile.ZipFile(B / "unsigned.apk", "a", zipfile.ZIP_DEFLATED) as z:
    for p in dex.glob("*.dex"):
        z.write(p, p.name)
    for p in (src / "jniLibs").rglob("*.so"):
        z.write(p, "lib/" + str(p.relative_to(src / "jniLibs")))
run([tools / "zipalign", "-f", "-P", "16", "4", B / "unsigned.apk", B / "aligned.apk"])
key = R / "build/local-preview.keystore"
if not key.exists():
    run(
        [
            jdk / "bin/keytool",
            "-genkeypair",
            "-keystore",
            key,
            "-storepass",
            "android",
            "-keypass",
            "android",
            "-alias",
            "local-preview",
            "-keyalg",
            "RSA",
            "-keysize",
            "2048",
            "-validity",
            "3650",
            "-dname",
            "CN=ShiRen Local Preview,O=Local Development,C=CN",
        ]
    )
out = R / "dist"
out.mkdir(exist_ok=True)
run(
    [
        jdk / "bin/java",
        "-jar",
        tools / "lib/apksigner.jar",
        "sign",
        "--ks",
        key,
        "--ks-key-alias",
        "local-preview",
        "--ks-pass",
        "pass:android",
        "--key-pass",
        "pass:android",
        "--out",
        out / f"时刃_Android_{release['version']}.apk",
        B / "aligned.apk",
    ]
)
run(
    [
        jdk / "bin/java",
        "-jar",
        tools / "lib/apksigner.jar",
        "verify",
        "--verbose",
        out / f"时刃_Android_{release['version']}.apk",
    ]
)
run([tools / "aapt2", "dump", "badging", out / f"时刃_Android_{release['version']}.apk"])
print("Android APK ready")
