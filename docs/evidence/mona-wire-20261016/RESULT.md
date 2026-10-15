# Mona 实接入结果（2026-10-16）

软件接入已完成，实际执行了固定上游统计类。macOS/ARM 与真实 Linux/x86_64 的
构建及 CTest 各 1/1 通过；合成阴性、阳性分别得到无分离、有验证分离，S5 长表
与宽表输出一致，非法 CSV 和覆盖旧输出目录均被拒绝。本路没有采集新硬件时间。

## 既有 M1 数据真实离线回放

六份输入各含 10000 值/类，已与各自 `samples.csv` 中 message-zero/ones 逐值、
按原类内顺序独立核对。没有裁剪、抽样、修正、重标类或调参。

| M1 输入 | 上游验证成功记录 | 失败记录 | 结论 |
|---|---:|---:|---|
| 主数据 vulnerable | 0 | 9 | 无通过验证的箱体分离 |
| 主数据 fixed | 1 | 8 | 有箱体分离，仅剩一个验证子集 |
| seed-424242 vulnerable | 0 | 9 | 无通过验证的箱体分离 |
| seed-424242 fixed | 1 | 1 | 有箱体分离，仅剩一个验证子集 |
| CPU6 vulnerable | 0 | 9 | 无通过验证的箱体分离 |
| CPU6 fixed | 0 | 0 | 未找到最优箱体 |

这是上游 Mona 算法的真实对照，未与既有 M1 检测方向一致。两项 fixed 成功均发生
在迭代扩展子集后只剩一个子集的末轮：主数据 `X<Y` 的 10%–11% 箱体、5120 值；
seed-424242 的 31%–32% 箱体、10000 值。相邻同类子集重叠条件此时没有后续子集可比。
该实现从数据自适应寻找箱体并扩展子集，因此不能把成功记录解释成受控误报率或
上游修复失效；也不能用 vulnerable 无分离推翻既有 M1 统计。这里是工具规则的
独立补充观察，未替换 CI/Welch、Holm、RTLF 或 dudect。

Linux 完整摘要见 `native-qualification/run/m1/m1-mona.csv`；每项保存原始
`box-results.csv`、逐项 `mona-validations.csv`、Mona 日志、输入与源码/字节码摘要。
六份原始输入及 JSON/CSV/Markdown 摘要、逐项验证输出均与本地离线运行逐字一致。

## 定位、统计与边界

**定位：** 本路调用 `StatisticEvaluation.calibrationPhase`、`BoxTest`、
`BoxTestResults`；它是统计对照，不产生新的二进制泄漏定位证据。

**统计：** 完整运行上游自适应箱体搜索、最小子集搜索和批次验证；输出原名
`Confidence Interval` 的字段为批次成功百分比，不是覆盖 CI 或 p 值，不入 Holm。
接口输出 `holm_member=false`、`p_value=null`、`alpha=null`。

**边界：** 无密钥恢复、网络攻击或新硬件采数；无分离不证明恒时。Linux 实测
这里指离线软件构建及数据回放，不是重新测量密码算法或新增独立实验环境。
M2 尚无本路真实对照行，待主控提供已冻结合同下的新数据。

## Linux 原件与准备失败

成功原件根为 `/home/nss-marker/yhr/Cry/platform-mona-20261016-1de26030f145`，
使用主控已核验的共享 SSH，以 `taskset -c 0,1` 启动整个离线构建、校准及回放。
系统 Java 21.0.12.1 已含 `jdk.compiler` 模块但缺 `javac` 命令，因此只在自有
`run/tools/` 建立 Java 编译器启动器，没有安装系统包或下载 JDK。

前三次准备失败原件分别保留于同一 Cry 下的 `platform-mona-20261016-9739782d8827`、
`platform-mona-20261016-91cff524d9c0`、`platform-mona-20261016-8a79566b085d`：
依次为 FindJava 要求未使用的 jar/javadoc、运行时缺跨版本 ct.sym、模块启动器不展开
classpath 通配符。最终自有 CMake 仅要求实际使用的工具、使用 source/target 11 和
显式三个 JAR；上游源码未修改。失败日志可读副本在 `failed-preparation/`。

