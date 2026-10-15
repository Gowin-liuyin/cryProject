# M3 人工 LUT 前置交付

**定位：** 在 nss-m x86_64、GCC 13.3、系统 Valgrind 3.22.0 的固定产物上，人工开版本的秘密查表地址 `mem_lut.c:277` 报 `32 errors from 1 contexts`、退出 `97`；固定扫描关版本为 `0 errors from 0 contexts`、退出 `0`。反汇编分别保留秘密字节索引和公开 `0..255` 扫描。Microwalk/Pin 尚不可用。

**统计：** 本轮未采集时间 CSV，也未运行 CI/Welch、RTLF、Holm 或 dudect；普通与 sanitizer 的功能测试通过不能替代时序统计，开关跨版本性能差异也不是秘密类对证据。

**边界：** 这是人工构造的校准夹具，独立于 ML-KEM 解封装，无密钥恢复；关版本的单次动态无报警不构成恒时证明，结果仅适用于记录的源码、编译器、ISA 和测试路径。M1、既有 vendor 与结论文件未改。

| 检查 | 结果 | 原始材料 |
|---|---|---|
| macOS/ARM 普通自检 | 2/2 | `local/ordinary-ctest.txt` |
| macOS/ARM ASan/UBSan | 2/2 | `local/sanitize-ctest.txt` |
| hook 编译与执行保护 | 编译通过；非 Valgrind 执行返回 77 | `fixtures/mem_lut_leak/README.md` |
| Linux x86_64 普通自检 | 2/2 | `native-idAExSCX/logs/ctest.txt` |
| 开版本秘密地址报警 | 32 次 / 1 站点，exit 97 | `native-idAExSCX/logs/on-valgrind.txt` |
| 关版本对照 | 0 次 / 0 站点，exit 0 | `native-idAExSCX/logs/off-valgrind.txt` |
| C / CMake 格式 | clang-format 21、cmakelang 0.6.13 通过 | 固定格式工具直接检查本路文件 |

源码位于 `fixtures/mem_lut_leak/`；计划、环境及工具阻塞分别见 [PLAN](PLAN.md)、[ENV](ENV.md)、[NOTES](NOTES.md)。远端原件保留在 Cry 新目录，本路未进行任何频率或隔离配置写入。
