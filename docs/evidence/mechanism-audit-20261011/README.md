# 固定便携解封装的三类时序机制审计

日期：2026-10-11。对象是本仓库固定的 mlkem-native 便携 C、ML-KEM-768 参考构建。
正式产物在授权裸金属 `nss-m`（`10.144.144.5`，`systemd-detect-virt=none`，Linux 6.17.0-35-generic，x86_64）。
工作根只在 `/home/nss-marker/yhr/Cry/mechanism-audit-20261011/`。GCC 13.3.0、CMake 3.28.3、
GNU objdump 2.42、RelWithDebInfo、sanitizer 关闭。内核目标文件
`kernel.c.o` 的 SHA-256 是 `3ce202eebcc590f02b401dadd09f81fa79eb6d74da820f5ef701a4543d649224`。
机器行和审计原文见同目录 `machine.txt`、`audit-run-1.txt`。两次审计输出逐字一致。
CTest `mechanism_audit` 在该机构建上通过。

这是指令归类，不是解封装计时，也不是统计检验。三类机制在该产物中都不存在，因此没有防护前后样本、均值、分位数或开销。
不把本机 macOS/ARM 的编译结果写成这次 Linux 结果。本记录不证明整库恒时、逐调用恒频或物理误差界。
R02、R04 仍为部分签收。历史人工消息分支仍是 [防御案例](../../defensive-case.md)，不是这次新发现的上游漏洞。
已封存的 `docs/evidence/` 旧目录没有改写。

## 文献机制、观察者能看到什么、本产物是否存在

| 机制 | 文献里时序观察者能看到的量 | 本 GCC 产物 | 处理 |
|---|---|---|---|
| KyberSlash 类变延迟除法 | 消息比特。压缩或消息编码若用除法，时延随被除数变化 | 不存在。消息编码和压缩符号中 `division_instructions=0` | 不新增补丁。上游已用 Barrett 乘法约减 |
| clangover 类消息编码分支 | 消息比特。掩码写法被编译成秘密依赖分支 | 不存在。`baseline_native_poly_frommsg` 的秘密条件分支为 0，循环边界分支为 2 | 不新增补丁。源码仍是值屏障加 `mlk_ct_sel_int16` |
| FO 比较或拒绝选择分支 | 比较或拒绝标志。提前结束比较，或按失败标志选择共享秘密 | 不存在。`baseline_native_dec` 的秘密条件分支为 0，循环边界分支为 2 | 不新增补丁。比较和选择仍是 `mlk_ct_memcmp` 与 `mlk_ct_cmov_zero` |

公开错误返回和栈保护比较留在解封装里，它们不暴露重加密是否失败。
审计程序的自检会把论文中的除法、消息位正向分支和拒绝标志正向分支标为存在；这次正式产物没有命中这些形态。

## 复现

在源码根、Linux x86_64、GCC 上：

```sh
cmake -S . -B build/cmake -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
cmake --build build/cmake --target mechanism_audit test_mechanism_audit
ctest --test-dir build/cmake -R '^mechanism_audit$' --output-on-failure
build/cmake/mechanism_audit \
  build/cmake/CMakeFiles/mlkem_reference.dir/src/kernel.c.o .
```

`mechanism_audit` 对刚编出的 `kernel.c.o` 反汇编，并核对 `compress.c` 与 `kem.c` 的源码位置。
输出中的 `artifact_sha256` 必须等于该目标文件的 SHA-256。
