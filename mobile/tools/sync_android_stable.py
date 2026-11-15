"""同步Android到已定稿桌面内核。"""

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

R = Path(__file__).resolve().parents[2]
A = R / "mobile/android/app/src/main/assets"
C = R / "mobile/android-core"


def main():
    """生成 Android 的最新时间场与原预览资源，保持统一的参数 ABI。"""
    C.mkdir(exist_ok=True)
    # 直接引用同一份内核，避免移动端复制后漏同步昼夜、角度、阴影与边缘修正。
    (C / "field_common.h").write_text('#include "../../app/core/field_common.h"\n')
    shader_source = C / "gpu.slang"
    shader_source.write_text(
        (R / "mobile/shared/gpu.slang")
        .read_text()
        .replace('#include "field_common.h"', '#include "../../app/core/field_common.h"')
    )
    compiler = (
        os.environ.get("SLANGC") or shutil.which("slangc") or str(R / "build/slang/bin/slangc")
    )
    with tempfile.TemporaryDirectory() as tmp:
        glsl = Path(tmp) / "field.glsl"
        subprocess.run(
            [
                compiler,
                str(shader_source),
                "-D",
                "SHIREN_MAC42=1",
                "-D",
                "SHIREN_MAC_NEXT=1",
                "-I",
                str(C),
                "-I",
                str(R / "mac-5.0-redesign/core"),
                "-I",
                str(R / "app/core"),
                "-entry",
                "fields",
                "-stage",
                "compute",
                "-target",
                "glsl",
                "-profile",
                "glsl_450",
                "-O2",
                "-o",
                str(glsl),
            ],
            check=True,
        )
        body = "\n".join(
            line
            for line in glsl.read_text().splitlines()
            if not line.startswith(("#version", "#line", "layout(row_major)"))
        )
        (A / "field.comp").write_text(
            "#version 310 es\nprecision highp float;\nprecision highp int;\n" + body
        )
    effects = [
        x
        for x in json.loads((R / "app/resources/effects.json").read_text())
        if x["id"] not in (405, 406)
    ]
    effects += json.loads((R / "mac-5.0-redesign/resources/mac42.json").read_text())
    for effect in effects:
        if effect["family"] == 2:
            effect["duration"] = 4
    (A / "effects.json").write_text(json.dumps(effects, ensure_ascii=False, indent=2))
    shutil.copy2(R / "app/resources/catalogue.json", A / "catalogue.json")
    for effect in effects:
        for suffix in (".jpg", ".gif"):
            rel = Path("assets/thumbnails") / (effect["key"] + suffix)
            source = R / "mac-5.0-redesign" / rel
            if not source.exists():
                source = R / rel
            if not source.exists():
                source = A / "thumbnails" / (effect["key"] + suffix)
            destination = A / "thumbnails" / source.name
            if source.resolve() != destination.resolve():
                shutil.copy2(source, destination)
    print("Android shares the 1.0 desktop field; original previews preserved.")


if __name__ == "__main__":
    main()