四树完整原包在成功根的 `originals.tar.gz`，SHA-256 为
`387bbfd7d477ef960d1ca7fdbad77554cffd4549c365c6cc784d87096989ee0e`。
拉回后核对 1317 份清单内原件及四树清单，压缩包没有符号链接；校验记录见
`archive-verification.json`。因原包含许可未明确的上游源码/JAR，本地保存在被本目录
`.gitignore` 排除的 `private-originals/`；可提交日志、输入、摘要按原字节选出。
Java 子进程结束核对为空，未关闭主控共享 SSH，未调频或占用 CPU2/6。

## 复现与交接

本地实际命令：

```sh
cmake -S scripts/platform_mona -B build/platform-mona-local-20261016 -DBUILD_TESTING=ON
cmake --build build/platform-mona-local-20261016 --target platform_mona
ctest --test-dir build/platform-mona-local-20261016 --output-on-failure
sh scripts/platform_mona/run_m1.sh /Users/yin/code/cryProject \
  /Users/yin/code/cryProject/build/platform-mona-local-20261016/platform-mona/classes \
  /Users/yin/code/cryProject/docs/evidence/mona-wire-20261016/local-qualification/m1
```

远端复现源码必须保留 `scripts/platform_mona/`、`cmake/PlatformMona.cmake`、
固定上游完整源码和依赖以及上述六份 M1 CSV 的原路径。在新的
`Cry/platform-mona-20261016-<nonce>/source` 调用：

```sh
sh <source>/scripts/platform_mona/run_native.sh <source> <assigned-root>/run
```

它核对物理路径，将 Java 临时和缓存全部限定在自有根内，禁用 JVM perf 临时文件，
以 CPU0/1 运行离线校准与回放；不占 CPU2/6，不调频，不安装系统依赖。默认 JDK
及其 compiler 模块均不存在时须在同根准备固定 JDK，不能绕过路径约束。

尚未 stage、commit 或 push。根 CMake 入口及 S5 脚本由各自所有者合并，本路未修改。

---

# 本轮追加：独立新根复跑（native-v2，2026-10-16 02:08–02:11 +0800）

本节追加于原记录之后，不修改上文历史段落；上文原件与结论保持原字节。

## 入口修正

原固定入口只接受 v1 根名 `platform-mona-20261016-*`，本轮分配的新根是
`platform-mona2-20261016-<12hex>`，直接运行会被物理路径守卫拒绝。就地修正两处：

| 修正 | 内容 | 修正前 SHA-256 | 修正后 SHA-256 |
|---|---|---|---|
| 根名守卫 | 保留 v1 根，同时接受 `platform-mona2-20261016-` + 恰 12 位小写十六进制；仍要求目录名恰为 `source`、运行根恰为同一分配根下的 `run` | `44485619c95050aa8af3ae16606d824290084a475c1d9d00b58da6ac9ff3e76a` | `9b48d7be9ef76307ce914026bfdba4fe6c1e1321b87baff35d95c9fbe77a772d` |
| 区域设置 | 新增并导出 `LC_ALL=C`、`LANG=C`；上游 JUL 日志否则随调用者 LANG 本地化（本轮调用者 `LANG=zh_CN.UTF-8`，未固定时输出“10月 16, 2026 … 上午/警告”） | `9b48d7be…` | `85ed5a4c41f175645b1eae3b2a7f3395a2dc3f36b4c6f1b24e995b2a5f219c13` |

守卫用 9 组路径样例复验：v1 与 v2 根接受；大写十六进制、11/13 位十六进制、
`source` 之外的子目录、非 Mona 根、`/tmp` 下同名目录均被拒绝。最终入口为
`85ed5a4c…`。

