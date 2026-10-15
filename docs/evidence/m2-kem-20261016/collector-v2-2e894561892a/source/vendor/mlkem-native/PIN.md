# mlkem-native 固定快照（M5）

- 上游：[pq-code-package/mlkem-native](https://github.com/pq-code-package/mlkem-native)。
- 完整提交：`b3ba7b32773e657dd37f6f87bce82528459ad8a4`；根 Git tree：
  `4cb8a67933a7f357e0f7b0dd45c0c6916050038d`。
- 作者时间：2026-09-21 07:50:12 UTC；提交者时间：2026-09-22 03:22:27 UTC。
- 既有导入范围是上游完整 `mlkem/` 库目录与根 `LICENSE`，共 126 个普通文件；
  本目录不是上游全仓库 clone，不包含其 proofs/test/dev 全部材料。
- 2026-10-16 从固定提交的 [GitHub 源码归档](https://codeload.github.com/pq-code-package/mlkem-native/tar.gz/b3ba7b32773e657dd37f6f87bce82528459ad8a4)
  重新逐文件核对：126/126 字节相同，无缺失、额外或修改文件。新增此 PIN 不算上游文件。
- 该次归档 SHA-256：`6a0dbe157c3cc94f79bc6a6c79ad53707600c40885f16107205a2a2836d81caa`。
  快照清单 SHA-256：`b451e5ca0c897f7ae7249b954f4f10ab0863e6af509141a29fb3b65b125a377f`。
  核验结果与每文件摘要见 `docs/evidence/m5-mlkem-native-20261016/`。
- [上游 LICENSE](https://github.com/pq-code-package/mlkem-native/blob/b3ba7b32773e657dd37f6f87bce82528459ad8a4/LICENSE)：
  库源码 Apache-2.0 OR ISC OR MIT，文档 CC-BY-4.0；逐文件 SPDX 与版权保持原件。
  [固定版本 SOUNDNESS](https://github.com/pq-code-package/mlkem-native/blob/b3ba7b32773e657dd37f6f87bce82528459ad8a4/SOUNDNESS.md)
  是上游声明入口，不将它当作本项目已完成的形式化或恒时认证。

使用 [FIPS 203](https://csrc.nist.gov/pubs/fips/203/final) ML-KEM-768、便携 C 后端与内置便携
FIPS202；`include/baseline_config.h` 固定参数 768、命名空间 `baseline_native`、关闭上游随机 API。
普通封装调用系统安全随机源；确定性接口仅用于明确测试。功能资格不表示取得 FIPS 模块认证。

M5 复用根 CMake 的 `mlkem_reference` 静态库、`reference_baseline` 和 `reference_measure`；
`src/kernel.c` 直接包含此快照的 `mlkem_native.c`，参考路径不应用实验补丁。
人工机制变体各自在构建目录准备副本，不能把它们当作 M5。
平台接线见 `cmake/PlatformM5.cmake`，构建与验证见 `docs/evidence/m5-mlkem-native-20261016/RESULT.md`。
