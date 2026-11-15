"""裁剪桌面未选择的Qt样式，删除前核对保留二进制的动态依赖。"""

import argparse
import json
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

STYLES = {
    "FluentWinUI3": "FluentWinUI3",
    "Imagine": "Imagine",
    "iOS": "IOS",
    "Material": "Material",
    "Universal": "Universal",
}


def remove(path):
    """只移除明确列出的包内路径，兼容数据和二进制之间的符号链接。"""
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def byte_size(bundle):
    """统计真实常规文件，避免把资源符号链接重复计算成体积。"""
    return sum(
        path.stat().st_size
        for path in bundle.rglob("*")
        if path.is_file() and not path.is_symlink()
    )


def prune(bundle):
    """保留Basic、原生与macOS样式，只裁剪可证明未被静态依赖的模块。"""
    bundle = Path(bundle).resolve()
    before = byte_size(bundle)
    candidates = []
    framework_names = ["QtQuickControls2" + suffix for suffix in STYLES.values()]
    for area in ("Frameworks", "Resources"):
        qt = bundle / "Contents" / area / "PySide6/Qt"
        for style, suffix in STYLES.items():
            candidates += [
                qt / "qml/QtQuick/Controls" / style,
                qt / "lib" / ("QtQuickControls2" + suffix + ".framework"),
            ]
        candidates.append(qt / "plugins/qmltooling")
    roots = [path.resolve() for path in candidates if path.exists() or path.is_symlink()]
    native = []
    for path in (bundle / "Contents/Frameworks").rglob("*"):
        if (
            not path.is_file()
            or path.is_symlink()
            or any(path.is_relative_to(root) for root in roots)
        ):
            continue
        with path.open("rb") as stream:
            magic = stream.read(4)
        if magic in (b"\xcf\xfa\xed\xfe", b"\xfe\xed\xfa\xcf", b"\xca\xfe\xba\xbe"):
            native.append(path)

    def dependencies(path):
        """检查保留库是否直接链接了计划删除的样式框架。"""
        result = subprocess.run(
            ["otool", "-L", str(path)], text=True, capture_output=True, check=True
        )
        return str(path), [
            name for name in framework_names if name + ".framework/" in result.stdout
        ]

    with ThreadPoolExecutor(4) as pool:
        blocked = [(path, names) for path, names in pool.map(dependencies, native) if names]
    if blocked:
        raise ValueError("Qt style is still required: " + repr(blocked))
    removed = []
    for path in candidates:
        if path.exists() or path.is_symlink():
            removed.append(str(path.relative_to(bundle)))
            remove(path)
    # PyInstaller 还会为框架建立顶层别名，一并移除指向已裁剪框架的悬空链接。
    for path in bundle.rglob("*"):
        if (
            path.is_symlink()
            and not path.exists()
            and any(name in str(path.resolve()) for name in framework_names)
        ):
            removed.append(str(path.relative_to(bundle)))
            path.unlink()
    report = dict(
        beforeBytes=before,
        afterBytes=byte_size(bundle),
        checkedNativeFiles=len(native),
        removed=removed,
        keptStyles=["Basic", "impl", "Native", "macOS", "Fusion"],
    )
    return report


def main():
    """仅操作指定轻量包，结果写在项目构建记录中供复核。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("bundle", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    report = prune(args.bundle)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False))


if __name__ == "__main__":
    main()