## 新根与身份

- 新根 `/home/nss-marker/yhr/Cry/platform-mona2-20261016-1256c4cca76d`（nonce 取
  `printf 'platform-mona2-20261016' | shasum -a 256` 的前 12 位）。
- `source/` 由只读的 v1 根 `platform-mona-20261016-1de26030f145/source` 复制；
  复制后 122 份清单文件逐字节核对通过，再换入本轮修正的 `run_native.sh`，最终
  123 份上传清单与本地工作区逐一相同（`native-v2/source/UPLOAD_SHA256SUMS`、
  `native-v2/source-verification.log` 123/123 OK）。
- Mona 版本：`mona-timing-report@4c74fb7e629b4d057b2d5d4accdb120d920774b7`
  （HEAD tree `507bba2ad89423354ffe4657a3ed102c3864b3c0`），未修改；快照内
  3 个 JAR 与 25 个 Java 源在每次回放前校验（`upstream-verification.log` 28/28 OK）。
- `mona-timing-lib@81e4de2971a5b379eb60fb4218e8ff771c554a1b` 仅作为固定同级仓库
  记录；本路是 Java 报告侧离线回放，**未构建、未调用**该库（其上游入口需
  Python 2.7 与 SWIG）。
- 源码基线提交 `47033dd864cab5544d2d2cc82d1ed0cf03b30f83`（main）。上传子集中
  6 份为已提交封存 CSV（未修改），其余为未跟踪/被忽略文件；工作区另有 4 个已
  跟踪文件修改（`CMakeLists.txt`、`src/main.c`、`src/measure.c`、`src/mlkem.c`），
  不属于本路，未上传、未执行。同样内容见 `native-v2/source/source-identity.json`。

## 编译与运行方式（无 sudo、无 mvn/ant/javac、无网络安装）

- 远端无 `javac`、无 `mvn`；系统 `OpenJDK 21.0.12.1` 含 `jdk.compiler` 模块。
  入口只在自有 `run/tools/javac` 建立启动器
  `exec java -m jdk.compiler/com.sun.tools.javac.Main "$@"`（SHA-256
  `eac1e450bea5199840215fe1cfac2924f8cf8bd0b51b98d7d30f6a1323a2a84f`），
  不安装系统包、不下载 JDK、不使用 Maven/Ant 或网络仓库。CMake 3.28.3 配置并
  编译出 28 个 class（25 个上游源 + 适配器及内部类）。
- 实际命令（原样见 `native-v2/invocation-attempt-2.txt`）：

  ```sh
  sh /home/nss-marker/yhr/Cry/platform-mona2-20261016-1256c4cca76d/source/scripts/platform_mona/run_native.sh \
     /home/nss-marker/yhr/Cry/platform-mona2-20261016-1256c4cca76d/source \
     /home/nss-marker/yhr/Cry/platform-mona2-20261016-1256c4cca76d/run
  ```

  退出码 0，用时 7 秒；`ctest` 1/1 通过（2.13 秒）；`replay.log` 为空。
- 临时、缓存与 JVM perf 路径全部限定在新根内（`run/runtime`、`run/cache`、
  `-Djava.io.tmpdir`、`-XX:-UsePerfData`）；`ctest` 与 M1 回放以 `taskset -c 0,1`
  启动，未占用 CPU2/6；无调频、无 MSR、无隔离写入、无 sudo、无 Docker。
- 同根另保留一次 `attempt-1-default-locale/`：入口为未固定区域设置的
  `9b48d7be…`，六条结论行与最终一致，但 `mona.log` 为中文日期与“警告”。该次
  作为对照原件保留，不作为最终证据；它正是加 `LC_ALL=C` 的原因。

## M1 输入映射与算法设置

