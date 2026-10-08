# M02已有记录的只读复算交接

2026-10-09的固定三次正式进程已经完成，启动前实现提交为 `1ac2033eb16057ee684eedefc6301a0ce6b5b7ed`，合同提交为 `96eba6d0b25d052a836a42b7ed5115615ee4a8d7`。本页只说明重建工具、审计已有原行、重新生成解释输出；以下命令不启动正式观察器，不产生新成本样本，也不覆盖现有记录。

[三进程完成记录](execution/completed.json)、[各进程独立C核验](independent-audits/)、[C跨进程汇总](process-summary.json)保持原身份。汇总的18个非零中位条件及240个时钟合格对是C程序的报告读数，整体范围仍为**一次新构建、同机三个顺序进程、既定六份非零输入**；它不是三个独立构建、独立同分布样本、任务总体或跨平台结论。旧M01没有合并进本轮确认，3/7重复全零任务只保留展示。

## 原实际汇总的来源

实际使用 `build/aris-replication-20261009/summary-normal/process_summary`。二进制SHA256为 `bb34c985ac25d72be098fce2bebc8cce74fc090486b7b2aae7ecae079f6cb8d7`；C源码为 `2e33ede99d082cc37488227022dae96915a90b7f840ef2cfbe3136f3372aa497`，CMake为 `70820a849c8ff5667105df4e61c6529044c6da8f7929ce91db5e9519528feb33`，均在上述实现提交内。它在三进程采集与逐进程C审计之后只读新M02汇总表，退出0。

[汇总命令记录](execution/summary-command.json)是事后交接记录，实际命令、退出码和标准输出来自根的工具执行结果；没有原起止UTC，不把事后记录时间或文件时间写成启动时间。工具等待时长不作为算法或整个进程成本。

## 从固定源码包重新构建

在包含本轮记录的仓库根执行。以下使用macOS/ARM上的CMake、Clang/GCC及系统 `unzip`、`shasum`；原独立C审计器固定核对原记录为Darwin/arm64，不能据此签收Linux测量。新构建的摘要可能因工具链或调试路径改变，不能继承本轮计时产物的资格。

源码包SHA256必须是 `56ad7ece879df934c5be8b740729058063ae214f23081afb04ed1540102fcc24`。下面直接核对这一值；不相同就停止，不用重新给替换文件生成“正确”清单。

```sh
set -eu
repository_root=$(pwd -P)
archive_path="$repository_root/deliverables/support/CACR2026EA16XZ-math-reproduction-20261009/CACR2026EA16XZ-数学源码与账本复核件.zip"
expected_archive_digest=56ad7ece879df934c5be8b740729058063ae214f23081afb04ed1540102fcc24
actual_archive_digest=$(shasum -a 256 "$archive_path")
actual_archive_digest=${actual_archive_digest%% *}
test "$actual_archive_digest" = "$expected_archive_digest"
```

以下新建唯一工作目录，不复用或重置本轮构建树。解压应有原123个文件，内置清单覆盖122项；核对失败即停止。只构建工具，不运行观察器，也不追加软件枚举自检。

```sh
replay_work_root=$(mktemp -d "$repository_root/build/m02-readonly-replay.XXXXXX")
mkdir "$replay_work_root/source"
unzip -q "$archive_path" -d "$replay_work_root/source"
(
    cd "$replay_work_root/source"
    shasum -a 256 -c SHA256SUMS
)
cmake -S "$replay_work_root/source" -B "$replay_work_root/normal" \
    -DBUILD_TESTING=OFF -DUPDATE_COST_SANITIZERS=OFF
cmake --build "$replay_work_root/normal" --parallel 2
cmake -S "$replay_work_root/source/audit" -B "$replay_work_root/audit" \
    -DBUILD_TESTING=OFF
cmake --build "$replay_work_root/audit" --parallel 2
```

普通及审计CMake来自56ad包的固定配置。跨进程汇总使用实现提交已核过的快照；这是新的构建目录，不改已提交源码或原证据。

```sh
cmake -S "$repository_root/docs/evidence/aris-replication-20261009/preparation/summary-source" \
    -B "$replay_work_root/summary" -DBUILD_TESTING=OFF -DSUMMARY_SANITIZERS=OFF
cmake --build "$replay_work_root/summary" --parallel 2
```

## 审计三个已有进程并生成新解释文件

原记录是根下三个直接的 `run-N` 目录；原审计C要求证据根包含 `run/`。以下只在新的工作目录建立符号链接视图，不复制、删除或改写任何原行。审计JSON和C汇总输出均使用新路径；C入口以只创建新文件的方式写入，既有同名输出会被拒绝。

```sh
m02_evidence_root="$repository_root/docs/evidence/aris-replication-20261009"
m02_input_root="$m02_evidence_root/preparation/fixed-inputs"
mkdir "$replay_work_root/audit-views" "$replay_work_root/outputs"
for process_number in 1 2 3; do
    view_root="$replay_work_root/audit-views/process-$process_number"
    mkdir "$view_root"
    ln -s "$m02_evidence_root/run-$process_number" "$view_root/run"
    "$replay_work_root/audit/update_cost_result_review" \
        "$view_root" "$m02_input_root" \
        "$replay_work_root/outputs/process-$process_number-audit.json"
done
"$replay_work_root/summary/process_summary" \
    "$m02_evidence_root" "$replay_work_root/outputs/process-summary.json"
```

每个独立审计核对原结果消费、176行、512校准原值、80比值、计数及输入副本；不再次执行两种完整统计函数。跨进程C程序只读三份 `summary.csv` 并核对schema、18个中位和240资格条件。它不证明目录本身是真实的新进程，也不替代原启动PID、状态、源与产物前后摘要、机器码审查。新JSON是已有数据的复算输出，不是新增实验。各原文件的内容摘要和整体结果签收，以本轮根保存的清单、原日志及独立结果审查为准。

若以后确实需要另一轮成本采集，应另建研究身份和目的、冻结新合同与预算，记录新源/产物/资源/输入/原值及全部失败；不能为更好效果补跑并回填本轮三个固定进程。本页不提供新的正式启动步骤。

## 关联的官方来源补证

本轮已保存[官方潜在勘误工作簿核对记录](../aris-resume-20261009/official-source-check.md)、[机器可读范围](../aris-resume-20261009/official-source-check.json)及[工作簿原件](../aris-resume-20261009/official-source/fips-203-potential-updates.xlsx)。本次取得的工作簿两项条目及固定便携C路径静态适用性已核对；原件范围不能扩大为全标准、全部后端、NIST认证或恒时签收。这条补证与M02纯数学成本记录分别成立，R02/R04真实总体与测量前提仍不由它们关闭。
