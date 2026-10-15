# M4 人工比较夹具：软件准备与定位结果

**案例类型：人工构造，用于校准。** 这不是 CVE 复现、实际 KEM 或密钥恢复；`ct` 只表示实现意图。

1. **定位：** x86_64 Linux / GCC 13.3.0 / RelWithDebInfo / Valgrind 3.22.0 的固定 poison 夹具中，vulnerable 在 `compare_early.c:9`（ELF 偏移 `0x18a0` 的 `je`）报告秘密相关条件跳转，32 errors / 1 context，退出 99；ct 对照 0 errors / 0 contexts，退出 0，末端比较为 `sete`，循环边界仅依赖公开长度。原日志与逐函数反汇编见 `linux-run-250f424b/`。Binsec 未运行，状态 `not_run`。
2. **统计：** 本轮未采集时间值，CI/Welch、Holm、RTLF、dudect 均 `not_run`；功能自检不是统计证据。未来须先冻结并提交 PLAN，再安排单任务锁频采数；dudect 不进 Holm 家族。
3. **边界：** 定位来自固定人工输入的一次 poison 执行，支持该编译产物中目标比较机制的开/关对照；不能推出任意输入下无泄漏、恒时证明、完整解封装结论或统计可区分。不存在物理精度或恒频主张。

| 软件资格 | 结果 |
|---|---|
| macOS/ARM 普通构建，两变体及两抽取 harness | 构建成功，CTest 4/4 |
| macOS/ARM ASan/UBSan 独立构建 | CTest 4/4，无 sanitizer 报告 |
| x86_64 Linux poison 构建 | 构建成功，CTest 4/4 |
| 相等性 oracle | 每变体枚举 0–32 字节长度、全部差异位置、全部 256 替换字节，135201 个内核检查，对照标准库 `memcmp(...) == 0` |
| 封装边界 | 空指针、真实短数组、零长度与 `SIZE_MAX` 长度均在调用内核前拒绝，错误不改输出 |
| 源与证据关联 | v2 完整包、四 ELF 摘要、10 源文件和可读日志均独立核对通过 |
| Binsec | 两环境缺 Binsec/opam/OCaml/solver；脚本与 1–16 字节有界合同已准备，未执行 |

入口、重建命令和可选 poison 使用方式见
[`fixtures/early_reject_memcmp/README.md`](../../../fixtures/early_reject_memcmp/README.md)。
本路未修改顶层 CMake、vendor、M1 或既有证据。
