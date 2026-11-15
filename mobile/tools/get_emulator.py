import concurrent.futures
import hashlib
import json
import ssl
import subprocess
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

R = Path(__file__).resolve().parents[1]
B = R / "build"
ctx = ssl.create_default_context(cafile="/etc/ssl/cert.pem")


# 读取 SDK 索引中的 XML 节点内容。
def xml(url):
    return ET.fromstring(urllib.request.urlopen(url, context=ctx, timeout=30).read())


repo = ET.fromstring((B / "android-repository.xml").read_bytes())
jobs = []
for p in repo:
    if (
        p.tag.endswith("remotePackage")
        and p.attrib.get("path") == "emulator"
        and p.find("channelRef").attrib.get("ref") == "channel-0"
    ):
        for a in p.findall("./archives/archive"):
            if a.findtext("host-os") == "macosx" and a.findtext("host-arch") in (
                "aarch64",
                "arm64",
            ):
                c = a.find("complete")
                jobs.append(
                    (
                        "emulator",
                        "https://dl.google.com/android/repository/" + c.findtext("url"),
                        c.findtext("checksum"),
                    )
                )
                break
        if jobs:
            break
base = "https://dl.google.com/android/repository/sys-img/google_apis/"
sys = xml(base + "sys-img2-3.xml")
for p in sys:
    if (
        p.tag.endswith("remotePackage")
        and p.attrib.get("path") == "system-images;android-35;google_apis;arm64-v8a"
    ):
        a = p.find("./archives/archive/complete")
        jobs.append(("system-image", base + a.findtext("url"), a.findtext("checksum")))
        break
print(jobs, flush=True)
(B / "emulator-downloads.json").write_text(json.dumps(jobs, indent=2))


# 获取所需输入或数据片段，交给后续处理。
def fetch(item):
    name, url, sha = item
    path = B / (name + ".zip")
    if not path.exists() or hashlib.sha1(path.read_bytes()).hexdigest() != sha:
        subprocess.run(
            ["curl", "-fL", "--retry", "3", "-C", "-", "-sS", "-o", str(path), url], check=True
        )
    assert hashlib.sha1(path.read_bytes()).hexdigest() == sha
    dest = B / name
    dest.mkdir(exist_ok=True)
    with zipfile.ZipFile(path) as z:
        z.extractall(dest)
        for f in z.infolist():
            if f.external_attr >> 16 & 0o111:
                (dest / f.filename).chmod((f.external_attr >> 16) & 0o777)
    print("Ready", name, flush=True)


with concurrent.futures.ThreadPoolExecutor(2) as ex:
    list(ex.map(fetch, jobs))
