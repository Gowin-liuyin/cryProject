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
