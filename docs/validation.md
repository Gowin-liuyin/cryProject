# 验证记录

## 模块二：参考功能

实测机器为 ARM64 macOS / Apple Clang 21。`make test-reference` 通过。
NIST ACVP-Server 独立来源：
<https://github.com/usnistgov/ACVP-Server/tree/975de31eb83d87039ec88934fdc47d8c312b892d/gen-val/json-files>。
标准修订标识 `FIPS203`，不使用旧 Kyber KAT 或本库自产答案。
原始 keyGen / encapDecap 的 prompt.json 与 expectedResults.json 保存在 tests/vectors；
SHA256SUMS 固定原始及转换文件。NIST 数据为美国政府发布的测试材料；原件中说明原样保留。
`sh tests/convert_vectors.sh` 使用 jq 按 tcId 关联原始输入/独立预期，只提取 ML-KEM-768 的
25 keygen、25 encaps、10 decaps；不修改预期字节。日常构建/测试不依赖 jq 或联网。
测试 C 程序逐字节比较完整密钥、密文、共享密钥。解封装预期包括接受和隐式拒绝，
另用 J(z||c) 识别向量中的拒绝实例；此识别仅用于测试，不进入产品接口/采集标签。

封装层检查公开长度与空指针后才调用固定长度内核。普通密钥生成和封装从系统
/dev/urandom 读取随机性，处理打开、读取、关闭失败和 EINTR，清理临时随机种子。
确定性入口仅由测试显式调用；普通接口不接收种子、不打印密钥或内部验证结果。
自检用实际系统随机源完成一次封装/解封装往返。
本模块未声称参考版本已通过完整常数时间审计，也未执行 x86_64 Linux 验证。

## 模块四：CLI 与输入

`make test` 在两版本上通过 KAT、192 次差分解封装及 CLI 集成检查。
CLI 测试覆盖五类输入、相同种子两版本生成文件一致、系统随机 demo/selftest、
未知类别、负数/溢出种子、已有输出文件拒绝覆盖，以及 1087 字节短密文和超长密文。
每个正确长度密文统一返回“解封装完成”，不输出内部重加密比较结果或共享密钥。
初次集成发现库副本目录 mlkem 与 CLI 同名冲突，已将实际命令统一为 baseline 后重测通过。

## 模块五：计时采集

Apple M5 / ARM64 macOS 上两版各实际采集 500 条原始时间（5 类各 100）。
CLOCK_MONOTONIC 的报告分辨率为 1000ns，10000 次时钟进展检查通过。
C 测试确认行数、各类计数、纳秒标识、正值和两版相同种子的类别顺序一致。
运行文件 SHA3-256 与独立 OpenSSL `dgst -sha3-256` 输出核对一致。
构建初次遇到 C 标准最短字符串支持长度限制，改为逐行常量数组；
macOS sysctl 头文件与 POSIX 特性宏冲突已用平台特性宏修复，严格警告重建通过。
已确认目标机制并采集原始数据，时间差异尚未正式统计确认。
模块五开发期输出保存在忽略的 runs/module5-final，最终交接另封存正式构建及原始数据。

## 模块六：集成验收

从全新 build-integration 目录以 `-O2 -g` 完整运行 `make test`，通过。
新增并执行 NIST 的 10 公钥检查和 10 私钥检查；总计每版本 80 组独立答案。
保留原始 JSON，转换仅增加这两组，旧 60 组预期未修改；SHA256SUMS 已更新。
真实随机源失败测试在独立测试进程中降低文件描述符上限，使 /dev/urandom 打开失败，
确认 keygen/encaps 返回随机源错误；恢复限制后往返自检通过。

`make sanitize` 在独立 build-sanitize 目录对两版完整 C 路径及回归补丁执行
AddressSanitizer + UndefinedBehaviorSanitizer（-O1 -g -fno-omit-frame-pointer），通过，
未报告地址或未定义行为问题。动态检查的测量输出仅用于接口自检，临时文件随测试清理。
源码命名检查未发现含糊的自有标识符；vendor 原件未改。

