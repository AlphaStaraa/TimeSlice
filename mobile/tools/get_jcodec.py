import hashlib
import ssl
import urllib.request
import zipfile
from pathlib import Path

R = Path(__file__).resolve().parents[1]
(R / "build").mkdir(exist_ok=True)
libs = R / "android/app/libs"
libs.mkdir(exist_ok=True)
ctx = (
    ssl.create_default_context(cafile="/etc/ssl/cert.pem")
    if Path("/etc/ssl/cert.pem").is_file()
    else ssl.create_default_context()
)
base = "https://repo.maven.apache.org/maven2/org/jcodec/jcodec/0.2.5/"
for name in ["jcodec-0.2.5.jar", "jcodec-0.2.5-sources.jar"]:
    target = libs / name if "sources" not in name else R / "build" / name
    sha = (
        urllib.request.urlopen(base + name + ".sha1", context=ctx, timeout=30)
        .read()
        .decode()
        .strip()
        .split()[0]
    )
    if not target.exists() or hashlib.sha1(target.read_bytes()).hexdigest() != sha:
        with urllib.request.urlopen(base + name, context=ctx, timeout=60) as response:
            target.write_bytes(response.read())
    assert hashlib.sha1(target.read_bytes()).hexdigest() == sha
    print(name, "verified")
with zipfile.ZipFile(R / "build/jcodec-0.2.5-sources.jar") as z:
    for n in [
        "org/jcodec/api/SequenceEncoder.java",
        "org/jcodec/codecs/h264/H264Encoder.java",
        "org/jcodec/api/transcode/SinkImpl.java",
    ]:
        (R / "build" / Path(n).name).write_bytes(z.read(n))
