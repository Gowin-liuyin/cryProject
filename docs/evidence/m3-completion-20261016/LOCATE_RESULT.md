# M3 挂载后定位重验 + Microwalk 探测（LOCATE_RESULT，2026-10-16）

本文件回答 task-4 的三个检查项与主控追加的 A/B 两项。所有远端动作都在新根
`/home/nss-marker/yhr/Cry/platform-m3-locate-20261016-4b102a339cc8/` 内完成（`realpath` 一致、
树内符号链接为空），未使用 sudo，未改本仓库 git 索引，未改 `fixtures/` 语义，
未覆盖 `docs/evidence/m3-completion-20261016/native-8b6f2d91/`。原始日志见
[`locate-v2/remote/`](locate-v2/remote/)（332 个文件，摘要见 [`locate-v2/SHA256SUMS`](locate-v2/SHA256SUMS)，
拉回口径见 [`locate-v2/PULL.txt`](locate-v2/PULL.txt)）。

新根 `source/` 由旧根同名树只读复制而来，`sha256sum -c SOURCE_EXPORT.sha256` 逐文件 **348/348 通过**
（`remote/logs/source-verification.log`）。

---

## 1. 四组合 Memcheck 重验（D02）

**做法**：在新根里**重新配置、重新构建**一棵普通构建（不是复用旧产物），再用
`tools/platform_m3/README.md` 里逐字相同的四条命令跑四组合。脚本 `run-locate.sh`，
日志 `remote/logs/{configure,build}-ordinary.log`、`remote/logs/combos.summary`。

```
cmake -S source -B build-ordinary -DCMAKE_C_COMPILER=clang -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF -DBASELINE_ENABLE_PLATFORM=ON \
      -DA113_ARCHIVED_CASE_ONLY=OFF -DPLATFORM_M3_CTGRIND=ON          # exit 0
cmake --build build-ordinary --parallel 8 \
      --target platform_m3 platform_m3_check platform_m3_on_probe platform_m3_off_probe   # exit 0
```

构建顺带跑的平台自检：**6/6 通过**（`platform_m3_{on,off}_kat`、
`platform_m3_{on,off}_random_failure`、`platform_m3_full_output_equivalence`、
`platform_m3_patch_dry_run`；`remote/logs/c10-ctest.log`）。

| 组合 | 命令（与 README 逐字一致，仅加 `--log-file`） | 退出码 | ERROR SUMMARY |
|---|---|---|---|
| on `--secret` | `valgrind --tool=memcheck --track-origins=yes --error-exitcode=97 ./platform_m3_on_probe --secret` | **97** | **1280 errors from 2 contexts** |
| off `--secret` | 同上，换 `platform_m3_off_probe` | 0 | 0 errors from 0 contexts |
| on `--defined` | `valgrind --tool=memcheck --error-exitcode=97 ./platform_m3_on_probe --defined` | 0 | 0 errors from 0 contexts |
| off `--defined` | 同上，换 `platform_m3_off_probe` | 0 | 0 errors from 0 contexts |

on `--secret` 的两处命中栈（原始日志 `remote/logs/on-secret.memcheck.log`）：

```
==337826== Use of uninitialised value of size 8
==337826==    at 0x10DCED: baseline_native_poly_frommsg (compress.c:714)
==337826==    by 0x10DCED: baseline_native_indcpa_enc (indcpa.c:544)
==337826==    by 0x112448: baseline_native_dec (kem.c:443)
==337826==    by 0x1093D7: main (source/tools/platform_m3/ctgrind_probe.c:43)
==337826==  Uninitialised value was created by a client request
==337826==    at 0x109354: main (source/tools/platform_m3/ctgrind_probe.c:40)
```

第二条栈的 PC 是 `0x10DD15`，其余帧相同。两者对同 PIE 的静态偏移为 `0x5CED`、`0x5D15`，
在 `remote/evidence/pull/excerpts/on.probe.full.disasm` 中分别是
`5ced: 41 0f b7 34 08  movzwl (%r8,%rcx,1),%esi`（`%rcx` 由 `5cc6: lea ... # 10300 <platform_m3_message_bit_table>` 装入）
与其对称的第二条 `movzwl`，即人工秘密下标 LUT 的两次实际 load。
off 探针反汇编中 `platform_m3_message_bit_table` 出现 **0 次**（`grep -c` 结果 0）。

