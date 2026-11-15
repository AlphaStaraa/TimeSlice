# 参与开发

欢迎提交问题和改进。当前维护Mac、Windows和Android；代码和自有资源采用AGPL-3.0-only。

先阅读[开发指南](docs/开发指南.md)。Python使用3.11，安装`requirements-dev.txt`，然后运行：

```sh
make check test PYTHON=python
```

修改桌面UI后运行`python tools/check_ui.py`；修改Lite后运行`python tools/build_lite.py`和`python tools/check_lite.py`。修改内核后，在有真实GPU的机器运行`python tools/check_desktop.py --gpu`。无GPU的CI只能证明CPU/文件布局等检查通过。

46种效果的92标准帧是回归基线。修复不能通过重录基线隐藏差异；确需改变效果时，在PR说明具体视觉差异和理由，并使用`tools/golden.py`的显式基线更新参数。

提交前请保持Ruff格式和中文函数说明，运行`python tools/index_functions.py`更新索引。Mac/Windows共用`mac-5.0-redesign/`，Android直接引用共用内核；不要复制出另一份活动分叉。

问题报告请包含系统、CPU/GPU、素材与输出规格、效果参数、复现步骤和错误日志。请移除个人目录、设备标识和不打算公开的素材；能用项目示例复现时优先使用示例。不要提交安装包、缓存、SDK、签名密钥或原始摄影序列。

PR请说明解决的问题、最终行为和已执行的检查。平台未实测时明确注明。提交贡献即表示你有权提供这些内容，并同意按本项目许可分发；不要求转让版权。

English contributions are welcome. Describe the problem, expected behavior and validation in your PR. Run the checks above, preserve the golden baseline unless the visual change is intentional, and state which platforms you actually tested. Do not commit private footage, credentials, build caches or signing keys.
