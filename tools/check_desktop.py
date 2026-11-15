"""从当前源码临时构建内核，运行可在新机器复现的数值检查。"""

import argparse
import os
import sys
import unittest
from pathlib import Path

from build_desktop import build_native
from prepare_desktop import ROOT, prepare


def main():
    """默认验证 CPU；显式要求 GPU 时，设备不可用也应报告失败。"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--cpu-only", action="store_true")
    parser.add_argument("--gpu", action="store_true")
    parser.add_argument("--stage", type=Path)
    args = parser.parse_args()
    if args.cpu_only and args.gpu:
        parser.error("--cpu-only 与 --gpu 不能同时使用")
    stage = prepare(args.stage or ROOT / "build/check/stage")
    build_native(stage)
    sys.path.insert(0, str(stage / "app"))
    os.environ["TIMESLICE_TEST_GPU"] = "1" if args.gpu else "0"
    suite = unittest.defaultTestLoader.discover(str(ROOT / "tests"), pattern="test_*.py")
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
