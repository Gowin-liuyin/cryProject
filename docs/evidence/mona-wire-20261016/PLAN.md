# Mona 离线对照计划（2026-10-16）

本路只处理既有时间数据，不产生新的密码算法计时，不写频率或亲和性配置。
固定 `mona-timing-report@4c74fb7e629b4d057b2d5d4accdb120d920774b7`，使用其
`StatisticEvaluation.calibrationPhase`、`BoxTest`、`BoxTestResults` 原始实现。
独立适配器仅严格解析输入、关闭图形/PDF回调并导出结果，不修改上游源码。

先构建全部上游 Java 源及适配器；依赖仅用快照内 JAR。CMake 为唯一构建与
CTest 配置来源，不运行上游 demo、网络客户端或攻击样例。

执行顺序：

1. 固定相等分布合成两类，1000 行/类，期望无 optimal box。
2. 固定大位移合成两类，1000 行/类，期望上游找到并验证箱体分离。
3. 校准通过后，依次回放 M1 既有 vulnerable/fixed 的双列 CSV，保留全量值，
   不裁剪长尾。主回放来自 `tooling-strengthen-20261015/csv/`；另外回放
   `r02-r04-close-20261016/raw/seed-424242/csv/` 与 `raw/cpu-6/csv/`。
4. M2 数据由主控采集完成后走同一接口；本路不提前制造或声称 M2 统计结果。

输入支持 S5 `V1,V2` + X/Y 的长表，及严格两列非负整数 ns 宽表。
每类至少 100 值；保留输入副本、SHA-256、类内输入顺序及上游输出 CSV。
运行失败必须保存错误与退出码，不用替代算法生成 Mona 结果。

Mona 使用自适应最优箱体搜索与批次验证。其输出名为 `Confidence Interval`
的字段实际为批次成功率；不解释为覆盖概率、显著性水平或 p 值，不进入 Holm。
`validated_separation` 只表示此实现本次找到并通过箱体规则；无分离不证明恒时。
结果仅作补充对照，不推翻或改写既有 M1 结论。

远端唯一路径为 `/home/nss-marker/yhr/Cry/platform-mona-20261016-<nonce>`，
原件、JDK（若需）、缓存、临时文件与归档均位于该物理树或 Cry 内同级归档。
不安装系统包，不用 Docker；Java 禁用 perf 临时目录并显式指定临时路径。
普通 Linux 离线运行不占用主控 CPU2/6；无需锁频，不称硬件采数。

上游 primary 资料：

- [report README](https://github.com/seecurity/mona-timing-report/blob/4c74fb7e629b4d057b2d5d4accdb120d920774b7/README.md)
- [统计实现](https://github.com/seecurity/mona-timing-report/blob/4c74fb7e629b4d057b2d5d4accdb120d920774b7/src/de/fau/pi1/timerReporter/evaluation/StatisticEvaluation.java)
- [许可证目录](https://github.com/seecurity/mona-timing-report/tree/4c74fb7e629b4d057b2d5d4accdb120d920774b7/license)
- [库 README](https://github.com/seecurity/mona-timing-lib/blob/81e4de2971a5b379eb60fb4218e8ff771c554a1b/README.md)

上游程序本体没有明确许可证声明；本路记录获取与本地构建，不分发上游源码或
JAR。Commons Lang/ini4j 声明 Apache-2.0，JSAP 文件声明 LGPL 未指定版本。
