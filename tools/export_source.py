"""Create a source-only GitHub checkout without local media, caches or signing keys."""

import argparse
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOLDERS = (
    "app",
    "assets",
    "mac-5.0-redesign",
    "lite",
    "mobile/android",
    "mobile/android-core",
    "mobile/shared",
    "mobile/vendor",
    ".github",
    "LICENSES",
    "tests",
    "tools",
    "mobile/tools",
    "docs",
)
FILES = (
    "LICENSE",
    "LICENSE.en.txt",
    "README.md",
    "README.en.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "CHANGELOG.md",
    "NOTICE.md",
    "THIRD_PARTY.md",
    "release.json",
    ".gitignore",
    ".gitattributes",
    "requirements.txt",
    "requirements-build.txt",
    "requirements-dev.txt",
    "requirements-compact-build.txt",
    "pyproject.toml",
    "Makefile",
    "tests/benchmark/source.mp4",
    "lite/assets/example.mp4",
    "tools/build_desktop.py",
    "tools/prepare_desktop.py",
    "tools/sync_open_source.py",
    "tools/verify_source.py",
    "tools/export_source.py",
    "tools/build_open_shaders.py",
    "tools/check_freeze_spacing.py",
    "tools/check_desktop.py",
    "tools/check_ui.py",
    "mobile/dependencies.json",
    "mobile/README.md",
    "mobile/tools/get_jcodec.py",
)
FILES += (
    "mobile/tools/prepare_stable_deps.py",
    "mobile/tools/build_android_stable.py",
    "mobile/tools/sync_android_stable.py",
    "mobile/tools/build_android.py",
    "tools/package_windows_open.py",
    "mobile/tools/get_android_tools.py",
    "mobile/android-release.json",
    "mobile/tools/build_stable_test.py",
    "mobile/tests/StableInstrumentation.java",
    "mobile/tests/UiDesignInstrumentation.java",
    "mobile/tests/StableManifest.xml",
    "mobile/tests/PhysicalInstrumentation.java",
    "mobile/tests/UiReviewInstrumentation.java",
    "mobile/tests/HdrInstrumentation.java",
)
EXCLUDE_DIRS = {
    "build",
    "dist",
    "legacy",
    ".venv",
    ".ruff_cache",
    ".pytest_cache",
    "__pycache__",
    ".git",
    ".gradle",
    ".cxx",
    ".idea",
    "xcuserdata",
    "jniLibs",
    "libs",
}
EXCLUDE_SUFFIXES = {
    ".log",
    ".pyc",
    ".pyo",
    ".pyd",
    ".so",
    ".dylib",
    ".dll",
    ".exe",
    ".apk",
    ".ipa",
    ".jar",
    ".keystore",
    ".jks",
    ".p12",
    ".pem",
    ".key",
    ".mobileprovision",
    ".mp4",
    ".mov",
    ".nef",
    ".backup",
    ".v1",
}


# 组织此入口的初始化、主流程和退出清理。
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--destination", type=Path, required=True)
    args = parser.parse_args()
    output = args.destination.resolve()
    if output.exists() and any(output.iterdir()):
        raise ValueError(
            "Destination must be empty; stale files would invalidate a source release."
        )
    output.mkdir(parents=True, exist_ok=True)
    selected = {ROOT / name for name in FILES}
    for folder in FOLDERS:
        for path in (ROOT / folder).rglob("*"):
            relative = path.relative_to(ROOT)
            if relative.parts[:2] == ("app", "tests"):
                continue
            if any(part in EXCLUDE_DIRS for part in relative.parts):
                continue
            if path.is_file() and path.suffix.lower() not in EXCLUDE_SUFFIXES:
                if path.name not in (".DS_Store", "local.properties"):
                    selected.add(path)
    for source in sorted(selected):
        if not source.is_file():
            raise FileNotFoundError(source)
        if source.is_symlink():
            raise ValueError(f"Source-only export requires regular files: {source}")
        relative = source.relative_to(ROOT)
        target = output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    manifest = {
        str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(selected)
    }
    (output / "SOURCE_SHA256.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"{len(manifest)} source files prepared at {output}")


if __name__ == "__main__":
    main()
