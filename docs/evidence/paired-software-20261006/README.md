# 本轮软件验收与复算夹具（2026-10-06）

本目录只包含ARM64 macOS的软件验证、失败演练和明确标记的合成复算材料。
原生x86_64 Linux前置/开发/确认均未执行，未选择K，不能从本目录得到性能改善声明。

模块日志保留各自实际HEAD和未提交状态；开发中的缺stdio及unused参数编译失败保留为
`module2/m2-build.log`，修正构建另命名。没有覆盖失败日志或回填新提交身份。
`tested-source.sha256`固定自有代码/构建/脚本；正式软件验证的编译命令、构建身份、
实际二进制摘要及反汇编另列。`vendor`、固定向量和此前封存证据不改。

最终普通及ASan/UBSan各实际选择12项：参考KAT、随机失败、CLI、向量解析、向量完整性，
reference_benchmark、batch_measurement、paired_statistics、paired_data、paired_rejections、
paired_runner、paired_prepare。不是28项全部执行，没有调用历史主动机制计时入口。
动态和普通构建独立，软件夹具时间不进入正式收益表。

`synthetic-cohort/`由C测试生成20对、每个假运行6个调用位置，所有时间及成本均为构造值，
文件ORIGIN明确标software_fixture。源提交/产物的全零标识也是构造字段，不是实机身份。
expected.report只用于复算一致性，独立正确性另由手算/恒等式/边界C测试验证。
该报告的最终状态必须是comparison_evidence_insufficient，不能用于原生比较或R12。

核验目录及复算：

```sh
shasum -a 256 -c docs/evidence/paired-software-20261006/SHA256SUMS
sh tools/replay_paired.sh /absolute/analyze_paired \
    docs/evidence/paired-software-20261006/synthetic-cohort /absolute/new-report.txt
```

独立检出作者自复现日志将另存新位置；没有非原作者执行日志。
