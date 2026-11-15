"""Check the release's shared notices and the core required by a fresh checkout."""

import ast
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


# 组织此入口的初始化、主流程和退出清理。
def main():
    release = json.loads((ROOT / "release.json").read_text(encoding="utf-8"))
    android_path = ROOT / "mobile/android-release.json"
    android_release = json.loads(android_path.read_text()) if android_path.exists() else release
    text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    assert (
        release["license"] == "AGPL-3.0-only"
        and "GNU AFFERO GENERAL PUBLIC LICENSE" in text
        and "19 November 2007" in text
    )
    active = release["activePlatforms"]
    assert active == ["macOS", "Windows", "Android"]
    folders = ["mac-5.0-redesign/resources", "mobile/android/app/src/main/assets"]
    for relative in folders:
        folder = ROOT / relative
        metadata = json.loads((folder / "release.json").read_text(encoding="utf-8"))
        expected = release
        if relative.startswith("mobile/android"):
            expected = android_release
        elif relative.startswith("mac-5.0-redesign"):
            expected = json.loads((folder / "mac-release.json").read_text(encoding="utf-8"))
        assert all(
            metadata[key] == expected[key]
            for key in ("version", "build", "author", "license", "effects")
        )
        assert (folder / "LICENSE").read_text(encoding="utf-8") == text
        notice_name = (
            "notice-zh.txt" if relative.startswith("mobile/android") else "许可与免责声明.txt"
        )
        notice = (folder / notice_name).read_text(encoding="utf-8")
        assert "AlphaStar" in notice and "完全免费" in notice and text in notice
        assert "采用闭源分发" not in notice and "禁止出售" not in notice
    manifest = ET.parse(ROOT / "mobile/android/app/src/main/AndroidManifest.xml").getroot()
    android = "{http://schemas.android.com/apk/res/android}"
    assert manifest.attrib[android + "versionName"] == android_release["version"]
    assert int(manifest.attrib[android + "versionCode"]) == android_release["build"]
    for target in ("mac", "windows"):
        metadata = json.loads(
            (ROOT / "mac-5.0-redesign/resources" / f"{target}-release.json").read_text()
        )
        assert re.fullmatch(r"\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?", metadata["version"])
        assert isinstance(metadata["build"], int) and metadata["build"] > 0
        assert all(metadata[key] == release[key] for key in ("author", "license", "effects"))
        assert metadata["platform"] == ("macOS" if target == "mac" else "Windows")
    for filename in (
        "app/core/cpu.cpp",
        "app/core/field_common.h",
        "app/core/gpu.slang",
        "app/core/render.wgsl",
        "app/core/fields.wgsl",
        "mac-5.0-redesign/core/shadow.h",
        "mac-5.0-redesign/core/creative.h",
        "mobile/android-core/android_bridge.cpp",
        "mobile/shared/gpu.slang",
    ):
        assert (ROOT / filename).is_file(), filename
    catalogues = [
        json.loads((ROOT / folder / "effects.json").read_text(encoding="utf-8"))
        for folder in ("mobile/android/app/src/main/assets",)
    ]
    expected_effects = [
        e
        for e in json.loads((ROOT / "app/resources/effects.json").read_text(encoding="utf-8"))
        if e["id"] not in (405, 406)
    ]
    expected_effects += json.loads(
        (ROOT / "mac-5.0-redesign/resources/mac42.json").read_text(encoding="utf-8")
    )
    for effect in expected_effects:
        if effect["family"] == 2:
            effect["duration"] = 4
    assert catalogues[0] == expected_effects and len(catalogues[0]) == release["effects"]
    groups = json.loads((ROOT / "app/resources/catalogue.json").read_text(encoding="utf-8"))
    ids = [v["effect"] for group in groups for v in group["variants"]]
    assert len(ids) == len(set(ids)) == 22
    assert set(ids) == {effect["id"] for effect in catalogues[0] if effect["family"] in (1, 2)}
    assert next(group for group in groups if group["key"] == "circle")["default"] == 300
    assert next(group for group in groups if group["key"] == "arc")["default"] == 301
    assert release["catalogueEntries"] == len(groups) + sum(
        effect["family"] in (0, 3) for effect in catalogues[0]
    )
    for relative in (
        "mac-5.0-redesign/resources",
        "mobile/android/app/src/main/assets",
    ):
        assert (
            json.loads((ROOT / relative / "catalogue.json").read_text(encoding="utf-8")) == groups
        )
    for folder in ("tools", "app", "mac-5.0-redesign", "mobile/tools", "tests"):
        for path in (ROOT / folder).rglob("*.py"):
            if "build" not in path.relative_to(ROOT).parts:
                ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    assert not (ROOT / "mac").exists(), "Old desktop fork must be archived"
    for directory in ("app", "tools", "mobile/tools", "mobile/shared"):
        for source in (ROOT / directory).rglob("*"):
            if source.suffix in (".py", ".h", ".cpp", ".slang") and source != Path(__file__):
                assert "mac/core" not in source.read_text(), source
    for filename in ("README.md", "docs/使用指南.md", "docs/开发指南.md", "docs/验证矩阵.md"):
        assert (ROOT / filename).is_file(), filename
    reference = json.loads((ROOT / "app/resources/PRReference.json").read_text(encoding="utf-8"))
    assert not reference["source"].startswith("/")
    assert all(
        not media.get("originalPath", "").startswith("/") for media in reference["media"].values()
    )
    print(
        f"Source/version/license checks passed for {release['version']}: {', '.join(active)}. "
        "Platform releases are versioned independently."
    )


if __name__ == "__main__":
    main()