**补充证据**（同一批 ELF，标注为 supplementary）：

- `-s --num-callers=20` 复跑四组合：on/secret 仍 1280/2，其余 3 组 0/0（`remote/logs/supplementary/`）。
- 不在 Valgrind 下直跑探针：四组合全部 **exit 77** + `M3 localization probe requires Valgrind`
  （证明探针自身有守卫，不是普通运行冒充定位）。
- 探针 ELF 摘要（`remote/logs/binary-SHA256SUMS`）：
  on `896967e6b9abd6c8b2dd347ef02f52a127070a50b65eae12083df7af3715c993`，
  off `e7eb22aa52a2d06cb3ff7b417cac9ca8a7c10accbef05cc36de504a1aa72f678`；
  源码逐文件摘要 `remote/logs/source-SHA256SUMS`。
- 结束核对：树内无残留 `platform_m3`/`valgrind` 进程，符号链接清单为空（`remote/logs/final-check.log`）。

**结论**：这是**独立重跑**得到的结果，与上一轮 `native-8b6f2d91` 的 1280/2 vs 0/0 一致；本轮数值不是照抄，
而是新树新产物的新日志。定位阳性仅说明「on 版人工 LUT 的地址取决于被标记的秘密」，off 版与两个
defined 对照不报警**不等于**恒时证明。测量开销、运行时间与物理时差本轮**没有**测量。

---

## 2. Microwalk（D03）——逐项真实探测

### 2.1 .NET SDK：**成功（真实安装）**

| 步骤 | 命令 | 结果 |
|---|---|---|
| 取安装脚本 | `curl -sSL -o dotnet-install.sh https://dot.net/v1/dotnet-install.sh` | exit 0，63563 B，sha256 `082f7685e156738a1b2e2ed8381a621870d4ce8e8c59278034556f05c186eb2e` |
| 安装 SDK | `bash dotnet-install.sh --channel 8.0 --install-dir <新根>/microwalk-probe/dotnet --no-path --verbose` | exit 0 |
| 版本 | `<新根>/microwalk-probe/dotnet/dotnet --info` | **.NET SDK 8.0.426**，Host 8.0.32，linux-x64 |

原始日志：`remote/logs/a1-dotnet-install-script-download.log`、`a2-...`、`a3-dotnet-info.log`、`a4-dotnet-list-sdks.log`。
安装目录、`DOTNET_CLI_HOME`、`NUGET_PACKAGES`、`TMPDIR` 全部在新根内。

### 2.2 Intel Pin：**成功（真实下载 + 可执行）**

| 探测 | 结果 |
|---|---|
| `pin-3.31-98869-gfa6f126a8-gcc-linux.tar.gz` | HTTP 301 → 404（URL 不存在）；下回来的 69889 B 是 HTML，`tar -xzf` 失败 exit 2（失败原件保留在 `remote/logs/b5-pin-extract.log`） |
| `pin-3.28-98749-g6643ecee5-gcc-linux.tar.gz` | **HTTP/2 200**，`content-length: 36310237`，`application/octet-stream`；下载 exit 0，sha256 `5a5a3337f3f16176b97edcd3366b561936e1068fba4ebcfed4b836d81d45847b` |
| 解包 | `tar -xzf` exit 0，得到 `pin doc extras ia32 intel64 licensing source ...` |
| 运行 | `<pin>/pin -version` → `Pin: pin-3.28-98749-6643ecee5  Copyright 2002-2023 Intel Corporation.` |
| 许可 | 包内含 `licensing/intel-simplified-software-license.txt`、`LICENSE-llvm`、`LICENSE-mit.txt` 等（`remote/logs/f6-pin-328-license.log`） |

### 2.3 Docker：**不可用于本项目（边界与权限双重阻塞）**

