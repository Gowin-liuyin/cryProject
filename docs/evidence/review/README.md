# 风格整理和代码审查后的实测证据

功能源码：b9a758fc3f16b9b7292543abd3c2ae6967c21f2a。
构建时工作区干净；源码整理及两项测试校验修复已提交，后续仅增加 README 和审查归档。
平台为 Apple M5 ARM64 macOS，Apple Clang 21，CMake/Ninja RelWithDebInfo。

ctest.log 和 sanitize-ctest.log 分别记录 9 项功能检查与独立动态检查通过。
format-check.log、源码格式配置和审查记录说明格式核验方法。
reference.csv / vulnerable.csv 各 100 次（五类各 20），仅作为当前产物采集能力的验证。
.meta、compile_commands.json、binaries.sha256 与 record-checks.txt 可核对源码、选项及文件摘要。

vulnerable-path-arm64.txt 来自同一采样文件：
0x100000cfc 起点读钟，0x100000d1c 完整解封装调用，0x100000d28 终点读钟。
编码入口 0x100002690，+0x48（0x1000026d8）的 tbz 仍由解密消息位控制。
文件 I/O 在整批计时循环后。以上地址只对应本组摘要，不跨构建复用。

未作显著性检验；已确认目标机制并采集原始数据，时间差异尚未正式统计确认。
