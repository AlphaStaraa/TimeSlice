import hashlib
import subprocess
import zipfile
from pathlib import Path

R = Path(__file__).resolve().parents[1]
p = R / "build/android29-image.zip"
sha = "fa0d67d7430fcc84b2fe2508ea81e92ac644e264"
url = "https://dl.google.com/android/repository/sys-img/android/arm64-v8a-29_r08.zip"
if not p.exists() or hashlib.sha1(p.read_bytes()).hexdigest() != sha:
    subprocess.run(["curl", "-fL", "--retry", "3", "-C", "-", "-sS", "-o", str(p), url], check=True)
assert hashlib.sha1(p.read_bytes()).hexdigest() == sha
d = R / "build/android29-image"
d.mkdir(exist_ok=True)
with zipfile.ZipFile(p) as z:
    z.extractall(d)
print("AOSP Android 10 ARM64 image ready", flush=True)
