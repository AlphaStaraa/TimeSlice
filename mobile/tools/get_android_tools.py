import hashlib
import json
import ssl
import subprocess
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
build = ROOT / "build"
ctx = ssl.create_default_context(cafile="/etc/ssl/cert.pem")
url = "https://dl.google.com/android/repository/repository2-3.xml"
xml = urllib.request.urlopen(url, context=ctx, timeout=30).read()
(build / "android-repository.xml").write_bytes(xml)
root = ET.fromstring(xml)
selected = []
for node in root:
    if node.tag.endswith("remotePackage") and node.attrib.get("path") in [
        "platforms;android-36",
        "build-tools;36.0.0",
        "platform-tools",
    ]:
        for arc in node.findall("./archives/archive"):
            host = arc.findtext("host-os")
            arch = arc.findtext("host-arch")
            if host and host != "macosx":
                continue
            complete = arc.find("complete")
            rel = complete.findtext("url")
            sha = complete.findtext("checksum")
            size = int(complete.findtext("size"))
            selected.append(
                dict(
                    package=node.attrib["path"],
                    url="https://dl.google.com/android/repository/" + rel,
                    sha1=sha,
                    size=size,
                )
            )
            break
(build / "android-downloads.json").write_text(json.dumps(selected, indent=2))
print(selected, flush=True)
for item in selected:
    path = build / Path(item["url"]).name
    if not path.exists() or hashlib.sha1(path.read_bytes()).hexdigest() != item["sha1"]:
        subprocess.run(
            ["curl", "-fL", "--retry", "3", "-C", "-", "-o", str(path), item["url"]], check=True
        )
    assert hashlib.sha1(path.read_bytes()).hexdigest() == item["sha1"]
    dest = build / "android-sdk" / item["package"].split(";")[0]
    dest.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path) as z:
        z.extractall(dest)
    print("Ready", item["package"], flush=True)
