# M4 本路验收边界

| 项 | 状态 | 证据 / 剩余 |
|---|---|---|
| 实装固定 Binsec + solver | 完成 | `runtime/`、`formal-v1/*/identity.txt` |
| 同秘密/公开模型的实际形式对照 | 完成 | vulnerable insecure / ct 有界 secure，length 1–16 |
| 完整探索门槛 | 完成 | halt 32/16，pending/cut/discontinued/unknown 均 0 |
| 原函数/新 harness/产物可关联 | 完成 | source tar、符号表、反汇编、源码行、SHA256 |
| 完整人工夹具两类 measure | 软件准备完成 | 32 字节 checked compare，Linux 普通/动态资格各 7/7 |
| 原生在线 dudect | 软件准备完成 | 真上游测量入口已编译，只执行 --describe，未采样 |
| 具体统计计划 | 草案 | 主控仍须冻结提交、控制器、ELF 和实际运行预算 |
| 时序 / CI / Holm / RTLF / dudect | 未运行 | 本路禁止采样；不能填阴性或阳性 |
| 完整 KEM / 任意长度 CT 证明 | 未实现 | 不属于本轮小函数有界结论 |

无密钥恢复或 exploit；既有 M1 vendor、夹具源和已提交证据不改。采数与锁频由主控另阶段串行执行，dudect 不进 Holm。