- M1 主 CSV 为 `docs/evidence/tooling-strengthen-20261015/csv/vulnerable-message-zero-ones.csv`
  （`8b176e085d31e697399a5c1c6893b262925bba4944d4ebd7276f65334b96bd95`）与
  `…/fixed-message-zero-ones.csv`（`887a90ea9da97c5b42175410bc58a67baf26aed9ff99240fe3e39527fa5d3bc8`）。
  本轮另核对：两份主 CSV 与封存 `docs/evidence/liboqs010-locked-20261015/runs/{vulnerable,fixed}/samples.csv`
  按类内出现顺序重新配对（第 i 个 `message-zero` ↔ 第 i 个 `message-ones`）后
  **逐字节相同**；封存原件未改动。
- 映射：两列宽表，表头即类名；列 0 → `X`/`class0`，列 1 → `Y`/`class1`；行序即
  类内顺序，记为 `Time(2i, …, 列0)`、`Time(2i+1, …, 列1)`；值须为非负整数纳秒；
  每类至少 100 值。无过滤、抽样、截尾或重标类，10000 值/类全部进入上游。
- 算法设置：原样调用上游 `StatisticEvaluation.calibrationPhase()`（自适应最优箱体
  搜索、最小子集搜索、批次验证），仅继承 `PlotPool` 关闭绘图/PDF/TeX 回调，统计
  实现未修改；`trimming=false`、`holm_member=false`、`p_value=null`、`alpha=null`。

## M1 对照行（本轮真实输出）

`native-v2/run/m1/m1-mona.csv`，与上轮 Linux 结果、与本地 macOS 结果逐字节相同：

| M1 输入 | 状态 | validated | rejected | 通过验证的箱体与子集 |
|---|---|---:|---:|---|
| primary-vulnerable | no_validated_box_separation | 0 | 9 | 无 |
| primary-fixed | validated_box_separation | 1 | 8 | `X<Y` 0.1–0.11，5120 值，子集数 1 |
| seed-424242-vulnerable | no_validated_box_separation | 0 | 9 | 无 |
| seed-424242-fixed | validated_box_separation | 1 | 1 | `X<Y` 0.31–0.32，10000 值，子集数 1 |
| cpu-6-vulnerable | no_validated_box_separation | 0 | 9 | 无 |
| cpu-6-fixed | no_validated_box_separation | 0 | 0 | 未找到最优箱体（两方向都提示需更多测量） |

结论与上轮一致：Mona 的箱体规则与既有 M1（Welch CI + Holm、RTLF、dudect）方向
不一致；两项 fixed“有分离”都出现在迭代扩展子集后只剩 1 个子集的末轮，属该自适应
实现的行为，不能解释为受控误报率，也不能用 vulnerable 的无分离推翻既有 M1 统计。
字段 `Confidence Interval` 是批次成功百分比，不是 p 值或覆盖区间，不入 Holm；
无分离不证明恒时。本路不产生新硬件计时，也没有把其它工具结果改称 Mona。

## 独立复现核对（v1 与 v2）

在只读 v1 根与新根之间逐项对比：6 个数据集 × 8 份核心摘要
（`mona.csv`、`mona.json`、`mona.md`、`mona-validations.csv`、输入副本、退出码、
环境、上游校验）**逐字节相同**；`m1-mona.csv` 逐字节相同；`box-results.csv`、
`mona.log`、`bytecode.sha256`（28 个 class）、`upstream-sources.sha256`、
`tools.sha256` 在归一化掉包内绝对路径（两代根名长度不同）与日志时间戳后逐字相同。
本地拉回副本亦按同一规则复核一致（`native-v2/run/…` 对比 `native-qualification/run/…`）。
这支持“同一固定算法在不同物理根、不同 JVM 调用环境下的确定性重放”，不是新数据、
新测量或新统计方法。

## 原始件、失败件与路径核对

- 拉回 `docs/evidence/mona-wire-20261016/native-v2/` 共 183 份原件；181 份与远端
  新根清单逐字节一致（`native-v2/local-verification.log`），另 2 份是清单文件自身
  与压缩包摘要（按设计不入清单）。
