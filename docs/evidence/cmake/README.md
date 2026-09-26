# CMake 迁移验证证据

真实机器仍为 Apple M5 / ARM64 macOS，CMake 4.3.2、Apple Clang 21。
本目录是构建迁移验证，不替换历史 final/ 的数据。

CMakeLists.txt、CMakePresets.json、cmake/ 和 Makefile 的改动在采样时尚未提交：
两个 .meta 如实记录基础 HEAD、工作区状态、tracked diff 摘要以及所有构建输入摘要。
配置为 Ninja / RelWithDebInfo，sanitizers=OFF；compile_commands.json 保存实际编译命令。
采样后只有文档和证据归档变化，未修改功能/构建代码。

reference.csv / vulnerable.csv 各 50 条（五类各 10），仅验证 CMake 构建的采集能力。
record-checks.txt 包含 C 行数/单位/顺序检查及独立 OpenSSL 二进制摘要。
.meta 中的 executable_digest 可与之直接比对；binaries.sha256 额外记录 SHA-256。

vulnerable-encoder-arm64.txt 来自同一个 vulnerable/measure：
入口 0x100002664，+0x48（0x1000026ac）的 tbz 控制系数写入，消息位分支仍然保留。
未做显著性检验，未宣称观察到可靠时间差异。

sanitizer / multi-config CTest 日志记录各 8 项通过；make-wrapper.log 记录转发构建及测试。
noop-build.log 仅刷新构建身份，未编译对象；patch-rebuild.log 记录补丁依赖触发缺陷内核重建。
