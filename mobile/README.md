# Android

当前为1.0.5 HDR预览版，独立版本由 [android-release.json](android-release.json) 维护。
只接收视频，保留切片调整、视频处理和导出；不再提供照片序列流程。

- [使用指南](../docs/使用指南.md)：导入、参数、输出与手机负载提示。
- [开发指南](../docs/开发指南.md)：Android构建方法。
- [验证矩阵](../docs/验证矩阵.md)：真机覆盖范围与限制。

`android/`为界面，`android-core/`为JNI入口，`shared/`为着色器生成入口。
Android使用`app/core/`的共享时间场。签名密钥、SDK、NDK和本地构建结果不参与源码发布。
模拟器结果不能代替实体设备性能或发热测试。