| 探测 | 原始结果 |
|---|---|
| `docker version` / `docker info` | 客户端与服务端 **29.1.3** 均在，`Driver=overlayfs` |
| `docker info --format '{{.DockerRootDir}}'` | **`/home/docker-data`**（在 Cry 物理边界之外） |
| 修法 1：`dockerd --data-root=<新根>/docker-data ...` | `unable to configure the Docker daemon with file /etc/docker/daemon.json: the following directives are specified both as a flag and in the configuration file: data-root` |
| 修法 2：`dockerd --config-file <新根>/empty-daemon.json --data-root=<新根>/docker-data2 ...` | `dockerd needs to be started with root privileges. To run dockerd in rootless mode as an unprivileged user, see https://docs.docker.com/go/rootless/` |
| 修法 3：`docker pull` 是否可指定存储位置 | `docker pull --help` 无任何 data-root 选项；`/etc/docker/daemon.json` 固定 `"data-root": "/home/docker-data"` |

因此**没有执行任何 `docker pull`、没有创建容器**：镜像层会写进 `/home/docker-data`，越出
`/home/nss-marker/yhr/Cry` 唯一存放边界；且无 root 也无法把守护进程的数据根改到 Cry 内。
原始输出：`remote/logs/d1-...`、`d2-docker-images-readonly.log`、`d3-dockerd-nonroot-cry-dataroot.log`。

### 2.4 ghcr 镜像与 Microwalk 源码：**网络可达（只读读取，落盘在 Cry 内）**

| 探测 | 结果 |
|---|---|
| `https://ghcr.io/v2/` | HTTP **401**（说明可达，需匿名 token） |
| token | `https://ghcr.io/token?scope=repository:microwalk-project/microwalk:pull&service=ghcr.io` → HTTP 200 |
| `manifests/pin` | HTTP **200**，`application/vnd.docker.distribution.manifest.v2+json`；config `sha256:bdeee1e1bd59…`（7209 B），**19 层，合计 273823514 B ≈ 261.1 MiB**（`remote/microwalk-probe/ghcr/manifest-index.json`） |
| `tags/list` | HTTP 200，含 `pin`、`3.2.0-pin` … `3.0.0-pin` |
| Microwalk 源码 | `codeload.github.com/.../Microwalk/tar.gz/refs/heads/master` exit 0，357435 B，sha256 `932cc295c6281b6ff6900dec0ce2642751217e6d049a8e2ea09a49d252229dd1`；`git clone --depth 1` 在本网络下 90 s 未完成（被 `codeload` 路径替换，`remote/logs/c4-git-clone-microwalk.log` 保留） |
| `api.github.com` release 查询 | 见 `remote/logs/c1-...`、`c2-...`、`c3-github-api-pin-action-repo.log` |

镜像层**未下载**（决定不把 261 MiB 拉进 Cry，因为没有 Docker 也用不上；manifest/config 已足以证明可达性）。

### 2.5 Microwalk 端到端**真实运行**：成功（自建工具链）

在新根内从源码构建并运行，全程无 Docker、无 root：

```
dotnet build Microwalk/Microwalk.csproj -c Release                    # exit 0
dotnet build Microwalk.Plugins.PinTracer/...csproj -c Release          # exit 0
dotnet build Tools/MapFileGenerator/MapFileGenerator.csproj -c Release # exit 0
cd PinTracer && mkdir -p obj-intel64 && make PIN_ROOT=<pin> obj-intel64/PinTracer.so   # exit 0
```
（第一次 `make` 因 `obj-intel64/` 不存在而失败：`can't create obj-intel64/CpuOverride.o`；
建目录后成功，产物 `PinTracer.so` 1960000 B。第一次 Microwalk 调用还把 config 放在 `-p` 之后，
报 `Could not find plugin directory ...config.yml`，改为 `<config> -p <plugin-dir>` 后成功。
两次失败原件分别保留在 `remote/logs/g5-make-pin-tool.log`、`remote/logs/g10-template-microwalk-run.log`。）

用 Microwalk 自带 C 模板（`templates/c`，即它自己的 example）跑通整条流水线：

