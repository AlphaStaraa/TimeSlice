"""同步Mac、Windows和Android的版本与AGPL声明。"""

import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


# 同步当前三个平台的声明和独立版本。
def sync():
    release = json.loads((ROOT / "release.json").read_text(encoding="utf-8"))
    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    notice = (
        f"时刃 / TimeSlice\n作者 {release['author']}\n"
        "本软件完全免费，自有代码以 AGPL-3.0-only 开源。"
        "允许商业使用和收费分发，须遵守对应源码与网络交互条款。\n"
        "第三方组件保留各自许可，旧版本合法取得的授权不受影响。\n\n" + license_text
    )
    folders = [
        ROOT / "mac-5.0-redesign/resources",
        ROOT / "mobile/android/app/src/main/assets",
    ]
    for folder in folders:
        folder.mkdir(parents=True, exist_ok=True)
        metadata = release
        mac_release = ROOT / "mac-5.0-redesign/resources/mac-release.json"
        if folder == ROOT / "mac-5.0-redesign/resources" and mac_release.exists():
            metadata = json.loads(mac_release.read_text(encoding="utf-8"))
        android_release = ROOT / "mobile/android-release.json"
        if folder == ROOT / "mobile/android/app/src/main/assets" and android_release.exists():
            metadata = json.loads(android_release.read_text())
        current_notice = notice.replace(release["displayVersion"], metadata["displayVersion"])
        notice_name = (
            "notice-zh.txt"
            if folder == ROOT / "mobile/android/app/src/main/assets"
            else "许可与免责声明.txt"
        )
        (folder / notice_name).write_text(current_notice, encoding="utf-8")
        (folder / "release.json").write_text(
            json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        shutil.copy2(ROOT / "LICENSE", folder / "LICENSE")
        shutil.copy2(ROOT / "app/resources/catalogue.json", folder / "catalogue.json")
    manifest = ROOT / "mobile/android/app/src/main/AndroidManifest.xml"
    text = manifest.read_text(encoding="utf-8")
    android_metadata = (
        json.loads((ROOT / "mobile/android-release.json").read_text())
        if (ROOT / "mobile/android-release.json").exists()
        else release
    )
    text = re.sub(
        r'android:versionCode="\d+"', f'android:versionCode="{android_metadata["build"]}"', text
    )
    text = re.sub(
        r'android:versionName="[^"]+"', f'android:versionName="{android_metadata["version"]}"', text
    )
    manifest.write_text(text, encoding="utf-8")
    print("Active-platform notices synchronized: macOS, Windows, Android")


if __name__ == "__main__":
    sync()
