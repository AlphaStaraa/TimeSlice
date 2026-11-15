import json
import platform
import sys
import traceback
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
report = {
    "python": sys.version,
    "platform": platform.platform(),
    "architecture": platform.machine(),
}
try:
    from PySide6.QtCore import qVersion

    report["qt"] = qVersion()
    import numpy as np
    from core.engine import CPUEngine, GPUEngine
    from model import BY_ID, DEFAULTS, params

    cpu = CPUEngine()
    p = params(BY_ID[100], DEFAULTS, 64, 64, 0.65, 20, 100)
    a = cpu.field(p, 64, 64)
    report["cpu"] = {"device": cpu.label, "finite": bool(np.isfinite(a).all())}
    cpu.close()
    try:
        gpu = GPUEngine()
        b = gpu.field(p, 64, 64)
        report["gpu"] = {"device": gpu.info, "difference": float(np.abs(a - b).max())}
        gpu.close()
    except Exception:
        report["gpuError"] = traceback.format_exc()
    from media import choose_encoder, ffmpeg

    report["encoder"] = choose_encoder()
    report["ffmpeg"] = ffmpeg()
except Exception:
    report["error"] = traceback.format_exc()
try:
    path = ROOT.parent / "时刃诊断.json"
    path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf8")
    print("诊断文件：", path)
except OSError:
    pass
print(json.dumps(report, ensure_ascii=False, indent=2))