```
00:00:00 [info] Found 16 testcase files.
00:00:00 [info] Start testcase thread -> pipeline start
00:00:00 [info] Pipeline completed, executing final analysis steps
00:00:00 [rslt] [analyze:cfl] Total number of leakages: 2
00:00:00 [rslt] [analyze:cfl] Unique leaking instructions: 2
00:00:01 [info] Program completed.
```
生成 17 份原始/预处理轨迹与 `persist/target-example/results/{call-stacks.json,call-stacks.txt}`，
原件在 `remote/microwalk-probe/template-run/run/persist/`。

### 2.6 本项目 M3 夹具上的 Microwalk：**成功**（本轮最强的一条）

做法：把**同一份补丁 overlay**（`build-ordinary/platform-m3-{on,off}-source/mlkem`）编译成
`libm3{on,off}.so`，用 Microwalk 模板的 `main.c` 加一个 `m3mwtarget.c`（`InitTarget` 用公开固定种子
`20261016` 生成密钥对，`RunTarget` 读 1 字节输入类下标 → 生成对应密文 → `mlkem_decapsulate`），
5 个 testcase 分别是 `valid / bit-flipped / random / message-zero / message-ones`。

| 项 | on 臂 | off 臂 |
|---|---|---|
| `control-flow-leakage` 报告 | 6 leakages / 6 unique | 4 leakages / 4 unique |
| 命中位置 | 全在 `libm3on.so:generate_test_ciphertext+2a/63/6b/c6/...`（测试用例准备阶段，不是解封装） | 同为 `generate_test_ciphertext` 系列 |
| 内存访问轨迹泄漏模块 | 568 条指令，454 条 MI>0 | 564 条，450 条 MI>0 |
| **MI 最高的指令** | **`baseline_native_poly_frommsg+30` 与 `+59`，各 1.922 bits** | `poly_frommsg+1c`/`+3e`，**0.722 bits**（与其余指令同级） |

关键交叉验证（反汇编原件 `remote/evidence/pull/excerpts/libm3on.poly_frommsg.disasm`）：

```
0000000000002a20 <baseline_native_poly_frommsg>:
    2a22: lea    0x4657(%rip),%rcx        # 7080 <platform_m3_message_bit_table>
    ...
    2a50: movzwl (%r10,%rcx,1),%r8d        # ← 函数内偏移 +0x30
    ...
    2a79: movzwl (%r9,%rcx,1),%edx         # ← 函数内偏移 +0x59
```
`+0x30` / `+0x59` 正是 Microwalk 报出的两个 MI 峰值；off 的 `libm3off.so` 中
`platform_m3_message_bit_table` 符号**不存在**（`objdump -t | grep -c` = 0），
其 `poly_frommsg` 走 `mlk_value_barrier_u8` + `mlk_ct_sel_int16`。

也就是说：**ctgrind/Memcheck 与 Microwalk 两条独立方法指向同一对指令**——探针里被标记的
`0x5CED/0x5D15`（内联副本，`%rcx` = `platform_m3_message_bit_table`）与该 .so 里
`poly_frommsg+0x30/+0x59` 的两次 `movzwl` 是同两处秘密下标 load。

**限制（不得升级）**：

- 只有 **5 个公开 testcase、无重复、无统计检验**；MI 是点估计，不能作泄漏量结论。
- 两臂 testcase 逐字节相同，但两臂是**不同 ELF**，跨臂只能按函数级对齐比较，不能逐偏移比较。
- 输入本身按类变化，两臂都有 450+ 条 MI>0 的指令，这是公开输入变化的基线噪声；
  有判别力的是 on 臂在 `poly_frommsg` 上的**抬升**，不是"有 MI 就是泄漏"。
- 控制流模块的命中落在**测试用例准备**代码（`generate_test_ciphertext`）而非解封装本体，
  不能当成解封装控制流泄漏。
- Microwalk 按公开 testcase 间轨迹差异判定，**不做秘密污点**；它是 D02 的独立佐证，
  不能替代 ctgrind 的秘密标记定位，也不是可利用性证明。
- 本轮用的是**源码自建**的 Microwalk 3.x master + 自建 Pin 工具（Pin 3.28），
  不是官方 `ghcr.io/microwalk-project/microwalk:pin` 镜像（镜像因 §2.3 未拉取、未运行）。

### 2.7 D03 结论

