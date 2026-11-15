"""只读设备和主存预算，限制额外源块缓存，不改变分辨率与时间精度。"""

import ctypes
import re
import subprocess
import sys


def available_memory():
    """只读系统可回收主存估算；失败时采用保守预算，不申请管理员权限。"""
    try:
        if sys.platform == "darwin":
            result = subprocess.run(
                ["vm_stat"], capture_output=True, text=True, timeout=2, check=True
            )
            page = int(re.search(r"page size of (\d+)", result.stdout)[1])
            counts = [
                int(re.search(r"Pages " + name + r":\s*(\d+)", result.stdout)[1])
                for name in ("free", "inactive", "speculative")
            ]
            return page * sum(counts)
    except (OSError, ValueError, TypeError, subprocess.SubprocessError):
        pass
    return 0


def source_cache_budget():
    """Metal推荐工作集与可用主存共同限制源块缓存；未知平台采用原分块路径。"""
    if sys.platform != "darwin":
        return 0
    try:
        metal = ctypes.CDLL("/System/Library/Frameworks/Metal.framework/Metal")
        objc = ctypes.CDLL("/usr/lib/libobjc.A.dylib")
        metal.MTLCreateSystemDefaultDevice.restype = ctypes.c_void_p
        device = metal.MTLCreateSystemDefaultDevice()
        if not device:
            return 0
        objc.sel_registerName.argtypes = [ctypes.c_char_p]
        objc.sel_registerName.restype = ctypes.c_void_p
        query = ctypes.CFUNCTYPE(ctypes.c_ulonglong, ctypes.c_void_p, ctypes.c_void_p)(
            ("objc_msgSend", objc)
        )
        release = ctypes.CFUNCTYPE(None, ctypes.c_void_p, ctypes.c_void_p)(("objc_msgSend", objc))
        try:
            recommended = query(device, objc.sel_registerName(b"recommendedMaxWorkingSetSize"))
        finally:
            release(device, objc.sel_registerName(b"release"))
        return min(2 * 1024**3, recommended // 16, available_memory() // 8)
    except (OSError, AttributeError, ValueError):
        return 0
