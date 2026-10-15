# M3 人工秘密下标 LUT 夹具

本夹具是**人工构造的访存校准例**，不是 ML-KEM 解封装、上游漏洞或密码实现，不用于保护真实秘密。它将固定 32 字节输入逐字节映射为 `(197*x+101) mod 256`，两种构建的输出语义相同。

| 构建 | 表访问 | 用途 |
|---|---|---|
| `mem_lut_leak_on` | 每字节以秘密值直接索引 256 项表 | 人工定位阳性 |
| `mem_lut_leak_off` | 每字节按公开顺序读取全部 256 项，以掩码选择结果 | 固定访存对照 |

`volatile` 保留实际读取；关版本没有按秘密值分支或寻址的源码。编译器、ISA、动态检查和时间统计仍须分别核验，源码结构不构成恒时证明。没有 sleep、随机延迟、空转或秘密输出。

从仓库根构建，所有产物留在 `build/`：

```sh
cmake -S fixtures/mem_lut_leak -B build/platform-s7/ordinary -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/platform-s7/ordinary --parallel 2
ctest --test-dir build/platform-s7/ordinary --output-on-failure
cmake -S fixtures/mem_lut_leak -B build/platform-s7/sanitize -DCMAKE_BUILD_TYPE=RelWithDebInfo -DMEM_LUT_SANITIZERS=ON
cmake --build build/platform-s7/sanitize --parallel 2
ctest --test-dir build/platform-s7/sanitize --output-on-failure
```

每个自检穷举 256 个字节取值及 32 个位置，共 8192 个映射；预期值来自公开算术公式。另检查空指针、0/31/33 字节输入、短输出、错误调用不改输出、额外输出字节不改、原地及部分重叠调用。自检无计时窗口。

接口 `mem_lut_apply` 要求输入恰好 32 字节、输出容量至少 32 字节。成功返回 `0`、写 32 字节；空指针/错误长度/短缓冲区返回 `-1`，不访问内核、不写输出。调用者负责保证所声明范围是有效内存。静态库分别为 `mem_lut_on_kernel` 和 `mem_lut_off_kernel`，一个可执行程序只链接其中一套。

安装 Valgrind 头文件后，可编出 poison 入口：

```sh
cmake -S fixtures/mem_lut_leak -B build/platform-s7/ctgrind -DCMAKE_BUILD_TYPE=RelWithDebInfo -DMEM_LUT_ENABLE_CTGRIND=ON
cmake --build build/platform-s7/ctgrind --parallel 2
valgrind --tool=memcheck --track-origins=yes --error-exitcode=97 build/platform-s7/ctgrind/mem_lut_leak_on --ctgrind-probe
valgrind --tool=memcheck --track-origins=yes --error-exitcode=97 build/platform-s7/ctgrind/mem_lut_leak_off --ctgrind-probe
```

入口用标准 Memcheck client request 标记人工输入，调用后恢复定义再消费结果；不需要应用历史 ctgrind SVN 补丁。未启用 hook 或未在 Valgrind 下执行时返回 `77`，避免把普通执行当成定位。已记录的原生结果为开版本 `97`、关版本 `0`，见[本轮证据](../../docs/evidence/m3-memaccess-20261016/RESULT.md)。上述命令不采数、不调频。

顶层集成只需主控在合适位置加入 `add_subdirectory(fixtures/mem_lut_leak)`；本路没有修改顶层 CMake。Microwalk 的交互 wrapper、真实解封装接入和统计采集尚未实现，工具探测及存储边界见[NOTES](../../docs/evidence/m3-memaccess-20261016/NOTES.md)。
