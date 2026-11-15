# 第三方组件

当前开发版本的自有代码采用 AGPL-3.0-only，官方版本免费；AGPL 允许商业使用和收费分发。以下第三方组件保留各自版权和许可，历史发行版的既有授权不变。

| 组件 | 用途 | 许可与上游 |
|---|---|---|
| PySide6 / Qt | 桌面界面 | LGPL-3.0 / GPL-3.0 / 商业许可，动态链接。https://code.qt.io/pyside/pyside-setup.git/ 和 https://code.qt.io/qt/ |
| CPython | 桌面运行时 | Python Software Foundation License。https://www.python.org/downloads/source/ |
| NumPy | 数组计算 | BSD-3-Clause。https://github.com/numpy/numpy |
| Pillow | 图像处理 | MIT-CMU。https://github.com/python-pillow/Pillow |
| wgpu-py / wgpu-native | 桌面 GPU | BSD-2-Clause / MIT / Apache-2.0，按对应包许可。https://github.com/pygfx/wgpu-py 和 https://github.com/gfx-rs/wgpu-native |
| rendercanvas | GPU 集成 | BSD-2-Clause。https://github.com/pygfx/rendercanvas |
| imageio-ffmpeg | FFmpeg 调用与二进制 | Python 包 BSD-2-Clause，FFmpeg 按具体构建的 LGPL/GPL。https://github.com/imageio/imageio-ffmpeg |
| FFmpeg | 视频解码和编码 | 此环境随 imageio-ffmpeg 的构建启用 GPL 编码组件。https://ffmpeg.org/download.html 和 https://github.com/imageio/imageio-binaries |
| OpenCV | 画面稳定和图像处理 | Apache-2.0，包含的第三方库按其各自许可。https://github.com/opencv/opencv-python 和 https://github.com/opencv/opencv |

Mac完整版1.0.1使用从OpenCV 4.13.0源码编译的精简模块，保留core/imgproc/flann/features2d/calib3d/video/Python绑定，视频读写仍由原FFmpeg承担。源码地址与SHA256见`mac-5.0-redesign/compact-opencv.json`，对应Apache许可在`LICENSES/OpenCV-4.13.0.txt`，构建脚本为`tools/build_compact_opencv.py`；不更改开发环境及Windows所用官方wheel。

Mac完整版1.0.2保留上述OpenCV模块，并从固定源码编译精简FFmpeg9.0.2，启用广泛原生解码器与dav1d1.5.1软件AV1解码、libx264及VideoToolbox编码。禁用网络协议，面向本地文件。构建入口`tools/build_full_ffmpeg.py`，源码锁`mac-5.0-redesign/full-ffmpeg-source.json`；FFmpeg/x264/pkgconf对应源码归档随`lite/vendor/`提供，dav1d归档在`mac-5.0-redesign/vendor/`。dav1d使用BSD-2-Clause许可（https://code.videolan.org/videolan/dav1d），精简工具的GPL/LGPL及dav1d许可也随应用附带。Windows仍使用其原已验证的视频工具，不能套用Mac裁剪结果。
| JCodec 0.2.5 | Android 兼容编码 | BSD-2-Clause，许可在 Android assets/JCODEC-LICENSE.txt。https://github.com/jcodec/jcodec/tree/v0.2.5 |
| Slang | 着色器生成工具 | Apache-2.0 WITH LLVM-exception 及上游第三方声明。https://github.com/shader-slang/slang |
| PyInstaller | 桌面打包工具 | GPL-2.0-or-later，附启动器分发例外。https://github.com/pyinstaller/pyinstaller |

桌面 Python 依赖精确版本见 requirements.txt 和 requirements-build.txt。Android JCodec 下载版本和 SHA256 见 mobile/dependencies.json。生成后的 WGSL、GLES 和 Metal 着色器随源码提供，对应方程在 app/core/field_common.h、mac-5.0-redesign/core/ 和 mobile/shared/gpu.slang。

分发二进制时应在同一发布位置提供本版本完整源码包。分发包含 GPL/LGPL 的第三方二进制时，还应提供该具体构建要求的对应源码、构建脚本及修改记录；上游项目首页不能代替这些内容。发布者应按实际打包依赖核对，保留每个依赖包附带的 LICENSE / COPYING / NOTICE。

项目不把第三方组件或原始摄影素材的版权归给 AlphaStar。用户自己的输入与输出文件不受本项目软件许可约束。
