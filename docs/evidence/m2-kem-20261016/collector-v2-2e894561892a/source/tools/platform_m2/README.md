# M2 完整解封装采集器 collector-v2

本目录只放 M2 锁频采数用的**普通（非 sanitizer）完整解封装 collector**、它的类/顺序逻辑与命令行资格。
历史定位层（三个热点、KyberSlash varlat）仍是只读原件，见 `docs/evidence/m2-kyberslash-20261016/`；
完整 KEM 功能资格与冻结源码见 `docs/evidence/m2-kem-20261016/`。

## 组成

| 文件 | 作用 |
|---|---|
| `collector.c` | 采集器 CLI：单次窗口只包一次 `mlkem_decapsulate`，逐行写 CSV |
| `collector_inputs.c/.h` | 四个输入类与可重放的类顺序（与既有 measure 相同的 SHAKE256 tag=4 Fisher–Yates） |
| `collector_selftest.c` | 类语义资格：选择消息接受路径、格式破坏密文隐式拒绝公式、顺序重放；`--transcript` 供跨版本比对 |
| `keypair_tool.c` | 公开测试夹具密钥：同一 `--key-seed` 在两版本下必须逐字节一致 |
| `run_collector_qualification.sh` | 远端资格运行入口（功能资格 + 冒烟采集 + 跨版本等价，全部落在一个输出目录内） |
| `test_collector_cli_guards.cmake` | 命令行准入资格（非法参数必须失败且不留输出，已有输出不得被覆盖） |
| `test_collector_equivalence.cmake` | 两个变体的 collector 转录必须逐字节相同 |

`cmake/PlatformM2Collector.cmake` 是独立构建模块，只由本目录的 `CMakeLists.txt` 引用；
根构建和其他模块不受影响。热点编译条件与已封存的 platform-m2kem 树一致：
vendor 用 Clang `-Oz -g -fno-vectorize -fno-slp-vectorize`、`KYBER_K=3`、
`randombytes=platform_m2_randombytes`。

## 构建与测试

```sh
cmake -S tools/platform_m2 -B build/m2-collector -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/m2-collector -j4
ctest --test-dir build/m2-collector --output-on-failure
ctest --test-dir build/m2-collector -R '^m2_' --output-on-failure   # 只跑 M2
```

ASan/UBSan 版本加 `-DM2_COLLECTOR_SANITIZERS=ON`，只用做软件资格，不用于正式采数。

## 四个类

| 类名 | 构成 | 期望路径 |
|---|---|---|
| `message-zero` | 固定公开公钥下，实际解密消息 0x00 的密文 | 重加密验证通过，接受 |
| `message-ones` | 同一公钥下，实际解密消息 0xFF 的密文 | 重加密验证通过，接受 |
| `malformed-zero-tail` | 同一基准密文，前 1056 字节不变、末 32 字节置 0x00 | 隐式拒绝 |
| `malformed-ff-tail` | 同一基准密文，前 1056 字节不变、末 32 字节置 0xFF | 隐式拒绝 |

前两个是主类对，后两个是"格式破坏密文"对照类对；对照类对只做描述性报告，不进主检验。
两个对照类长度仍是合法 1088 字节，走的是原 `kem.c` 隐式拒绝分支，不是长度拒绝。

## 采数使用

```sh
<elf> --class message-zero,message-ones --samples 10000 --seed 31337 \
      --raw <新CSV> --meta <新meta> --run-id <运行名> \
      --public-key <pk.bin> --secret-key <sk.bin>
```

窗口、单位、顺序和输出字段的口径见
`docs/evidence/m2-kem-20261016/COLLECTOR_CONTRACT.md`。