- 完整原包 26,640,698 字节，SHA-256
  `5d9f0b055a6cc9618dbccc90aec254b50f78debfd23c2233e13fa903b6a936f8`，本地留存
  `private-originals/native-v2-originals-1256c4cca76d.tar.gz`（含许可未明确的上游
  源码/JAR，故不入仓库正文）。根清单 `ORIGINAL_SHA256SUMS` 902 行，远端
  `sha256sum -c` 902/902 通过；包内 1163 个成员、无符号链接。
- 失败原件：第一次打包把输出写在被归档根内，tar 报“读入时文件发生变化”并以 1
  退出。部分产物保留在新根 `failed/archive-attempt-1/`
  （`originals.tar.gz.partial` 4,441,817 字节，SHA-256
  `03390942332470af674c97d39b6a553431338c4c8526b9b7ea838879c9b5e2e8`，并附
  `README.txt` 记录原因与后续修正）；本地副本在
  `private-originals/native-v2-archive-attempt-1.partial.tar.gz`。未删除任何失败件；
  历史 `failed-preparation/` 三次准备失败保持原样。
- 结束核对：无 java/javac 残留进程；新根无符号链接；`~/.m2` 不存在；只读扫描
  `/tmp`、`/var/tmp` 与 `$HOME`（深度 ≤2）在运行窗口内没有本路文件
  （`native-v2/post-run-audit.txt`，仅目录自身 mtime 有变化）。调用者亲和性回到
  `0-31`（`0,1` 只施加于 `ctest`/回放子进程）。未关闭主控共享 SSH，未 sudo，
  未改 M1 封存证据，未 stage/commit/push。

## M2 状态：未接入（如实标注）

本轮没有 `platform-collect-20261016-*` 主 CSV，因此 M2 **未执行**，不报“阴性”，
也不用 Mona 名义转发其他工具结果。主控产出 M2 CSV 后，可直接复用同一新根与
class 目录接入（输出目录必须不存在）：

```sh
env LC_ALL=C LANG=C sh /home/nss-marker/yhr/Cry/platform-mona2-20261016-1256c4cca76d/source/scripts/platform_mona/run.sh \
  --input <M2_CSV> --output-dir /home/nss-marker/yhr/Cry/platform-mona2-20261016-1256c4cca76d/m2/<dataset> \
  --class-dir /home/nss-marker/yhr/Cry/platform-mona2-20261016-1256c4cca76d/run/build/platform-mona/classes \
  --upstream-dir /home/nss-marker/yhr/Cry/platform-mona2-20261016-1256c4cca76d/source/third_party/mona-timing-report \
&& awk -v d=<dataset> 'NR>1 {print d "," $0}' \
  /home/nss-marker/yhr/Cry/platform-mona2-20261016-1256c4cca76d/m2/<dataset>/mona.csv \
  >> /home/nss-marker/yhr/Cry/platform-mona2-20261016-1256c4cca76d/m2/m2-mona.csv
```

接受两种输入：两列非负整数纳秒宽表（表头即类名，同 M1），或 S5 的 `V1,V2` +
X/Y 长表；每类至少 100 值。若 M2 只提供原始 6 列 `samples.csv`，先按与 M1 相同
且已核对的类内顺序投影，再调用上面的命令：

```sh
awk -F, 'NR==1 {print "message-zero,message-ones"; next} \
  $3=="message-zero" {z[++n0]=$5} $3=="message-ones" {o[++n1]=$5} \
  END {for (i=1; i<=n0 && i<=n1; i++) print z[i] "," o[i]}' <M2_samples.csv> > <M2_CSV>
```

接入后仍按本节口径保存：输入副本与 SHA-256、`mona.json/csv/md`、
`mona-validations.csv`、`box-results.csv`、原始 `mona.log`、退出码、`tools.sha256`
与 `upstream-verification.log`；`holm_member=false` 不变，阴性不证明恒时。
