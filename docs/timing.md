# 最小原始时间采集

当前 CMake 默认构建的两个入口为 `build/cmake/reference/measure` 和 `build/cmake/vulnerable/measure`：

```sh
mkdir -p runs/example
build/cmake/reference/measure example-reference 42 1000 runs/example/reference.csv runs/example/reference.meta
build/cmake/vulnerable/measure example-vulnerable 42 1000 runs/example/vulnerable.csv runs/example/vulnerable.meta
```

参数依次为 run_id、公开测试种子、每类次数、CSV 路径、元数据路径。
run_id 仅接受字母/数字/下划线/连字符，1–64 字符；每类 1–20000 次，总计五类。
输出必须是新文件，不覆盖已有结果。文件写入失败会返回非零，可能保留部分写入文件；
只有程序返回 0 的运行才可使用。种子用于固定测试密钥和输入，不用于保护真实秘密。

全部密文和标签在计时前生成、分配并按 Fisher–Yates 洗牌；SHAKE256 tag=4 的随机值
经拒绝采样映射到当前范围，顺序跨两版可复现。每类等量，sample_index 是打乱后的序号。
100 次预热不进入 CSV。计时器先检查 10000 次读取不倒退且有进展，再用
CLOCK_MONOTONIC 围绕完整包装层解封装调用计时，单位为纳秒；记录 clock_getres 的实际分辨率。
纳秒是表示单位，不意味着 1ns 测量精度；不用 TSC，也不称为 CPU 周期。
单次窗口含两次读钟间的调用边界及 C11 编译屏障，不扣除计时开销。
窗口外检查公开操作状态、写入内存记录、消费输出，整批结束才进行文件 I/O。
输出消费使用 volatile 累积值而不打印；正式产物的调用须在反汇编中核验。

元数据包含真实 OS/架构/CPU 型号、时钟、预热数、顺序算法、seed、样本总数，
以及程序自行读取运行文件计算的 SHA3-256。构建时嵌入 Git HEAD、工作区状态、
tracked diff SHA-256、各实际构建输入的 SHA-256、编译器和选项。
未跟踪源码也列入构建输入摘要，不能仅凭旧 HEAD 代表未提交构建。
CMake 根据源码和编译选项更新对象，构建身份改变会更新采集程序，避免元数据仍指向旧源码。
配置、CMake 文件和 compile_commands.json 的摘要也进入构建清单。历史 final/ 证据属于原 Make
构建的 e519d94 提交，不能用其中的二进制地址为当前 CMake 产物作证。
默认未固定 CPU 亲和性、频率或后台负载，相关状态如实记录。

普通长尾全部保留。不做离群值删除、均值代替逐次数据、自动安全判定或统计泄露判断。
本阶段采集是软件基线验收；后续统计分析接 CSV/元数据，正式研究应预先规定输入总体、
固定主机条件和确认数据。两种固定消息类在同一密钥下重复相同密文，需考虑缓存及序列效应。
参考版与回归版优化条件不同，两者均值差不能单独证明秘密泄露。
