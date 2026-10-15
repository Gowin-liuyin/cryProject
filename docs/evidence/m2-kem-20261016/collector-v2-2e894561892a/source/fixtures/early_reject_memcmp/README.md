# M4：人工提前退出比较夹具

**人工构造，用于校准。** 这是相等性比较夹具，不是实际 KEM、CVE 复现或密钥恢复。vulnerable
在首个不同字节处返回；ct 访问公开长度内的全部字节并异或归约。返回值仅为 0/1，两者
都不提供标准 `memcmp` 的正负排序语义。`ct` 是实现意图名称，不能替代产物检查或有界验证。

封装接口只接受 32 字节，长度与空指针先检查；提取内核要求调用者提供有效指针及可访问长度。
`--self-test` 分别对照标准库 `memcmp(...) == 0`，覆盖长度 0–32、全部差异位置及全部替换字节；
同时使用真实短数组检查封装拒绝边界。固定输入只用于明确的测试，不使用随机延迟或空转。

```sh
cmake -S fixtures/early_reject_memcmp -B build/platform-s8/ordinary -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/platform-s8/ordinary
ctest --test-dir build/platform-s8/ordinary --output-on-failure
cmake -S fixtures/early_reject_memcmp -B build/platform-s8/sanitize -DCMAKE_BUILD_TYPE=Debug -DM4_FIXTURE_SANITIZERS=ON
cmake --build build/platform-s8/sanitize
ctest --test-dir build/platform-s8/sanitize --output-on-failure
```

两套主入口为 `m4_compare_vulnerable`、`m4_compare_ct`；默认运行自检，也接受 `--probe`。
后者执行一次固定比较，不采数、不输出比较结果。Linux Valgrind 环境可在独立构建中配置
`-DM4_ENABLE_CTGRIND=ON -DM4_VALGRIND_INCLUDE_DIR=<含valgrind/的目录>`，然后分别执行：

```sh
valgrind --tool=memcheck --error-exitcode=99 --track-origins=yes <build>/m4_compare_vulnerable --probe
valgrind --tool=memcheck --error-exitcode=99 --track-origins=yes <build>/m4_compare_ct --probe
```

poison 只包住秘密输入到比较调用；结果消费前取消 poison。应记录具体源码行和二进制地址，
不能把消费者分支或未运行的预期当作定位结果。普通、poison、sanitizer 产物相互分离。

Binsec 抽取入口为 `m4_binsec_vulnerable`、`m4_binsec_ct`，脚本 `checkct.cfg` 限定公开长度
1–16；设置秘密数组、公开候选数组与具体栈指针，在 `exit` 入口停止。Linux ELF 构建后执行：

```sh
binsec -sse -checkct -sse-script fixtures/early_reject_memcmp/checkct.cfg -sse-depth 10000 -sse-timeout 120 -checkct-stats-file <out>/vulnerable.toml <elf>/m4_binsec_vulnerable
binsec -sse -checkct -sse-script fixtures/early_reject_memcmp/checkct.cfg -sse-depth 10000 -sse-timeout 120 -checkct-stats-file <out>/ct.toml <elf>/m4_binsec_ct
```

工具可用性、固定官方参考和本轮执行边界见
[`NOTES.md`](../../docs/evidence/m4-compare-20261016/NOTES.md)。macOS 的 ARM Mach-O 构建
只作软件资格；本轮未运行 Binsec。Linux 采数前必须另行冻结并提交 PLAN；这里没有计时循环。

主控接入建议：可选 `add_subdirectory(fixtures/early_reject_memcmp)`；本路没有改顶层 CMake。
本夹具不修改 vendor、密码语义、隐式拒绝或任何现有证据。
