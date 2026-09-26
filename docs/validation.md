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
