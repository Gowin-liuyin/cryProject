# G2计时描述C11增量的软件资格

2026-10-10。本目录首次新建，旧run-0ba4cd7原件、结果、49页报告及925项包保持。C源81565a45、CMake57c4060a，在旧严格解析/校验/窗口链之后新增描述模式；旧61个非入口函数逐字保持。合同SHA eb2d57f2是在真实分布分析前冻结，实际本机CPU/编译器/输入与空间预检通过。

`software-qualification.zip`原字节保存首轮452份载荷和修复20份载荷及各自manifest。普通CTest2/2；动态初次因额外detect_leaks=1被macOS运行库在测试体前拒绝，原始失败保持。修复只将该选项关为0，使用同一动态产物、原CMake生成的两项CTest注册；在新CTest日志根运行，避免覆盖首次失败。修复后2/2，不宣称LSan覆盖或最初已通过。

普通新产物旧模式normal退出0、parent-loss退出1，四CSV/JSON与冻结结果逐字一致；只读stdout描述符的纯fixture退出1，目标文件不变。初452份manifest前后保持，两源与普通/动态Mach-O原字节保持。完整命令、环境、退出、输入前后摘要和二进制在归档内。

静态独立审查针对实际C/CMake/合同，未执行C；README的SIGPIPE文案建议已单独收紧，未改C源。根format-check、clang-format21和diff检查通过。软件资格不是新描述结果：此时真实 `--timing-description` 运行0，新密码调用0、硬件采集0、SSH0；R02/R04仍partial。
