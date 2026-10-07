# 普通数据成本资格修复

固定修复源：697ddf867dfb1791ebcc4eba4e97f16197be3069。只改变普通记录的证据资格校验，
未改变密码内核、计时窗口、统计数值、种子、阈值或既有封存文件，未新采集正式性能。

修复前，共用普通加载入口读取CSV/meta但遗漏.csv.cost。用原生普通性能目录的18份CSV及
18份meta建立缺成本副本，旧二进制仍返回0并写report_status=complete，见before-missing-cost.report。
before-version.log记录实际旧二进制源码声明d4ed862，而不是本轮开工HEAD；二进制SHA256另存。
这是记录资格缺陷，不是新的密码泄露案例。

新入口复用既有阶段成本读取器，普通路径要求CSV/meta/cost运行编号一致、initial_state=started、
final_state=complete、阶段时刻有序、墙钟等于首尾差、采集窗口不短于逐次时长总和；正式、预热
及结果消费数与CSV相符。meta另要求CLOCK_MONOTONIC、ns及reference_ordinary_v1。
缺文件、partial、错误身份、不足窗口或矛盾计数不能发布完整HTML/性能报告。
旧配对合同的读取字段保持，未通过修复重判旧停止条件。

验证：

- Mac/ARM64普通及ASan/UBSan各32项通过，执行时为28602f4加本模块未提交改动，代码随后原样提交697ddf8；不是原生Linux计时证据。
- 697ddf8固定提交在Mac再做4项相关检查通过；format-check通过。
- 697ddf8全新原生x86_64/KVM检出：GCC13普通、Clang18 ASan/UBSan各32项通过，源身份、注册清单和完整日志见native。
- 两平台均从原封存18套CSV/meta/cost重建性能主表，逐字一致；同样18套CSV/meta缺成本副本返回非零，无complete标志。
- 40份历史报告在Mac逐字复算一致。新失败用例是明确的无秘密解析夹具，不能作为真实误报、检出率或密码总体证据。

可执行复算（在含本修复的新构建中；输出目录/报告不得已存在）：

```sh
cmake -S . -B build/cost-check -DCMAKE_BUILD_TYPE=RelWithDebInfo -DA113_ARCHIVED_CASE_ONLY=ON
cmake --build build/cost-check --parallel 4
ctest --test-dir build/cost-check --output-on-failure
mkdir runs/new-cost-check
build/cost-check/audit performance-replay docs/evidence/native-final-20261007/performance runs/new-cost-check/performance.report
cmp docs/evidence/native-final-20261007/performance/performance.report runs/new-cost-check/performance.report
mkdir runs/new-cost-check/missing-cost-input
cp docs/evidence/native-final-20261007/performance/*.csv docs/evidence/native-final-20261007/performance/*.meta runs/new-cost-check/missing-cost-input/
build/cost-check/audit performance-replay runs/new-cost-check/missing-cost-input runs/new-cost-check/missing-cost.report
```

最后一条必须失败；失败报告不得出现report_status=complete。封存SHA清单应先核对，
字段自洽不证明元数据真实，不替代采集退出码、源码/产物摘要或独立执行。
原生执行仍为作者代理，虚拟机非裸金属。R02/R08/R11科学及非原作者缺口不因此关闭。
