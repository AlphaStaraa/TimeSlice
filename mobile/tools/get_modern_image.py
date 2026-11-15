import hashlib
import subprocess
import zipfile
from pathlib import Path

R = Path(__file__).resolve().parents[1]
p = R / "build/android35-atd.zip"
sha = "19feee66a81448df6c612ddbdc3088c82d86b3cf"
url = "https://dl.google.com/android/repository/sys-img/aosp_atd/arm64-v8a-35_r01.zip"
if not p.exists() or hashlib.sha1(p.read_bytes()).hexdigest() != sha:
    subprocess.run(["curl", "-fL", "--retry", "3", "-C", "-", "-sS", "-o", str(p), url], check=True)
assert hashlib.sha1(p.read_bytes()).hexdigest() == sha
d = R / "build/android35-atd"
d.mkdir(exist_ok=True)
with zipfile.ZipFile(p) as z:
    z.extractall(d)
print("Android 15 automated-test image ready", flush=True)
