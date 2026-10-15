R05 T15 补测远端工作根（2026-10-16）
- m1-disasm/  : M1 未修(bd84ee9c…)/已修(1849821e…) measure 的 objdump -d 原件与按函数切出的指令字节
- m2-disasm/  : M2 未修(dd4073ba…)/已修(c48f89a5…) measure 的 poly_frommsg / indcpa_enc / dec 反汇编原件
- m2-ctgrind/ : M2 秘密标记 Memcheck 探针（源码、构建日志、16 次运行日志、run-log.txt）
- binsec-m5/  : M5 重加密 Binsec checkct 尝试（A/B/B2/B3/B4/C 六份实验输出与配置）
- tmp/ cache/ : 本轮的显式 TMPDIR 与 XDG_CACHE_HOME，物理路径均在本根内
本根不修改任何既有证据目录，不 sudo，不跑锁频。
