# Windows 1.0.8 预览

保留RGB10、PQ和HLG预览修复，增加Windows GPU长源有界文件读取及8MB流式HDR峰值扫描。完整20秒4K60 PQ生产路径已完成首轮验证；原生编码PQ输入和最终包补验范围见docs/HDR内存优化_1.0.8.md。

支持推荐/自定义1–500 Mbps码率和平滑渐变。此版本已交叉构建x64启动器与原生内核，本轮尚待Windows实机验证；旧版验收不能代替本版结果。

完整解压发布包后运行时刃.exe；显卡不兼容时使用 CPU兼容模式.cmd。
当前使用、构建与验证说明见根目录 README.md 和 docs/。Windows 与 Mac 共用本目录实现。
实机启动和完整导出验证必须分别记录，不以 PE 静态检查代替运行。
AlphaStar · 免费开源 · AGPL-3.0-only。

新增HEVC Main10 SDR、PQ、HLG输出，自动核验实际SPS位深。支持取决于所选编码器，未实机的范围保持明确标注。