模块三补丁的标准 diff 空白上下文曾触发 git diff --check，已在独立提交 c6f709e 修复并重测，
没有改写提交历史。最终正式采集与反汇编将在功能代码提交后封存，以绑定干净源码版本。

待目标环境执行：真实 x86_64 Linux 的同组测试、最终产物分支确认及同机新采样。
当前没有 GNU GCC 的实际运行证据，没有正式统计检验，也没有未知密钥攻击或常数时间证明。

### 最终采集与产物复核

最终功能提交 `e519d941ddcf8a4dfb9e92f5b9343db53fc36064` 的干净源码已在 build-release 重建并通过全套测试。
两版本各采集 5000 次（5 类各 1000），公开 seed=20260926；数据保存在
[evidence/final](evidence/final/README.md)，包含原始 CSV、完整元数据、构建日志、反汇编与摘要。
C 检查确认条数、各类数量、单位和类别顺序；独立 OpenSSL SHA3-256 与运行元数据一致。

实际 vulnerable/measure 中，在两次读钟之间存在完整解封装调用，输出消费和整批 I/O 在其后。
解封装到重加密到消息编码的实际调用链仍在，编码入口 +0x48 为消息位控制的 tbz。
参考编码该位置为无分支算术选择；不由局部检查推导整库恒时性。
正式采集与 sanitizer 的构建输入清单逐项一致；动态检查时间未进入最终 CSV。
所有原始时间保留，未计算显著性、未确认时间差异或未知密钥攻击能力。

## CMake 构建迁移

按用户后续要求，CMake/CTest 成为唯一构建和测试规则来源；原 Makefile 只转发命令。
CMake ≥3.21，C11 严格警告，两个库和两个版本的程序完全分离；缺陷补丁只作用于构建目录。
默认 preset 使用 RelWithDebInfo，sanitizer preset 使用独立目录和 ASan/UBSan。
构建身份包含配置、实际编译命令文件摘要、CMake 配置源码及所有原有构建输入。

本机 CMake 4.3.2 / Apple Clang 21 上实际执行并通过：
- Unix Makefiles 默认 preset 的 8 项 CTest，以及根 Makefile 兼容入口。
- Ninja 单配置的 8 项 CTest。
- Ninja Multi-Config 的 Debug 构建及 8 项 CTest。
- sanitizer preset 的 8 项 CTest，无 ASan/UBSan 报告。
- BUILD_TESTING=OFF 构建成功，CTest 注册数为 0。
- 无改动增量构建只检查/刷新元数据，不重编译；触碰补丁后，仅缺陷内核及其关联程序重建。

新的 CMake/Ninja 正式配置采集程序各运行 50 次，作为构建迁移的采集冒烟检查，
并核对两版记录数和顺序、运行文件 SHA3-256。缺陷编码仍保留消息位控制的 tbz。
证据位于 [evidence/cmake](evidence/cmake/README.md)。这些结果不扩大为统计时序结论；
历史 evidence/final 的 5000 次数据继续绑定原 Make 构建，不冒称当前 CMake 构建结果。
当前仍未进行真实 x86_64 Linux 验证。

## 用户要求的全面代码审查与风格统一

后续审查见 [review.md](review.md)：已修正 CSV/KAT 校验器的宽松解析和密文读取失败后的后续读取，
统一全部自有 C/CMake 格式并加入可复现风格检查。CTest 从 8 项增加到 9 项，新增
vector_parser；两版 KAT 仍各覆盖 80 组独立答案。
整理后的源码通过干净构建、9 项 CTest、ASan/UBSan 和自有运行代码静态分析。
新产物独立证据见 evidence/review，原有 evidence/completion 等目录继续只证明各自历史提交。

## 固定统计检验与正式确认

按用户推进要求，新增只读取 CSV 的统计程序 `analyze`，把判定从采集中分离出来；
采集程序仍不做任何统计判断。CTest 从 9 项增加到 10 项，新增 analysis。
方法、预先规定项和解释边界见 [statistics.md](statistics.md)。

