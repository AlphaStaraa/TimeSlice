"""从同一内核生成Mac、Windows和Android着色器。"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    """统一调用当前平台入口，防止旧生成脚本还原已经修复的渲染行为。"""
    compiler = os.environ.get("SLANGC") or shutil.which("slangc")
    if not compiler:
        raise SystemExit("Set SLANGC; generated shaders are already included.")
    environment = dict(os.environ, SLANGC=compiler)
    for source in ("mac-5.0-redesign/build_next_shaders.py", "mobile/tools/sync_android_stable.py"):
        subprocess.run([sys.executable, str(ROOT / source)], check=True, env=environment)


if __name__ == "__main__":
    main()
