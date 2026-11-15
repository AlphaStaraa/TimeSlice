import os
import shutil
import subprocess
from pathlib import Path

MAC = Path(__file__).resolve().parent
ROOT = MAC.parent
compiler = os.environ.get("SLANGC") or shutil.which("slangc") or ROOT / "build/slang/bin/slangc"
for entry in ("render", "fields"):
    subprocess.run(
        [
            str(compiler),
            str(ROOT / "app/core/gpu.slang"),
            "-D",
            "SHIREN_MAC42=1",
            "-D",
            "SHIREN_MAC_NEXT=1",
            "-I",
            str(MAC / "core"),
            "-target",
            "wgsl",
            "-entry",
            entry,
            "-stage",
            "compute",
            "-O2",
            "-o",
            str(MAC / "core" / f"{entry}.wgsl"),
        ],
        check=True,
    )
print("Mac-only shaders generated.")
