# M2 软件资格环境

- 本机：macOS/ARM，Apple Clang21；普通/ASan+UBSan各7/7，日志在 `macos-qualification/`。
- 原生：nss-m，x86_64裸金属，Linux6.17.0-35-generic，Ubuntu Clang18.1.3、CMake3.28.3；原记录见 `native-qualification/ENV.txt`。
- 根目录：`/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019`，源码、两构建、原件、依赖、临时、缓存均在此物理树。
- 普通：RelWithDebInfo，原生vendor `-Oz -g -fno-vectorize -fno-slp-vectorize`，`KYBER_K=3`，无LTO、无AVX2分发；封装用根普通优化和严格警告。
- 动态：另建 `build-sanitize`，ASan/UBSan、`-O1 -fno-omit-frame-pointer`；不作为采数产物。
- KAT依赖：远端有libcrypto.so.3/OpenSSL3.0.13运行库，无开发头。只将Ubuntu `libssl-dev=3.0.13-0ubuntu3.16` 原deb解包到本树 `dependencies/sysroot`，没有系统安装或apt写入。
- deb来源：`https://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl-dev_3.0.13-0ubuntu3.16_amd64.deb`；远端系统已有APT缓存元数据给定SHA-256 `2b4734df0475e305ac03abb0a2cc5659651ed37ef02d967a1c4033a154cf714b`，下载后逐字核对通过。
- CMake测试配置：`OPENSSL_INCLUDE_DIR=<树>/dependencies/sysroot/usr/include`、`OPENSSL_CRYPTO_LIBRARY=/lib/x86_64-linux-gnu/libcrypto.so.3`，额外系统头路径为树内 `usr/include/x86_64-linux-gnu`；这些头仅服务独立KAT目标，生产measure没有libcrypto动态依赖。
- `TMPDIR/TMP/TEMP=<树>/tmp`，`XDG_CACHE_HOME=<树>/cache`。所执行7条新测试、适配、CMake和官方测试DRBG源码的显式 `/tmp`、`/run`、mktemp搜索无命中；只执行M2新测试，未执行其余旧测试。
- 45个symlink物理解析均位于Cry，结束本树运行程序为0；原JSON与源/20ELF/11原件摘要均保留。
- 本轮编译最多-j4；无密钥恢复、无measure数据、无频率/boost/governor/亲和性/隔离配置写入。
- 共享SSH socket由主控管理；本路没有关闭主控连接。口令/私钥内容未进入材料。

可复现构建命令（从根源码目录执行，OpenSSL只供测试）：

```sh
cmake -S . -B build/m2-ordinary -DCMAKE_C_COMPILER=clang-18 -DBASELINE_ENABLE_PLATFORM=ON -DBASELINE_SANITIZERS=OFF
cmake --build build/m2-ordinary --target platform_m2 platform_m2_check -j4
cmake -S . -B build/m2-sanitize -DCMAKE_C_COMPILER=clang-18 -DBASELINE_ENABLE_PLATFORM=ON -DBASELINE_SANITIZERS=ON
cmake --build build/m2-sanitize --target platform_m2 platform_m2_check -j4
```

缺OpenSSL开发依赖时必须按原日志补充树内头/实际库路径；配置器会明确警告KAT目标缺失，
不得把剩余5条通过冒称完整7条资格。源码和CLI已存在不代表统计计划已冻结或已执行。
