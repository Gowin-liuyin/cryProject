# M5 本轮验收与当前门槛

| ID | 要求 | 本路范围 |
|---|---|---|
| M5-01 | 固定上游/portable reference/完整decap与适用独立功能资格 | 复用PIN与reference；本轮新Linux资格 |
| M5-02 | 真正标记PKE秘密与拒绝z；公开key/hash/ciphertext边界清楚 | 新完整harness，非Valgrind运行poison必须拒绝 |
| M5-03 | 普通Memcheck与patched varlat no/yes的真实原生执行 | 本路执行并保留原日志，意外命中如实调查 |
| M5-04 | 普通ELF调用链/反汇编/源和工具摘要 | 本路执行 |
| M5-05 | online dudect原头文件+同message类对，prepare/consume在窗口外 | 本路只构建与不读钟自检 |
| M5-06 | PLAN提交后唯一锁频采数、原CSV/ENV/恢复 | 留主控，不在本路执行 |
| M5-07 | 参数族仅3项Welch；Holm α=.05；RTLF/dudect族外 | PLAN固定，实际数据后由主控复算 |
| M5-08 | 阴性与未知分开，三句RESULT，原证据只读 | 本路动态/资格RESULT；统计未运行 |

所有远端源码、构建、输入、输出、缓存、临时及归档均在新Cry物理子根。
本路不写系统调频/隔离、不占CPU2/6采数、不安装系统包、不push或提交。
