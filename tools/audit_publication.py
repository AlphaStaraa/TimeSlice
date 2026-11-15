"""检查待发布源码中的私有文件、个人路径、凭据、字体和Git大文件。"""

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

BAD_PARTS = {
    "build",
    "dist",
    ".venv",
    ".ruff_cache",
    "__pycache__",
    ".gradle",
    ".cxx",
    "legacy",
    "维护记录",
    "promo-video",
    "design-review",
    "jniLibs",
    "libs",
}
BAD_SUFFIXES = {
    ".keystore",
    ".jks",
    ".key",
    ".pem",
    ".p12",
    ".mobileprovision",
    ".apk",
    ".ipa",
    ".exe",
    ".dll",
    ".pyd",
    ".so",
    ".dylib",
    ".pyc",
    ".idsig",
    ".nef",
    ".arw",
    ".cr2",
    ".cr3",
    ".raf",
    ".dng",
    ".r3d",
    ".mov",
    ".log",
}
FONTS = {".ttf", ".otf", ".woff", ".woff2", ".ttc"}
PUBLIC_VIDEOS = {"tests/benchmark/source.mp4", "lite/assets/example.mp4"}
TEXT_SUFFIXES = {
    ".py",
    ".cpp",
    ".h",
    ".slang",
    ".java",
    ".qml",
    ".json",
    ".md",
    ".txt",
    ".yml",
    ".yaml",
    ".gradle",
    ".xml",
    ".toml",
    ".c",
    ".rc",
}
PATTERNS = {
    "personal-path": re.compile(
        r"/Users/[A-Za-z0-9][A-Za-z0-9._-]{0,60}/|[A-Za-z]:[\\/]+Users[\\/]+[A-Za-z0-9][A-Za-z0-9._-]{0,60}[\\/]"
    ),
    "private-key": re.compile(r"(?m)^-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "github-token": re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}\b|\bgithub_pat_[A-Za-z0-9_]{40,}\b"),
    "api-token": re.compile(r"\bsk-[A-Za-z0-9_-]{24,}\b"),
}


def files_to_check(root):
    """Git仓库只检查将被上传的已跟踪/暂存文件，干净导出目录检查全部文件。"""
    if (root / ".git").exists():
        raw = subprocess.check_output(["git", "-C", str(root), "ls-files", "-z"])
        names = raw.decode("utf-8").split("\0")
        return [root / name for name in names if name], "git-index"
    return [p for p in root.rglob("*") if p.is_file() or p.is_symlink()], "directory"


def inspect(root):
    """仅报告文件和规则，不将疑似凭据内容写入报告或控制台。"""
    selected, scope = files_to_check(root)
    issues, fonts = [], []
    total, largest = 0, []
    for path in selected:
        relative = path.relative_to(root)
        name = relative.as_posix()
        rules = []
        if path.is_symlink():
            rules.append("symlink")
        if any(part in BAD_PARTS for part in relative.parts):
            rules.append("local-artifact-directory")
        if relative.parts[:2] in (("app", "tests"), ("mobile", "ios")):
            rules.append("private-or-removed-platform")
        if path.suffix.lower() in BAD_SUFFIXES or path.name == ".DS_Store":
            rules.append("private-or-binary-file")
        if path.name == ".env" or path.name.startswith(".env.") or path.name == "local.properties":
            rules.append("local-configuration")
        if path.suffix.lower() == ".mp4" and name not in PUBLIC_VIDEOS:
            rules.append("unapproved-video")
        if path.suffix.lower() in FONTS:
            fonts.append(name)
            rules.append("font-license-needs-review")
        if path.is_file() and not path.is_symlink():
            size = path.stat().st_size
            total += size
            largest.append((size, name))
            if size >= 100 * 1024**2:
                rules.append("github-file-limit")
            if path.suffix.lower() in TEXT_SUFFIXES and size < 8 * 1024**2:
                content = path.read_text(encoding="utf-8", errors="replace")
                rules.extend(rule for rule, pattern in PATTERNS.items() if pattern.search(content))
        if rules:
            issues.append(dict(file=name, rules=sorted(set(rules))))
    return dict(
        passed=not issues,
        scope=scope,
        files=len(selected),
        bytes=total,
        largest=[dict(file=name, bytes=size) for size, name in sorted(largest, reverse=True)[:10]],
        fontFiles=fonts,
        fontPolicy="System UI fonts; no standalone font files redistributed"
        if not fonts
        else "Review required",
        publicVideoFiles=sorted(PUBLIC_VIDEOS),
        issues=issues,
    )


def main():
    """保存待上传范围审计，任何确定的私有文件或资源问题均阻止通过。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    report = inspect(args.source.resolve())
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    digest = hashlib.sha256(args.report.read_bytes()).hexdigest()
    print(f"Publication audit: {report['files']} files, passed={report['passed']}, report={digest}")
    if report["issues"]:
        for item in report["issues"]:
            print(item["file"], ", ".join(item["rules"]))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