**Microwalk 真实跑通了，不需要降级到"仅 ctgrind"**：.NET 与 Pin 都在 Cry 内真实安装成功，
Microwalk 与 Pin 工具真实编译成功，并对本项目 M3 on/off 夹具产出了原始轨迹、原始报告。
唯一的"降级"是**载体替换**：用源码自建工具链取代官方 Docker 镜像（Docker 存储越界 + 无 root，
证据见 §2.3），而不是"没跑起来"。Docker/镜像那一条路记为 **blocked_by_boundary_and_privilege**，
不记为"未检出"，也不把 clone 成功当运行成功（本轮的运行证据是 §2.5/§2.6 的 `[rslt]` 输出与报告文件）。

---

## 3. 追加项 B：M3 online dudect

### 3.1 阻塞一：导出源码缺 `third_party/`

`source/` 的 348 文件导出**不含 `third_party/`**（新旧两棵树都一样），而
`cmake/PlatformM5Tools.cmake` 的 dudect 目标条件是
`EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/dudect/src/dudect.h"`，所以目标一开始根本不存在
（`cmake --build . --target help | grep dudect` 无输出）。
修法：把本机 `third_party/dudect`（排除 `.git`，65 文件）传进新根 `source/third_party/dudect`；
`dudect.h` sha256 `3fb3b2bd7f9e17ae34b7c92518c1311c67342c56facc80da925d85f121b649da` 与本机一致。
重新 configure 后 `platform_m5_dudect` 目标出现并构建成功。

### 3.2 阻塞二：标准目标量的是 reference，且守卫拒绝 M3 两臂

`remote/logs/b6-dudect-linkline.log` 的原始链接行：

```
/usr/bin/clang -O2 -g -DNDEBUG CMakeFiles/platform_m5_dudect.dir/tools/platform_m5/dudect.c.o \
    -o platform_m5_dudect  reference/libmlkem.a -lm
```
它链接的是 `mlkem_reference`（`src/kernel.c` + vendor 上游），**不是** M3 on/off overlay；
`remote/logs/b7-dudect-selftest.log` → `--self-test` exit 0（量的是 reference）。
而 `dudect.c` 第 45 行守卫 `strcmp(mlkem_implementation_name(), "reference") != 0` 让
手工链到两臂的版本直接拒绝：`remote/logs/b11-m3dudect-{on,off}-selftest.log` 均为 **exit 1、无任何输出**。
`--describe` 不是本工具的参数（`remote/logs/b8-dudect-describe.log`：usage + exit 2）。

### 3.3 主控要求的最小改动（**已做，且只改守卫与注释**）

改动只在**远端新根 `source/tools/platform_m5/dudect.c`** 一处；原件另存
`remote/evidence/dudect.c.original`（sha256 `8beb2994757ee0d81b0a6207f7b1502fdc66019cc9e126afb46e67a9ebb2a367`），
改后 sha256 `67eb4dca28f4d1d4ed33a34c8c76aab4d40b7c68e725eacf023482fbd2166d58`：

```diff
-    return strcmp(mlkem_implementation_name(), "reference") != 0;
+    /* 采数准入：M5 参考臂与 M3 人工 LUT 夹具的开/关两臂共用同一套自检；
+       其他实现名仍拒绝，避免把未审查的实现当成可采数对象。 */
+    const char *implementation_name = mlkem_implementation_name();
+    return strcmp(implementation_name, "reference") != 0 &&
+        strcmp(implementation_name, "platform-m3-lut-on") != 0 &&
+        strcmp(implementation_name, "platform-m3-lut-off") != 0;
```
统计内核、`M5_DUDECT_MEASUREMENTS_PER_BATCH=10000`、`M5_DUDECT_MAXIMUM_BATCHES=21`、
类顺序（`message-zero` vs `message-ones`）、输出格式均未动（`remote/logs/c3-diff.log` 只有这一段 hunk）。

**本仓库工作树里的 `tools/platform_m5/dudect.c` 我没有改**：它是共享工作区，比对发现该文件
在本轮导出之后已被其他协作者改过（本地 sha256 `64e5e80a8c4047f691126c512753627ece7ae558fb600e97087f10deb8bcb07b`
≠ 远端导出原件 `8beb2994…`）。落库由主控决定，diff 见上。

