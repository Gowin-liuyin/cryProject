# M5 完整原生工具入口

只连接既有未打补丁的 `mlkem_reference`。根CMake在平台选项下include
`cmake/PlatformM5Tools.cmake`后：

```sh
cmake -S . -B build/m5 -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF
cmake --build build/m5 --target platform_m5_poison reference_measure
ctest --test-dir build/m5 -R '^platform_m5_' --output-on-failure
```

`platform_m5_poison --self-test`执行2种公开seed×5类的完整decap一致性检查，不读钟。
这不替代独立KAT；同时运行既有reference KAT/边界/随机源测试。

`--poison`必须有编译时Valgrind客户端头且实际处于Valgrind进程，否则返回77。
标记真实PKE秘密key的1152字节与拒绝z的32字节；公开key、公开hash和密文保持defined。
在同一完整调用结束后才定义输出供一致性检查，不打印秘密、验证位或内部消息。
使用固定S3补丁工具分别显式 `--variable-latency-errors=no/yes`，并保留发行版Memcheck基线。
固定工具身份、命令、输入、ELF摘要和未解释命中均须留在新结果目录。

x86_64且钉版dudect存在时额外构建：

```sh
cmake --build build/m5 --target platform_m5_dudect
build/m5/platform_m5_dudect --self-test
```

`--self-test`只执行相同callback的功能比较，不读钟。
只有 `--collect --seed N --raw NEW.csv` 启动原生rdtsc；这一步必须先提交PLAN，并交主控唯一锁频任务执行。
每批10000、最多21批，原上游首批预热、裁剪/高阶检验与t>10规则保持；首次泄漏状态停止。
类顺序由公开seed/batch编号的SHAKE域5确定；同key的零/ff消息密文固定，推断只覆盖固定输入。
输入生成、分配和复制在窗口外；callback仅完整decap、固定输出槽写入和公开索引/状态记录。
整批结束再消费并擦除输出；日志与I/O在窗口外。预算、实际批次/类计数均输出，dudect不进Holm。

新计划与资格/定位原件入口为 `docs/evidence/m5-completion-20261016/`。
本轮不修改旧M1/M5证据，不把动态产物当正式计时产物，不把未检出称为恒时证明。

原生dudect强制独占新raw CSV：整批结束保留每次begin tick、类别、相邻end tick/周期差、预热/正式阶段和原uncropped检验成员标志。
首批原始ticks不受其exec_times排序影响；每批末调用没有下一begin tick，end/duration明确为空，不补造测量。
每批完成后flush；中断时尚未完成的一批可能没有落盘，应按未知/不完整处理。