功能源码提交 `d322cbf2743a6db8529a59641f161c688bff7acf`。本机实际执行并通过：
- 全新 build/statistics 目录、CMake/Ninja/RelWithDebInfo 的 10 项 CTest。
- 同一源码的 sanitizer preset 10 项 CTest，无 ASan/UBSan 报告。
- clang-format 21 与 cmake-format 0.6.13 检查、`sh -n` 语法检查。
- Apple Clang 静态分析覆盖 src/analyze.c，无报告；首版的符号下标指针存储触发
  误报泄漏，改为单一平铺记录数组后消除，同时去掉了重复的增长逻辑。

analysis 用可解析验证的合成数据检查统计实现：完全分离两组给出 `rank_u1=0.0`、效应量 0；
分布相同两组给出 `rank_u1=200.0`、`rank_z=0.0000`、`rank_p=1`；取值全同判为方差退化。
预期值由秩和检验定义推出，不由被测程序生成。另覆盖十类畸形 CSV、截断尾行、
单条记录、缺失文件、已存在报告和参数个数错误。

正式采集两个公开种子（20260930 与 42）各两版、每版 25000 条（五类各 5000）：
参考版两次均 0/10 显著，缺陷版两次均 7/10 显著；恒定消息类与变化消息类之间
均值差 711–800ns、效应量 0.819–0.844。两版共用同一采集程序、种子、类别顺序与输入构造。
C 记录校验、独立 OpenSSL SHA3-256（与报告 `csv_digest`、元数据 `executable_digest` 一致）
和两版编码函数反汇编均已归档于 [evidence/statistics](evidence/statistics/README.md)。

仍未执行：真实 x86_64 Linux/GCC 的同组采集与确认、恒时防护补丁、未知密钥攻击或密钥恢复。

## 恒时编码补丁与对照

新增第三个变体 hardened，应用独立的 message-constant-time.patch：保留与缺陷版相同的
函数级优化控制和循环结构，只把消息位分支换成掩码选择，使对照只改变「有无分支」。
CMake 的补丁准备与等价检查改为按变体参数化，`equivalence` 拆成 `equivalence_vulnerable`
与 `equivalence_hardened`；CTest 从 10 项增加到 13 项。方法与边界见 [mitigation.md](mitigation.md)。

功能源码提交 `8e437f27f8a27f63a4edbe54f0472f040d6b091f`。本机实际执行并通过：
- 全新 build/mitigation 目录、CMake/Ninja/RelWithDebInfo 的 13 项 CTest。
- sanitizer preset 的 13 项 CTest，无 ASan/UBSan 报告。
- clang-format 21、cmake-format 0.6.13 和 `sh -n` 检查。
- 三个变体的 `baseline version` 与采集 `.meta` 实现名一致；CLI 检查确认三者在相同种子下
  生成的五类测试密文逐字节相同。

三个变体用同一种子 20260930、每个 25000 条采集并用同一固定检验判定：
缺陷版 7/10 显著（类别均值极差 752ns、最大 |z|=62.69），防护版 0/10（45ns、3.61），
参考版 0/10（29ns、1.01）。record-checks.txt 另用类别列逐字节比较确认三者样本顺序相同。
实测反汇编确认防护版函数内只剩循环边界分支，缺陷版的 `tbz` 在同一偏移变为 `and` 掩码运算。
证据见 [evidence/mitigation](evidence/mitigation/README.md)。

防护版六项「恒定消息类 vs 变化消息类」比较仍有同方向残差（均值差 22–44ns、|z| ≤ 3.61），
未达预先规定阈值但未消失，因此不宣称该补丁已证明恒时。
防护版整体比参考版慢约 200ns，来自为保持对照而保留的 `optnone`，不是防护的必要开销。

仍未执行：真实 x86_64 Linux/GCC 的同组采集与确认、打开优化后的恒时编码产物复核、
未知密钥攻击或密钥恢复。