### 3.4 两臂重建与自检（exit 0）

```
clang -O2 -g -DNDEBUG -std=c11 -DMLK_CONFIG_FILE='"baseline_config.h"' \
  -DPLATFORM_IMPLEMENTATION_NAME='"platform-m3-lut-on"' -DPLATFORM_M3_LUT_LEAK=1 \
  -I build-ordinary/platform-m3-on-source/mlkem -I source/include \
  -I source/vendor/mlkem-native/mlkem -I source/third_party/dudect/src \
  source/tools/platform_m5/dudect.c source/src/inputs.c \
  build-ordinary/platform-m3/on/libmlkem.a -lm -o microwalk-probe/m3dudect-on
```
（off 臂把 `on`→`off`、`LEAK=1`→`0`。）

| 臂 | 绝对路径 | sha256 | `--self-test` |
|---|---|---|---|
| on | `<新根>/microwalk-probe/m3dudect-on` | `8ae8979f7d521411f478c4097ce25d6cbf74ce965810a5ac3fd89183e8a1c66a` | **exit 0** |
| off | `<新根>/microwalk-probe/m3dudect-off` | `73a2b04223fb46d83e534ccd1f270979f8de846f0e188edfc1c8cd6a5ac12006` | **exit 0** |

原始输出（`remote/logs/c7-selftest-{on,off}.log`）：

```
M5 dudect callback self-test passed; no clocks or collection invoked
selftest_exit=0
```

实现名用独立小程序实测（不是 `strings` 猜的，`remote/logs/d2-implname-{on,off}.log`）：
`implementation=platform-m3-lut-on` / `implementation=platform-m3-lut-off`。
另外 `m3dudect-on` 反汇编里出现 `platform_m3_message_bit_table` 的 `lea`+`movzwl`，
`m3dudect-off` 同函数是 `mlk_value_barrier_u8`/`mlk_ct_sel_int16` 版本
（`remote/evidence/pull/excerpts/m3dudect-{on,off}.poly_frommsg.disasm`）。

### 3.5 `--collect` 的确切命令行（**本轮未执行**）

**本 ELF（远端导出那一版 `dudect.c`）的形态是**：

```
<新根>/microwalk-probe/m3dudect-on  --collect --seed <十进制无符号整数>
<新根>/microwalk-probe/m3dudect-off --collect --seed <同上的同一 N>
```
- 4 个 argv；没有 `--raw`、没有 CSV 输出，也没有 `--describe`。
- 不需要 pk/sk：密钥对、两类密文都由 `--seed N` 内部派生（`prepare_class_pair`）。
- 批量：`measurements_per_batch=10000`，`maximum_batches=21`，类为 `message-zero`/`message-ones`，
  计时用上游 dudect 的 rdtsc，结果消费在每批之后。
- **每臂各起一个进程、串行、不并发**（工具内部按批循环，跨臂并行会互相污染计时）。
- 输出只有 stdout 两行：`module=M5 backend=reference seed=... classes=... measurements_per_batch=... maximum_batches=...`
  与 `stopped_after_batches=... state=...`。
- ⚠ **版本差异**：本机仓库当前的 `dudect.c`（`64e5e80a…`）已经加了
  `--self-test-raw <path>` 与 `--collect --seed N --raw NEW.csv`（逐样本 CSV）。
  若采数需要逐样本 CSV，必须**重新导出源码再重建**本文件的两个 ELF；上面这两个 ELF
  对应的是**旧版 CLI（无 CSV）**。这一点请主控在 PLAN 里按需选择。
- 我按要求**没有**运行任何合法形态的 `--collect`；只跑了参数不合法形态取 usage
  （`--collect --seed 1 --raw probe.csv` → usage，exit 2，未进入采集），见 `remote/logs/d5-collect-usage-form.log`。
- 主控独立实测同一形态也得到 `exit 2` + `usage: platform_m5_dudect --self-test | --collect --seed N`，
  与本节结论一致：**M3 版没有 `--raw`**。
