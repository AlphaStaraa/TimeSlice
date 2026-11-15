# 第三方对应源码

FFmpeg9.0.2、x264、pkgconf归各自作者所有。来源与固定SHA256见build.json；源码归档保留上游许可。FFmpeg本配置启用GPL组件，与x264一起作为独立命令行工具随应用分发。

运行 `python tools/build_lite_ffmpeg.py` 会校验随附归档，在项目build目录编译依赖和视频工具；不安装到系统。macOS部署目标14.0。设置或源码变更后可用 --rebuild 重编译。build.json中的${PROJECT_ROOT}表示构建时项目路径。
