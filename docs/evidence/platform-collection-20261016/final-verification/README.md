# 平台全量构建与 CTest 复核（2026-10-16）

命令（逐字）：

```sh
cmake -S . -B build/final-verify -DBASELINE_ENABLE_PLATFORM=ON \
      -DA113_ARCHIVED_CASE_ONLY=OFF -DOPENSSL_EXECUTABLE=/Users/yin/miniconda3/bin/openssl
cmake --build build/final-verify --parallel 4
ctest --test-dir build/final-verify --output-on-failure
```

结果：**100% tests passed, 0 tests failed out of 87**，总耗时 40.21 s。
标签分布：`platform_m3` 6、`reference` 5、`software_only` 6、`stats` 1，其余为既有交付测试。

这一遍覆盖了本轮新增的全部平台目标（M2 collector、M3 on/off、M4 measure/dudect/formal、
M5 poison/dudect、`platform_stats`、`platform_holm`、统计电池、Mona 接线），
因此它与平台关闭配置的 57/57 一起构成"普通 + ASan/UBSan + 平台开"三组复核。

`-DOPENSSL_EXECUTABLE` 指向 OpenSSL 3.5.5：本机默认 `/usr/bin/openssl` 是 LibreSSL 3.3.6，
不支持 `dgst -sha3-256`，会让 `native_digest` 失败（56/57）。该前置条件已由本目录的
`../../build-20261016/BUILD.md` 记录，并本轮追加了配置期能力探测。