- **没有落盘文件**：这一版采集不写任何 CSV/原始样本文件，唯一产物是 stdout 两行。
  建议主控采集时用 `... --collect --seed N > <新根>/logs/collect-<arm>-<时间戳>.stdout.log 2>&1`
  在 Cry 内留原件；如需逐样本 CSV，先重新导出源码（§3.5 版本差异）再重建两个 ELF。

---

## 4. 追加项 A：M3 采数树指定

新根普通构建 **CTest 6/6 通过**，四组合 Memcheck 也已在**该树产物**上跑通（§1），因此可以作采数树。

```
$ ls -l <新根>/build-ordinary/platform-m3/on/measure <新根>/build-ordinary/platform-m3/off/measure
-rwxrwxr-x 1 nss-marker nss-marker 248544 10月 16 02:07 .../platform-m3/on/measure
-rwxrwxr-x 1 nss-marker nss-marker 248928 10月 16 02:07 .../platform-m3/off/measure
$ sha256sum ...
a371ed089e857d92069dbd670afab2f0de546e0042be869bba7c9c5da680a1f7  .../platform-m3/on/measure
8daaea28ffe97cb71800195e6113245080205f3d044859709834c22d99b4425d  .../platform-m3/off/measure
```
（`remote/logs/c9-measure-identity.log`；同名两文件在旧根是 `fe5435ba…` / `d62e3912…`，
字节不同只源于构建路径/调试信息，源 export 同一份、348/348 校验通过。旧根未被改动。）

**注意**：这两个 `measure` 我**只构建、未执行**（`tools/platform_m3/README.md` 规定统计草案冻结前不执行）。
采数放行后由主控决定是否需要用新根重跑，`--parallel` 与 `build-ordinary` 目录下还有
`platform_m5_dudect`（reference 版）与手工链接的 `m3dudect-{on,off}`。

---

## 5. 遗留缺口（不主张）

1. `measure` 未执行；没有采数、没有调频、没有 MSR/隔离写入，`restore_match` 不适用。
2. Microwalk 结论基于 5 个公开 testcase 的点估计，无重复、无统计检验，不能作为泄漏量或
   "on 比 off 差多少"的定量结论；也**不是**物理时差或可利用性证明。
3. 官方 `ghcr.io/microwalk-project/microwalk:pin` 镜像**未拉取、未运行**；Docker 路径被
   「存储越界 + 无 root」双重阻塞（§2.3）。镜像 manifest/config 只是可达性证据。
4. 远端新根 `source/` 相对 348 文件导出多了 `third_party/dudect`（新增）与被改写的
   `tools/platform_m5/dudect.c`（守卫），其余文件未动；`SOURCE_EXPORT.sha256` 校验仍通过
   （校验清单不含这两者）。
5. `call-tree-dump.txt`（各 ~130 MB）只留在远端；本地仅有前 200000 字节摘录。
6. 未对 Microwalk 报告做进一步统计加工；`results-memory/*.txt` 是 Microwalk 原始输出。
7. 本文件不冻结 `PLAN.md` 的采数合同；`PLAN.md` 的类名/CLI 口径应与 §3.5 的版本差异一起复核。

## 6. 复核入口

- `locate-v2/remote/logs/`：全部原始命令、stdout/stderr、退出码（`*.log` 内含 `### cmd`、`### exit`）。
- `locate-v2/remote/logs/{on,off}-{secret,defined}.{memcheck,stdout,stderr}.log` + `.exit`：四组合原件。
- `locate-v2/remote/logs/combos.summary`、`binary-SHA256SUMS`、`source-SHA256SUMS`。
- `locate-v2/remote/microwalk-probe/`：dotnet 安装信息、Pin 摘要、ghcr manifest/tags、
  M3 的 `config3.yml` 与 `libm3{on,off}.map`/目标 MAP、`work3-{on,off}/persist/**`（原始报告）。
- `locate-v2/remote/evidence/pull/excerpts/`：两臂 `poly_frommsg` 反汇编、探针完整反汇编、
  调用树摘录、摘要文件。
- `locate-v2/remote/evidence/dudect.c.original` 与 `locate-v2/remote/logs/c3-diff.log`：守卫改动前后。
- `locate-v2/SHA256SUMS`、`locate-v2/PULL.txt`：拉回完整性与未拉回清单。
