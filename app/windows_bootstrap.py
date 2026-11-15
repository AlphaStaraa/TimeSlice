"""在 Qt 导入前处理 Windows UTF-8 与深层解压路径，只使用标准库。"""

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

RUNTIME_FOLDERS = ("app", "assets", "runtime", "_internal")
READY_FILE = ".timeslice-runtime.json"


def filesystem_path(path):
    """Windows 文件复制使用扩展路径，避开旧 Win32 MAX_PATH 文件接口限制。"""
    if os.name != "nt":
        return path
    value = str(path.resolve())
    if value.startswith("\\\\?\\"):
        return path
    return Path("\\\\?\\UNC\\" + value[2:] if value.startswith("\\\\") else "\\\\?\\" + value)


def package_files(root):
    """列出应用运行文件，避开用户另放的素材、结果及临时文件。"""
    selected = []
    for folder in RUNTIME_FOLDERS:
        base = root / folder
        if not base.is_dir():
            continue
        for path in base.rglob("*"):
            if "__pycache__" in path.parts or path.is_symlink():
                continue
            if path.is_file() and path.suffix not in (".pyc", ".log", ".partial"):
                selected.append(path)
    for path in root.iterdir():
        if path.is_file() and (
            path.suffix.lower() in (".exe", ".dll", ".pyd", ".json")
            or path.name in ("LICENSE", "README.md", "THIRD_PARTY.md")
        ):
            selected.append(path)
    return sorted(set(selected))


def needs_short_path(root, files):
    """用实际运行文件的最长路径判断，保守留出 Qt 的额外路径余量。"""
    return any(len(str(path)) >= 235 for path in files)


def runtime_key(root, files):
    """文件列表、大小和修改时间变化会生成新缓存，避免升级后仍打开旧代码。"""
    digest = hashlib.sha256(str(root).encode("utf-8"))
    for path in files:
        stat = path.stat()
        digest.update(f"{path.relative_to(root)}:{stat.st_size}:{stat.st_mtime_ns}".encode("utf-8"))
    return digest.hexdigest()[:16]


def prepare_runtime(root, cache_base):
    """需要时原子建立短路径运行副本，源程序和额外用户文件保持在原位置。"""
    root = root.resolve()
    files = package_files(root)
    if not files:
        raise ValueError("未找到完整的程序运行文件")
    cache_base = cache_base.resolve()
    if root.is_relative_to(cache_base) or not needs_short_path(root, files):
        return root
    key = runtime_key(root, files)
    target = cache_base / key
    if (target / READY_FILE).is_file():
        return target
    if target.is_relative_to(root):
        raise ValueError("运行缓存不能建在原程序目录内部")
    cache_base.mkdir(parents=True, exist_ok=True)
    size = sum(path.stat().st_size for path in files)
    if shutil.disk_usage(cache_base).free < size + 128 * 1024**2:
        raise OSError(f"首次运行准备需要约 {size // 1024**2 + 128} MB 可用空间")
    temporary = Path(tempfile.mkdtemp(prefix=key + "-", dir=cache_base))
    try:
        for path in files:
            destination = temporary / path.relative_to(root)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(filesystem_path(path), filesystem_path(destination))
        (temporary / READY_FILE).write_text(
            json.dumps(dict(source=str(root), key=key, files=len(files)), ensure_ascii=False),
            encoding="utf-8",
        )
        try:
            temporary.rename(target)
        except OSError:
            if not (target / READY_FILE).is_file():
                raise
        return target
    finally:
        if temporary.exists():
            shutil.rmtree(temporary, ignore_errors=True)


def ensure_windows_runtime(module_file):
    """默认启动自动采用 UTF-8 和短运行目录，在 Qt/PySide 初始化前完成。"""
    if sys.platform != "win32":
        return
    frozen = bool(getattr(sys, "frozen", False))
    root = (
        Path(sys.executable).resolve().parent if frozen else Path(module_file).resolve().parents[1]
    )
    embedded = root / "runtime" / Path(sys.executable).name
    cache = (
        Path(os.environ.get("LOCALAPPDATA", str(Path.home() / "AppData/Local"))) / "TimeSlice" / "r"
    )
    try:
        target = prepare_runtime(root, cache) if frozen or embedded.is_file() else root
        if target == root and (frozen or sys.flags.utf8_mode):
            return
        if frozen:
            command = [str(target / Path(sys.executable).name), *sys.argv[1:]]
        else:
            executable = target / "runtime" / Path(sys.executable).name
            if not executable.is_file():
                executable = Path(sys.executable)
            script = target / "app" / Path(module_file).name
            command = [str(executable), "-X", "utf8", str(script), *sys.argv[1:]]
        subprocess.Popen(
            command,
            cwd=target,
            env=dict(os.environ, PYTHONUTF8="1", PYINSTALLER_RESET_ENVIRONMENT="1"),
            creationflags=0x08000000,
        )
        raise SystemExit(0)
    except (OSError, ValueError) as error:
        import ctypes

        ctypes.windll.user32.MessageBoxW(None, "时刃启动准备失败：\n" + str(error), "时刃", 0x10)
        raise SystemExit(1) from error
