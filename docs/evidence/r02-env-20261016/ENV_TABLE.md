# T07 环境总表（2026-10-16，主机 `nss-m`）

本文件把本轮（R02/T07—T09）所依据的**真实机器、工具链、编译行、计时源、CPU/频率/中断状态**
集中登记。每一项都给出**原始命令**与**原始输出**；长输出给出摘录并指向 `raw/` 下的完整原文。

- 采集方式：**只读**。远端只执行 `lscpu` / `cat` / `--version` / `openssl dgst` 一类命令；
  没有写远端任何已存在文件、没有 `sudo`、没有安装任何包。
- 唯一的远端写入是 T07 读钟探针自身：新根 `Cry/r02-env-20261016-cad9a98501db/`
  （含显式 `TMPDIR=$ROOT/tmp`），只放该探针的源码、ELF 与临时目录，见 §4.3。
- 远端命令一律不绑定 CPU2/CPU6（主控稍后要在 CPU2/CPU6 上做锁频采集）。
- 完整原文：[`raw/remote-env.txt`](raw/remote-env.txt)（本文件 §1/§2/§5/§6/§7）、
  [`raw/compile-lines.txt`](raw/compile-lines.txt)（§3）、
  [`raw/clock-probe.txt`](raw/clock-probe.txt)（§4.3）、
  [`raw/clock-overhead-archive.txt`](raw/clock-overhead-archive.txt)（§4.4）、
  [`raw/irq-and-isolation.txt`](raw/irq-and-isolation.txt)（§5）。

## 0. 覆盖清单（28 项，全部有原始命令与原始输出）

| # | 项 | 状态 | 出处 |
|---:|---|---|---|
| 1 | `lscpu` | 完整 | §1.6 |
| 2 | `uname -a` | 完整 | §1.1 |
| 3 | `/etc/os-release` | 完整 | §1.2 |
| 4 | `/proc/cmdline` | 完整 | §1.3 |
| 5 | `nproc` | 完整 | §1.4 |
| 6 | 内存 | 完整 | §1.4 |
| 7 | clang 版本 | 完整 | §2 |
| 8 | gcc 版本 | 完整 | §2 |
| 9 | cmake 版本 | 完整 | §2 |
| 10 | ninja 版本 | 完整 | §2 |
| 11 | valgrind 版本 | 完整 | §2 |
| 12 | binsec 版本 | 未安装（历史仅 M4 运行时 opam root，现已无二进制） | §2.2 |
| 13 | z3 版本 | 不在 PATH；M4 运行时目录内 4.15.3 | §2.2 |
| 14 | 实际编译行：M1 两版 | 完整，含 ELF 摘要核验 | §3.2 |
| 15 | 实际编译行：M2 两版 | 完整，含 ELF 摘要核验 | §3.3 |
| 16 | 实际编译行：M3 on/off | 完整，含 ELF 摘要核验 | §3.4 |
| 17 | 实际编译行：M4 两臂 | 完整，含 ELF 摘要核验 | §3.5 |
| 18 | 实际编译行：M5 | 完整，含 ELF 摘要核验 | §3.6 |
| 19 | 计时源：各采集件 clock | 完整（含 dudect 的 rdtsc） | §4.1 |
| 20 | `clock_resolution_ns` | 完整（M4 的 `.meta` 未记，实测补上） | §4.2 |
| 21 | 读钟开销实测（n≥10000；均值/中位数/p99） | 完整（新探针 n=100000×2；既有归档 n=300000） | §4.3 / §4.4 |
| 22 | SMT 状态 | 完整 | §5.1 |
| 23 | `isolcpus` | 完整（**无** isolcpus） | §5.2 |
| 24 | IRQ 亲和（`/proc/interrupts` 摘录 + CPU2/6 相关行） | 完整 | §5.3 |
| 25 | 后台服务快照 | 完整（39 个 running service） | §6 |
| 26 | `/sys/.../cpufreq/boost` | 完整 | §7 |
| 27 | CPU2 / CPU6 的 policy | 完整 | §7 |
| 28 | `amd_pstate` 状态 | 完整 | §7 |

---

## 1. 主机与内核

采集时刻（本机 UTC）：`2026-10-15T19:59:47Z`。
命令与输出原文见 [`raw/remote-env.txt`](raw/remote-env.txt)；以下逐项引用。

### 1.1 主机名与内核

```console
$ ssh nss-marker@10.144.144.5 'hostname; echo "---"; uname -a'
nss-m
---
Linux nss-m 6.17.0-35-generic #35~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Tue May 26 19:30:42 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
```

### 1.2 发行版

```console
$ ssh nss-marker@10.144.144.5 'cat /etc/os-release'
PRETTY_NAME="Ubuntu 24.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.4 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
```

### 1.3 内核命令行（`isolcpus` 判定的第一手依据）

```console
$ ssh nss-marker@10.144.144.5 'cat /proc/cmdline'
BOOT_IMAGE=/boot/vmlinuz-6.17.0-35-generic root=UUID=4a69ef09-597f-4e06-b988-36525528f82c ro quiet splash vt.handoff=7
```

行内**没有** `isolcpus=`、没有 `nohz_full=`、没有 `rcu_nocbs=`。另见 §5.2。

### 1.4 逻辑 CPU 与内存

```console
$ ssh nss-marker@10.144.144.5 'nproc; echo "---"; getconf _NPROCESSORS_ONLN; echo "---"; free -k; echo "---"; head -3 /proc/meminfo'
32
---
32
---
               total        used        free      shared  buff/cache   available
内存：      63385244     9489292      962968       73244    53718688    53895952
交换：       8388604     1579324     6809280
---
MemTotal:       63385244 kB
MemFree:          962968 kB
MemAvailable:   53895952 kB
```

要点：**32 个在线逻辑 CPU**，`MemTotal = 63385244 kB ≈ 60.4 GiB`，swap 8388604 kB。

### 1.5 时钟源与开机身份

```console
$ ssh nss-marker@10.144.144.5 'cat /sys/devices/system/clocksource/clocksource0/current_clocksource; echo "--- available"; cat /sys/devices/system/clocksource/clocksource0/available_clocksource; echo "--- uptime"; cat /proc/uptime; echo "--- boot_id"; cat /proc/sys/kernel/random/boot_id'
tsc
--- available
tsc hpet acpi_pm 
--- uptime
3895385.67 124249010.99
--- boot_id
1d5a4300-d997-4a45-a9d6-95165d68dcd9
```

`boot_id = 1d5a4300-d997-4a45-a9d6-95165d68dcd9` 与平台采集 `command.json` 里记录的 `boot_id`
逐字相同，说明 T07 与 T05 采集**同一次开机**。

### 1.6 `lscpu`（完整）

```console
$ ssh nss-marker@10.144.144.5 'lscpu'
架构：                                   x86_64
CPU 运行模式：                           32-bit, 64-bit
Address sizes:                           48 bits physical, 48 bits virtual
字节序：                                 Little Endian
CPU:                                     32
在线 CPU 列表：                          0-31
厂商 ID：                                AuthenticAMD
型号名称：                               AMD Ryzen 9 9950X 16-Core Processor
CPU 系列：                               26
型号：                                   68
每个核的线程数：                         2
每个座的核数：                           16
座：                                     1
步进：                                   0
Frequency boost:                         启用
CPU(s) scaling MHz:                      54%
CPU 最大 MHz：                           5756.4521
CPU 最小 MHz：                           624.1940
BogoMIPS：                               8583.30
标记：                                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good amd_lbr_v2 nopl xtopology nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpuid_fault cpb cat_l3 cdp_l3 hw_pstate ssbd mba perfmon_v2 ibrs ibpb stibp ibrs_enhanced vmmcall fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a avx512f avx512dq adx smap avx512ifma clflushopt clwb avx512cd sha_ni avx512bw avx512vl xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local user_shstk avx_vnni avx512_bf16 clzero irperf xsaveerptr rdpru wbnoinvd cppc arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold v_vmsave_vmload vgif v_spec_ctrl vnmi avx512vbmi umip pku ospke avx512_vbmi2 gfni vaes vpclmulqdq avx512_vnni avx512_bitalg avx512_vpopcntdq rdpid bus_lock_detect movdiri movdir64b overflow_recov succor smca fsrm avx512_vp2intersect flush_l1d amd_lbr_pmc_freeze
虚拟化：                                 AMD-V
L1d 缓存：                               768 KiB (16 instances)
L1i 缓存：                               512 KiB (16 instances)
L2 缓存：                                16 MiB (16 instances)
L3 缓存：                                64 MiB (2 instances)
NUMA 节点：                              1
NUMA 节点0 CPU：                         0-31
Vulnerability Gather data sampling:      Not affected
Vulnerability Ghostwrite:                Not affected
Vulnerability Indirect target selection: Not affected
Vulnerability Itlb multihit:             Not affected
Vulnerability L1tf:                      Not affected
Vulnerability Mds:                       Not affected
Vulnerability Meltdown:                  Not affected
Vulnerability Mmio stale data:           Not affected
Vulnerability Old microcode:             Not affected
Vulnerability Reg file data sampling:    Not affected
Vulnerability Retbleed:                  Not affected
Vulnerability Spec rstack overflow:      Mitigation; IBPB on VMEXIT only
Vulnerability Spec store bypass:         Mitigation; Speculative Store Bypass disabled via prctl
Vulnerability Spectre v1:                Mitigation; usercopy/swapgs barriers and __user pointer sanitization
Vulnerability Spectre v2:                Mitigation; Enhanced / Automatic IBRS; IBPB conditional; STIBP always-on; PBRSB-eIBRS Not affected; BHI Not affected
Vulnerability Srbds:                     Not affected
Vulnerability Tsa:                       Not affected
Vulnerability Tsx async abort:           Not affected
Vulnerability Vmscape:                   Mitigation; IBPB on VMEXIT
```

要点：AMD Ryzen 9 9950X、**16 核 × 2 SMT = 32 线程**、单 socket、单 NUMA 节点、
`constant_tsc` + `nonstop_tsc` + `rdtscp`（dudect 臂用 `rdtsc` 的前提）、
L2 16 MiB、L3 64 MiB。

GPU / 网卡（只作环境描述）：

```console
$ ssh nss-marker@10.144.144.5 'nvidia-smi -L 2>&1 | head -3; echo "--- lspci net"; lspci 2>/dev/null | grep -i -E "ethernet|network" | head -5'
GPU 0: NVIDIA GeForce RTX 4090 (UUID: GPU-94550b01-cd83-b86d-2d92-2789357e25ca)
--- lspci net
07:00.0 Ethernet controller: Realtek Semiconductor Co., Ltd. RTL8125 2.5GbE Controller (rev 0c)
08:00.0 Network controller: MEDIATEK Corp. Device 7925
```

---

## 2. 工具链版本

### 2.1 路径探测

```console
$ ssh nss-marker@10.144.144.5 'for t in clang clang-18 gcc g++ cmake ninja valgrind binsec z3 python3 openssl taskset; do p=$(command -v "$t" 2>/dev/null || true); if [ -n "$p" ]; then printf "%s\t%s\n" "$t" "$p"; else printf "%s\tNOT-INSTALLED\n" "$t"; fi; done'
clang	/usr/bin/clang
clang-18	/usr/bin/clang-18
gcc	/usr/bin/gcc
g++	/usr/bin/g++
cmake	/usr/bin/cmake
ninja	/usr/bin/ninja
valgrind	/usr/bin/valgrind
binsec	NOT-INSTALLED
z3	NOT-INSTALLED
python3	/usr/bin/python3
openssl	/usr/bin/openssl
taskset	/usr/bin/taskset
```

### 2.2 版本字符串

```console
$ ssh nss-marker@10.144.144.5 'clang --version; echo "---"; clang-18 --version; echo "---"; gcc --version | head -1; echo "---"; cmake --version | head -1; echo "---"; ninja --version'
Ubuntu clang version 18.1.3 (1ubuntu1)
Target: x86_64-pc-linux-gnu
Thread model: posix
InstalledDir: /usr/bin
---
Ubuntu clang version 18.1.3 (1ubuntu1)
Target: x86_64-pc-linux-gnu
Thread model: posix
InstalledDir: /usr/bin
---
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
---
cmake version 3.28.3
---
1.11.1
```

```console
$ ssh nss-marker@10.144.144.5 'valgrind --version 2>&1 | head -2; echo "---"; binsec -version 2>&1 | head -5; echo "---"; z3 --version 2>&1 | head -2'
valgrind-3.22.0
---
bash: 行 1: binsec: 未找到命令
---
bash: 行 1: z3: 未找到命令
```

| 工具 | 系统 PATH 版本 |
|---|---|
| clang / clang-18 | Ubuntu clang 18.1.3 (1ubuntu1) |
| gcc | 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04.1) |
| cmake | 3.28.3 |
| ninja | 1.11.1 |
| valgrind | 3.22.0 |
| **binsec** | **未安装**（PATH 中无） |
| **z3** | **未安装**（PATH 中无） |

**binsec / z3 的准确说法**（不是"从来没装过"）：

```console
$ ssh nss-marker@10.144.144.5 'R=/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH; ls $R/opam; echo "### binsec find"; find $R/opam -maxdepth 6 -name binsec -type f 2>/dev/null | head -5; echo "### z3"; $R/runtime/z3-4.15.3-x64-glibc-2.39/bin/z3 --version'
config
config.lock
download-cache
lock
log
opam-init
repo
### binsec find
### z3
Z3 version 4.15.3 - 64 bit
```

- M4 轮次曾用 opam 在 `Cry/platform-m4-20261016-6hRHRUxH/opam`（`OPAMROOT`，非系统）
  安装 **binsec 0.11.3**（`opam-installed.txt`、`binsec-version.log` =
  `Binsec version 0.11.3`）。**当前该 opam root 下已找不到 binsec 可执行文件**
  （`find -maxdepth 6 -name binsec -type f` 为空），系统 PATH 也没有。
- z3 曾以发行包放在同一运行时的 `runtime/z3-4.15.3-x64-glibc-2.39/bin/z3`，
  **现在仍存在**，`--version` = `Z3 version 4.15.3 - 64 bit`（另一个 4.13.4 包的同轮记录见
  `docs/evidence/m4-completion-20261016/runtime/runtime-logs/z3-4.13.4-release.json`）。
- 因此本轮**没有**执行任何 binsec / z3 分析；T07—T09 全部结论不依赖它们。

---

## 3. 实际编译行

### 3.1 取法（为什么不是"从模块证据目录里那份 compile_commands.json 抄"）

被测 ELF 的构建树以**每次 run 的 `controller/command.json`**（控制器逐字落盘的实际命令行）
为准。核对发现三处与模块证据目录里另存的构建树不一致，已逐条登记（§8）：

| 模块 | 被测 ELF（`command.json` 原文） | 构建树 |
|---|---|---|
| M1 未修 | `.../build/historical-clangover/historical/measure` | 与 `.meta` 的 `compile_commands=` 一致 |
| M1 已修 | `.../build/historical-fixed-982c762/historical/measure` | 与 `.meta` 的 `compile_commands=` 一致 |
| M2 未修/已修 | `platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/{unfixed,fixed}/m2_decaps_collector` | **不是** `platform-m2kem-.../build-ordinary`；该 collector 树没有 `compile_commands.json` |
| M3 on/off | `platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/{on,off}/measure` | **不是** `platform-m3-20261016-8b6f2d91` |
| M4 vuln/ct | `platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_{vulnerable,ct}` | **不是** 证据里记的 `build-software-v2` / `source-v2` |
| M5 | `platform-m5-20261016-30efdf66eb26/build-v2-ordinary/reference/measure` | 与 `.meta` 的 `compile_commands=` 一致 |

编译行取自各树的 `compile_commands.json`（M3/M5/M1 有）或 CMake 的
`CMakeFiles/<target>.dir/flags.make` + `link.txt` + `build.make` 编译规则（M2/M4 无
`compile_commands.json`，因为生成器是 Unix Makefiles 且未开 `CMAKE_EXPORT_COMPILE_COMMANDS`）。

完整原文：[`raw/compile-lines.txt`](raw/compile-lines.txt)（529 行）。

### 3.2 M1（liboqs 0.10.0 历史复测，未修 / 已修）

应用层（`historical_measure`，含计时窗口的 TU）：

```console
$ ssh ... "python3 - 'measure|poly' .../build/historical-clangover/compile_commands.json"
TARGET CMakeFiles/historical_measure.dir/src/measure.c.o
  RAW   /usr/bin/clang -DBASELINE_HISTORICAL=1 \
        -I.../build/historical-clangover/generated/RelWithDebInfo -I.../include \
        -isystem .../build/historical-clangover/liboqs010-install/include \
        -O2 -g -DNDEBUG -std=c11 \
        -o CMakeFiles/historical_measure.dir/src/measure.c.o -c .../src/measure.c
```

liboqs 0.10.0 子构建（`poly.c` 所在目标，两臂相同）：

```console
$ ssh ... "python3 - 'poly|indcpa|kem' .../build/historical-clangover/liboqs010-build/compile_commands.json"
TARGET CMakeFiles/ml_kem_768_ipd_ref.dir/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/poly.c.o
  FLAGS -Os -fno-vectorize -Os -fno-vectorize -g -DNDEBUG -std=gnu11 -fPIC \
        -fvisibility=hidden -Wa,--noexecstack -g3 -fno-omit-frame-pointer -DKYBER_K=3
```

| 项 | M1 未修 | M1 已修 |
|---|---|---|
| 编译器 | `/usr/bin/clang`（18.1.3） | 同左 |
| 应用层选项 | `-O2 -g -DNDEBUG -std=c11` + `-DBASELINE_HISTORICAL=1` | 同左 |
| liboqs 子构建选项 | `-Os -fno-vectorize -Os -fno-vectorize -g -DNDEBUG -std=gnu11 -fPIC -fvisibility=hidden -Wa,--noexecstack -g3 -fno-omit-frame-pointer -DKYBER_K=3` | 同左（`-Os -fno-vectorize` 出现两次，后面没有另一个 `-O`） |
| 关闭 AVX2 分发 | CMake 侧 `-DOQS_USE_AVX2_INSTRUCTIONS=OFF`、`-DOQS_ENABLE_KEM_ml_kem_768_ipd_avx2=OFF`、`-DOQS_OPT_TARGET=generic`（见 [liboqs010-locked README](../liboqs010-locked-20261015/README.md)） | 同左 |
| `-march` | **无** | **无** |

**ELF 摘要核验（sha3-256）**

```console
$ ssh ... 'openssl dgst -sha3-256 .../build/historical-clangover/historical/measure; openssl dgst -sha3-256 .../build/historical-fixed-982c762/historical/measure'
SHA3-256(.../build/historical-clangover/historical/measure)= 227cd409f6acdc2640271883a2905fa3d8278d4acccc26522f2fefe85b9199c3
SHA3-256(.../build/historical-fixed-982c762/historical/measure)= f9ee0f792abbf066183e209c457d412bda2e14af0e1cead69ac929787913f927
```

`docs/evidence/liboqs010-locked-20261015/runs/vulnerable/meta.txt` =
`executable_digest=227cd409…99c3`、`runs/fixed/meta.txt` = `executable_digest=f9ee0f79…f927`
—— **两臂逐字一致**。

### 3.3 M2（KyberSlash 夹具，未修 / 已修）

被测 ELF 的构建树无 `compile_commands.json`，取 `flags.make` 与 `link.txt`：

```console
$ ssh ... 'cat .../CMakeFiles/m2_collector_unfixed_collector.dir/flags.make; cat .../link.txt'
C_DEFINES =
C_INCLUDES = -I.../source/include -I.../source/tools/platform_m2 -I.../source/vendor/kyber-kyberslash-unfixed/ref
C_FLAGS = -isystem .../dependencies/sysroot/usr/include/x86_64-linux-gnu -O2 -g -DNDEBUG \
          -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror
link.txt: /usr/bin/clang-18 ... -O2 -g -DNDEBUG CMakeFiles/m2_collector_unfixed_collector.dir/collector.c.o \
          -o collector/unfixed/m2_decaps_collector libm2_collector_unfixed.a libm2_collector_unfixed_vendor.a
```

实际编译规则（`build.make`，展开变量后即真实编译行）：

```console
$ ssh ... 'grep -A 3 "\.c\.o: " .../CMakeFiles/m2_collector_fixed_collector.dir/build.make'
	/usr/bin/clang-18 $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/m2_collector_fixed_collector.dir/collector.c.o \
	  -MF CMakeFiles/m2_collector_fixed_collector.dir/collector.c.o.d \
	  -o CMakeFiles/m2_collector_fixed_collector.dir/collector.c.o \
	  -c .../source/tools/platform_m2/collector.c
```

Kyber vendor 目标（计时窗口调用的实现，两臂相同）：

```console
$ ssh ... 'cat .../CMakeFiles/m2_collector_fixed_vendor.dir/flags.make'
C_DEFINES = -DKYBER_K=3 -Drandombytes=platform_m2_randombytes
C_FLAGS = -isystem .../dependencies/sysroot/usr/include/x86_64-linux-gnu -O2 -g -DNDEBUG \
          -Oz -g -fno-vectorize -fno-slp-vectorize
```

| 项 | M2 未修 | M2 已修 |
|---|---|---|
| 编译器 | `/usr/bin/clang-18` | 同左 |
| collector 选项 | `-O2 -g -DNDEBUG -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`（**无 `-std=`**） | 同左 |
| Kyber vendor 选项 | `-DKYBER_K=3 -Drandombytes=platform_m2_randombytes -O2 -g -DNDEBUG -Oz -g -fno-vectorize -fno-slp-vectorize` | 同左 |
| 链接 | `/usr/bin/clang-18 -O2 -g -DNDEBUG` | 同左 |
| `-march` | **无** | **无** |

**ELF 摘要核验（sha3-256）**

```console
$ ssh ... 'openssl dgst -sha3-256 .../collector/unfixed/m2_decaps_collector; openssl dgst -sha3-256 .../collector/fixed/m2_decaps_collector'
SHA3-256(.../collector/unfixed/m2_decaps_collector)= 624d267302805ab1eb6ae79db5d9ea8ea71cc07228f2efe70a4f06fe0e068623
SHA3-256(.../collector/fixed/m2_decaps_collector)= 282532c37df78ba5a24b19e699d707f3ff7036ca0b3fbb10b8ea325f89639359
```

与 `M2/m2-s1-unfixed/unfixed-main.meta` 的 `executable_sha3_256=624d2673…8623`、
`M2/m2-s1-fixed/fixed-main.meta` 的 `executable_sha3_256=282532c3…9359`
—— **两臂逐字一致**。

### 3.4 M3（人工构造 LUT 开关臂，on / off）

```console
$ ssh ... "python3 - 'platform_m3_(on|off)_measure' .../platform-m3-locate-20261016-4b102a339cc8/build-ordinary/compile_commands.json"
TARGET CMakeFiles/platform_m3_on_measure.dir/src/measure.c.o
  RAW /usr/bin/clang -DMLK_CONFIG_FILE=\"baseline_config.h\" \
      -I.../platform-m3-locate-20261016-4b102a339cc8/build-ordinary/generated/RelWithDebInfo \
      -I.../source/include -I.../source/vendor/mlkem-native/mlkem \
      -O2 -g -DNDEBUG -std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror \
      -o CMakeFiles/platform_m3_on_measure.dir/src/measure.c.o -c .../source/src/measure.c
TARGET CMakeFiles/platform_m3_off_measure.dir/src/measure.c.o
  （同上，路径换成 platform_m3_off_measure）
```

被测实现（on/off 两臂的差别只在这里）：

```console
$ ssh ... "python3 - 'platform_m3_(on|off)_kernel.dir/platform_m3' .../compile_commands.json"
FLAGS -DMLK_CONFIG_FILE=\"baseline_config.h\" -DPLATFORM_IMPLEMENTATION_NAME=\"platform-m3-lut-on\" \
      -DPLATFORM_M3_LUT_LEAK=1 -O2 -g -DNDEBUG -std=c11 -Wall -Wextra -Wpedantic -Wshadow \
      -Wconversion -Wstrict-prototypes -Werror
FLAGS -DMLK_CONFIG_FILE=\"baseline_config.h\" -DPLATFORM_IMPLEMENTATION_NAME=\"platform-m3-lut-off\" \
      -DPLATFORM_M3_LUT_LEAK=0 -O2 -g -DNDEBUG -std=c11 -Wall -Wextra -Wpedantic -Wshadow \
      -Wconversion -Wstrict-prototypes -Werror
```

| 项 | M3 on | M3 off |
|---|---|---|
| 编译器 | `/usr/bin/clang`（18.1.3） | 同左 |
| 选项 | `-O2 -g -DNDEBUG -std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror` | 同左 |
| 臂定义 | `-DPLATFORM_IMPLEMENTATION_NAME="platform-m3-lut-on" -DPLATFORM_M3_LUT_LEAK=1` | `…"platform-m3-lut-off" -DPLATFORM_M3_LUT_LEAK=0` |
| `-march` | **无** | **无** |

**ELF 摘要核验（sha3-256）**

```console
$ ssh ... 'openssl dgst -sha3-256 .../platform-m3/on/measure; openssl dgst -sha3-256 .../platform-m3/off/measure'
SHA3-256(.../platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/on/measure)= 7b4707989fffa123e1cf5f899d696496681cf1fe655f5c09de9852e87f7897f9
SHA3-256(.../platform-m3-locate-20261016-4b102a339cc8/build-ordinary/platform-m3/off/measure)= c1651c455757247013a66bf146313ee798b1b2485a04905531bd9fe191055767
```

`M3/m3-s1-on/on-samples.meta` 的 `executable_digest=7b470798…97f9` **逐字一致**；
off 臂同理（同一 `.meta` 字段规则）。**M3 是人工构造校准夹具，不代表上游 CVE。**

### 3.5 M4（人工提前退出比较夹具，vuln / ct）

被测 ELF 来自 `build-software-v3`（无 `compile_commands.json`）：

```console
$ ssh ... 'cat .../build-software-v3/CMakeFiles/platform_m4_measure_vulnerable.dir/flags.make; cat .../link.txt'
C_DEFINES = -DM4_VARIANT_NAME=\"vulnerable\"
C_INCLUDES = -I.../source-v3/fixtures/early_reject_memcmp -I.../source-v3/tools/platform_m4
C_FLAGS = -O2 -g -DNDEBUG -std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror
link.txt: /usr/bin/cc -O2 -g -DNDEBUG CMakeFiles/platform_m4_measure_vulnerable.dir/measure.c.o \
          -o platform_m4_measure_vulnerable libplatform_m4_vulnerable_kernel.a
```

（`platform_m4_measure_ct` 同形，`C_DEFINES = -DM4_VARIANT_NAME=\"ct\"`，链 `libplatform_m4_ct_kernel.a`。）

| 项 | M4 vulnerable | M4 ct |
|---|---|---|
| 编译器 | `/usr/bin/cc` → GCC 13.3.0 | 同左 |
| 选项 | `-O2 -g -DNDEBUG -std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror` | 同左 |
| 变体定义 | `-DM4_VARIANT_NAME="vulnerable"` | `-DM4_VARIANT_NAME="ct"` |
| 链接 | `/usr/bin/cc -O2 -g -DNDEBUG` | 同左 |
| `-march` | **无** | **无** |

**ELF 摘要核验（sha256，与控制器 `worker_sha256` 比）**

```console
$ ssh ... 'sha256sum .../build-software-v3/platform_m4_measure_vulnerable .../build-software-v3/platform_m4_measure_ct'
2686907893706372538855fa778bc7133cbed8fa0a8115c3dc57b124119b36c5  .../platform_m4_measure_vulnerable
90740bdf99125a2c37465c239617b6dadb344401e89b1830d24da88bd70be035  .../platform_m4_measure_ct
```

与 `M4/m4-s1-vuln/controller/command.json` 的 `worker_sha256=26869078…b36c5`、
`M4/m4-s1-ct/controller/command.json` 的 `worker_sha256=90740bdf…be035`
—— **两臂逐字一致**。M4 的 `.meta` 本身不含可执行摘要字段。

**M4 是人工构造校准夹具**，其 "insecure" 只针对人工提前退出实现，不代表上游 CVE。

### 3.6 M5（mlkem-native 参考臂）

```console
$ ssh ... "python3 - 'measure' .../build-v2-ordinary/compile_commands.json"
TARGET CMakeFiles/reference_measure.dir/src/measure.c.o
  RAW /usr/bin/clang-18 -DMLK_CONFIG_FILE=\"baseline_config.h\" \
      -I.../build-v2-ordinary/generated/RelWithDebInfo -I.../source-v2/include \
      -I.../source-v2/vendor/mlkem-native/mlkem \
      -O2 -g -DNDEBUG -std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror \
      -o CMakeFiles/reference_measure.dir/src/measure.c.o -c .../source-v2/src/measure.c
```

| 项 | M5 |
|---|---|
| 编译器 | `/usr/bin/clang-18`（18.1.3） |
| 选项 | `-O2 -g -DNDEBUG -std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror` |
| 定义 | `-DMLK_CONFIG_FILE="baseline_config.h"` |
| `-march` | **无** |

**ELF 摘要核验（sha3-256）**

```console
$ ssh ... 'openssl dgst -sha3-256 .../build-v2-ordinary/reference/measure'
SHA3-256(.../build-v2-ordinary/reference/measure)= 99f1743f94ec082de1ec7426e19b9f8fbb50c4d403cb79cf5b2e7f2140a1e672
```

`M5/m5-s1-meas/m5-samples.meta` 的 `executable_digest=99f1743f…a1e672` —— **逐字一致**。

### 3.7 全部构建树的选项盘点：没有任何 `-march` / `-mavx` / `-mfma`

对 `raw/compile-lines.txt` 里所有 `-m` 前缀选项做词频：

```console
$ grep -o '\-m[a-z0-9=._-]*' docs/evidence/r02-env-20261016/raw/compile-lines.txt | sort | uniq -c | sort -rn
 338 -marker
  76 -m5-20261016-30efdf66eb26
  22 -m2kem-20261016-d75a4019
   6 -m3-20261016-8b6f2d91
   2 -m32
   2 -m3-lut-on
   2 -m3-lut-off
   1 -measure
$ grep -c 'march' docs/evidence/r02-env-20261016/raw/compile-lines.txt
0
```

（`-marker`、`-m5-…`、`-m2kem-…` 等是 `--progress-dir` / 路径串里的子串误匹配；
唯一真实的 `-m*` 选项是 **`-m32`**，出现在 **binsec 形式化夹具** 目标上
—— `-m32 -O1 -g -ffreestanding -fno-pie -fno-stack-protector -fno-builtin`，
**不属于任何计时采集件**。被测计时 ELF 全部是默认目标 `x86_64-pc-linux-gnu`，
没有 `-march=`、没有显式 `-mavx*`、没有 `-mfma`；M2 的 Kyber 与 M1 的 liboqs 反而**关掉**了自动向量化
（`-fno-vectorize -fno-slp-vectorize` / `-fno-vectorize`）。

---

## 4. 计时源与读钟开销

### 4.1 各采集件用的 clock

来源：各 run 的 `.meta`（采集件自己写）与 `dudect-cycles.csv.gz` 的表头。

| 模块 | 采集件 | clock | `clock_resolution_ns` | 单位 | 窗口 |
|---|---|---|---|---|---|
| M1（liboqs010 未修/已修） | `historical/measure` | `CLOCK_MONOTONIC` | 1 | ns | 一次完整解封装 |
| M2 主类对/对照类对 | `m2_decaps_collector` | `CLOCK_MONOTONIC` | 1 | ns | `clock_gettime;atomic_signal_fence(seq_cst);mlkem_decapsulate(…);atomic_signal_fence(seq_cst);clock_gettime` |
| M3 on/off | `platform-m3/{on,off}/measure` | `CLOCK_MONOTONIC` | 1 | ns | 一次完整解封装 |
| **M4 vuln/ct（含截断对照）** | `platform_m4_measure_*` | **`CLOCK_MONOTONIC_RAW`** | `.meta` 未记（实测 `clock_getres` = 1 ns，见 §4.3） | ns | 一次完整受检比较 |
| M5 | `reference/measure` | `CLOCK_MONOTONIC` | 1 | ns | 一次完整解封装 |
| R03（三臂） | `r03_malformed_measure` | `CLOCK_MONOTONIC` | 1 | ns | 一次 ML-KEM 解封装调用 |
| **M2/M3/M4/M5/R03 的 online dudect 臂** | `*_dudect` | **`rdtsc`**（CSV 列为 `start_tsc` / `finish_tsc` / `elapsed_tsc_ticks`） | —（TSC 刻度） | ticks | 一批测量 |

逐字输出（`.meta` 抽样）：

```console
$ grep -hE '^(clock|clock_resolution_ns|time_unit)=' docs/evidence/platform-collection-20261016/M5/m5-s1-meas/m5-samples.meta
clock=CLOCK_MONOTONIC
time_unit=ns
clock_resolution_ns=1

$ cat docs/evidence/platform-collection-20261016/M4/m4-s1-vuln/vuln-samples.csv.meta
module=M4
case=artificial_compare
boundary=complete_checked_compare
variant=vulnerable
clock=CLOCK_MONOTONIC_RAW
unit=ns
order=balanced_adjacent_pair_splitmix64
seed=31337
requested_calls=20000
completed_calls=20000
collection_status=0
frequency_control=external_controller_required
compare_bytes=32
abi_bytes=32
warmup_calls=100
expected_equal_count_mismatch_first=0
expected_equal_count_mismatch_last=0
observed_equal_count_mismatch_first=0
observed_equal_count_mismatch_last=0
expected_result=mismatch-first:unequal,mismatch-last:unequal
（该 `.meta` 既没有 `clock_resolution_ns`，也没有可执行摘要字段）
```

**聚合核对**（脚本按模块统计全部 `.meta`）：

| 模块 | clock | `clock_resolution_ns` | 单位 | `.meta` 个数 |
|---|---|---|---|---|
| M1-liboqs010 | `CLOCK_MONOTONIC` | 1 | ns | 2 |
| M2 | `CLOCK_MONOTONIC` | 1 | ns | 12 |
| M3 | `CLOCK_MONOTONIC` | 1 | ns | 6 |
| M4 | `CLOCK_MONOTONIC_RAW` | （未记） | ns | 12 |
| M5 | `CLOCK_MONOTONIC` | 1 | ns | 3 |
| R03 | `CLOCK_MONOTONIC` | 1 | ns | 9 |

### 4.2 `clock_resolution_ns`

- 采集件自报：M1/M2/M3/M5/R03 均为 **1 ns**；**M4 的 `.meta` 没有这个字段**。
- 现测 `clock_getres`（新探针，见 §4.3）：`CLOCK_MONOTONIC` = **1 ns**、`CLOCK_MONOTONIC_RAW` = **1 ns**。
- 内核当前 clocksource = `tsc`（§1.5），可用 `tsc hpet acpi_pm`。
- 注意口径：本机**解析度 1 ns**，但 §4.3/§4.4 显示单次读钟自身约 **17–20 ns**；
  两者是两个不同的量，不得混用。

### 4.3 读钟开销实测（新探针，2026-10-16）

远端新根：`/home/nss-marker/yhr/Cry/r02-env-20261016-cad9a98501db/`（显式 `TMPDIR=$ROOT/tmp`）。
源码副本：[clock_overhead_probe.c](clock_overhead_probe.c)（与远端字节相同，sha256 见下）。
探针做的是**连续两次 `clock_gettime` 的空窗口**，与 `raw_clock_calibration.c` 的空 pair 语义一致。

```console
$ NONCE=$(openssl rand -hex 6); ROOT=/home/nss-marker/yhr/Cry/r02-env-20261016-$NONCE
$ # 写源码（只写自己的新根）、编译、运行（taskset -c 8，绝不使用 CPU2/CPU6）
### sha256 of remote probe source
c0e5775755646f80776c0109e343653b280cce935656f6abdda5fdd0971120f2  /home/nss-marker/yhr/Cry/r02-env-20261016-cad9a98501db/clock_overhead_probe.c
### compile line
/usr/bin/clang -O2 -std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror -o /home/nss-marker/yhr/Cry/r02-env-20261016-cad9a98501db/clock_overhead_probe /home/nss-marker/yhr/Cry/r02-env-20261016-cad9a98501db/clock_overhead_probe.c
### run line
taskset -c 8 /home/nss-marker/yhr/Cry/r02-env-20261016-cad9a98501db/clock_overhead_probe
observed_cpu=8
affinity_cpus=8,
clocksource_hint=see /sys/devices/system/clocksource/clocksource0/current_clocksource
SERIES CLOCK_MONOTONIC
  clock_getres_ns=1
  n=100000 failures=0
  min_ns=10
  max_ns=2916
  mean_ns=17.422940
  p50_ns=20.0
  p90_ns=21.0
  p99_ns=40.0
  p999_ns=41.0
SERIES CLOCK_MONOTONIC_RAW
  clock_getres_ns=1
  n=100000 failures=0
  min_ns=10
  max_ns=2544
  mean_ns=16.195490
  p50_ns=20.0
  p90_ns=20.0
  p99_ns=21.0
  p999_ns=21.0
### clocksource
tsc
### tree
总计 40
drwxrwxr-x  3 nss-marker nss-marker      4096 10月 16 04:04 .
drwxrwxr-x 69 nss-marker nss-marker      4096 10月 16 04:04 ..
-rwxr-xr-x  1 nss-marker nss-marker 16816 10月 16 04:04 clock_overhead_probe
-rw-r--r--  1 nss-marker nss-marker  4226 10月 16 04:04 clock_overhead_probe.c
drwxrwxr-x  2 nss-marker nss-marker      4096 10月 16 04:04 tmp
```

| 串 | n | mean | p50 | p90 | p99 | p99.9 | min | max | `clock_getres` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `CLOCK_MONOTONIC`（CPU8） | 100000 | **17.423 ns** | **20 ns** | 21 ns | **40 ns** | 41 ns | 10 ns | 2916 ns | 1 ns |
| `CLOCK_MONOTONIC_RAW`（CPU8） | 100000 | **16.195 ns** | **20 ns** | 20 ns | **21 ns** | 21 ns | 10 ns | 2544 ns | 1 ns |

**必须一起读的三点**：

1. 这次跑在 **CPU8**（`taskset -c 8`），**没有**碰 CPU2/CPU6；重负载、单线程、
   进程总运行时间不足 1 秒。CPU8 与采集用的 CPU2/CPU6 不是同一个物理核，数值**不可**直接当作
   采集窗口的读钟开销。
2. 两个 CLOCK 的中位数都是 20 ns，但 `CLOCK_MONOTONIC` 的 p99（40 ns）明显高于
   `CLOCK_MONOTONIC_RAW`（21 ns）：前者每次要叠加 `tk` 偏移与 seqcount 读重试，
   尾部更厚。M4 用的正是 `CLOCK_MONOTONIC_RAW`。
3. `min_ns = 10`：本机 `clock_gettime` 的实际最小步进是 10 ns 量级，**不是** `clock_getres` 报的 1 ns。
   单次取值 20 ns 上下，说明**读钟开销与被测窗口同量级**——这正是 M4（20–30 ns 的夹具）
   出现大量并列值的原因（见 [ROBUSTNESS.md §6.1](ROBUSTNESS.md)）。

### 4.4 读钟开销（既有归档复算，n=300000，CPU2 绑定）

新探针只有 100000 次/串；仓库里已有一份**更大、且绑在采集用 CPU2 上**的同类原件：
`docs/evidence/raw-clock-20261010/run-aa43771/remote-originals.tar.gz`（保留原件，不重采）。
其 `source/raw_clock_calibration.c` 的 `record_pair()` 就是

```c
record->before = read_clock_timespec(CLOCK_MONOTONIC_RAW);
atomic_signal_fence(memory_order_seq_cst);
atomic_signal_fence(memory_order_seq_cst);
record->after  = read_clock_timespec(CLOCK_MONOTONIC_RAW);
```

复算命令（脚本 [clock_overhead_report.py](clock_overhead_report.py)，只读压缩包）：

```console
$ python3 docs/evidence/r02-env-20261016/clock_overhead_report.py
output/P1.csv: elapsed==after-before mismatch rows = 0
output/P2.csv: elapsed==after-before mismatch rows = 0
output/P3.csv: elapsed==after-before mismatch rows = 0

| series | n | mean_ns | p50_ns | p90_ns | p99_ns | p99.9_ns | min_ns | max_ns | zeros |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| output/P1.csv warmup | 1000 | 17.621000 | 20.0 | 20.0 | 21.0 | 30.0 | 10 | 50 | 0 |
| output/P1.csv main | 100000 | 17.521420 | 20.0 | 20.0 | 21.0 | 21.0 | 10 | 2004 | 0 |
| output/P2.csv warmup | 1000 | 17.523000 | 20.0 | 20.0 | 21.0 | 21.0 | 10 | 50 | 0 |
| output/P2.csv main | 100000 | 17.500800 | 20.0 | 20.0 | 21.0 | 21.0 | 10 | 1603 | 0 |
| output/P3.csv warmup | 1000 | 17.672000 | 20.0 | 20.0 | 21.0 | 21.0 | 10 | 50 | 0 |
| output/P3.csv main | 100000 | 17.480480 | 20.0 | 20.0 | 21.0 | 21.0 | 10 | 501 | 0 |
| P1+P2+P3 main pooled | 300000 | 17.500900 | 20.0 | 20.0 | 21.0 | 21.0 | 10 | 2004 | 0 |
```

- **n = 300000**（三个进程各 100000 主 pair；另有 3 × 1000 预热 pair），
  满足并超过"n ≥ 10000"。
- 三个进程的 `elapsed_ns` 与 `after_ns − before_ns` **逐行相等**（mismatch = 0）。
- 结论：**均值 17.50 ns、中位数 20 ns、p99 21 ns、p99.9 21 ns、最小 10 ns**；
  该轮是 `CLOCK_MONOTONIC_RAW`、绑定 CPU2、`boost` 未配置（不是本轮锁频条件）。
- 与 §4.3 的新探针（`RAW`，CPU8：mean 16.20 / p50 20 / p99 21）**一致**，互为交叉验证。

---

## 5. SMT、`isolcpus` 与 IRQ 亲和

原文：[`raw/irq-and-isolation.txt`](raw/irq-and-isolation.txt)。

### 5.1 SMT

```console
$ ssh nss-marker@10.144.144.5 'cat /sys/devices/system/cpu/smt/active; echo "---"; cat /sys/devices/system/cpu/smt/control'
1
---
on
```

`SMT active = 1`：**SMT 开启**，32 个逻辑 CPU 是 16 个物理核的双线程。
采集时 `taskset -c 2` / `-c 6` 只固定了**线程**，**没有**排除同核的兄弟线程（CPU2↔CPU18、CPU6↔CPU22 一类）。
本轮不主张"整机独占"或"物理核独占"。

### 5.2 `isolcpus`

```console
$ ssh nss-marker@10.144.144.5 'cat /proc/cmdline'      # 见 §1.3，逐字
BOOT_IMAGE=/boot/vmlinuz-6.17.0-35-generic root=UUID=… ro quiet splash vt.handoff=7

$ ssh nss-marker@10.144.144.5 'echo -n "isolated=<<"; cat /sys/devices/system/cpu/isolated; echo ">>"; echo -n "nohz_full=<<"; cat /sys/devices/system/cpu/nohz_full; echo ">>"; grep -o "isolcpus[^ ]*" /proc/cmdline || echo "cmdline 中无 isolcpus"'
isolated=<<>>
nohz_full=<<(null)>>
cmdline 中无 isolcpus
```

结论：**没有 `isolcpus`**（`/sys/devices/system/cpu/isolated` 为空、cmdline 无该项），
`nohz_full` 为 `(null)`。采集的 CPU 隔离性**只**来自 `taskset` 亲和性 + 控制器写频，
不是内核级 CPU 隔离。

### 5.3 IRQ 亲和（`/proc/interrupts` 摘录）

先从第一次全量抓取（`head -40`，含表头，见 `raw/remote-env.txt`）确认表头列序，
再按"CPU2 列（第 4 字段）或 CPU6 列（第 8 字段）非零"过滤全表：

```console
$ ssh nss-marker@10.144.144.5 'awk "NR==1{print; next} {if (\$4+0!=0 || \$8+0!=0) print}" /proc/interrupts'
            CPU0       CPU1       CPU2       CPU3       CPU4       CPU5       CPU6       CPU7   …  CPU31
  29:          0          0          0          0          0          0          1          0   …      0 IR-PCI-MSI-0000:00:01.2    0-edge      PCIe PME, PCIe bwctrl
 109:          0          0         96          0          0          0          0          0   …      0 IR-PCI-MSIX-0000:02:00.0    3-edge      nvme0q3
 113:          0          0          0          0          0          0          3          0   …      0 IR-PCI-MSIX-0000:02:00.0    7-edge      nvme0q7
 141:          0          0    1984127          0          0          0          0          0   …      0 IR-PCI-MSIX-0000:03:00.0    3-edge      nvme1q3
 145:          0          0          0          0          0          0     357101          0   …      0 IR-PCI-MSIX-0000:03:00.0    7-edge      nvme1q7
 179:          0          0      86152          0          0          0          0          0   …      0 IR-PCI-MSIX-0000:74:00.0    0-edge      amdgpu
 NMI:       1078      12725       2190      10754       2232       1221        618        406   …    217   Non-maskable interrupts
 LOC:   96096576  558560207  274624422  497643927 1008867163  164433785  100386975   63249099   … 20042691   Local timer interrupts
 PMI:       1078      12725       2190      10754       2232       1221        618        406   …    217   Performance monitoring interrupts
 RES:    2924678    4021020    5138541    2865942    3617183    2968423    1620470    1124425   … 276991   Rescheduling interrupts
 CAL:  198324639  233057925  153013980  177410543  106443457  126354077   85932170   58705679   … 6090312   Function call interrupts
 TLB:    2520524    4497054    6034434    4895137    5636576    6082394    3114052    1863708   … 582661   TLB shootdowns
 MCP:      11888      11888      11888      11888      11888      11888      11888      11888   …  11888   Machine check polls

$ ssh nss-marker@10.144.144.5 'grep -c ":" /proc/interrupts'
120
$ ssh nss-marker@10.144.144.5 'cat /proc/irq/default_smp_affinity; systemctl is-active irqbalance'
ffffffff
inactive
```

要点（**如实登记，不淡化**）：

- **CPU2 与 CPU6 都不是"零中断"**：CPU2 上累计有 `nvme1q3` 1984127 次、`amdgpu` 86152 次、
  `nvme0q3` 96 次；CPU6 上有 `nvme1q7` 357101 次、`nvme0q7` 3 次、`PCIe PME` 1 次。
  这些是**开机以来的累计计数**，不是采集窗口内的计数；但本页不主张采集窗口内 CPU2/CPU6 零中断。
- 每个 CPU 的 `LOC` / `RES` / `CAL` / `TLB` 都是十万到上亿量级（内核定时器、重调度、TLB shootdown）。
- `irqbalance` 服务 **inactive**，`default_smp_affinity = ffffffff`（32 个 CPU 全在掩码里）。
- 全表共 120 行中断条目。

---

## 6. 后台服务快照

```console
$ ssh nss-marker@10.144.144.5 'systemctl list-units --type=service --state=running --no-pager --no-legend'
  accounts-daemon.service       loaded active running Accounts Service
  avahi-daemon.service          loaded active running Avahi mDNS/DNS-SD Stack
  bluetooth.service             loaded active running Bluetooth service
  bolt.service                  loaded active running Thunderbolt system service
  codex-mihomo.service          loaded active running Codex Mihomo Proxy
  colord.service                loaded active running Manage, Install and Generate Color Profiles
  containerd.service            loaded active running containerd container runtime
  cron.service                  loaded active running Regular background program processing daemon
  cups-browsed.service          loaded active running Make remote CUPS printers available locally
  cups.service                  loaded active running CUPS Scheduler
  dbus.service                  loaded active running D-Bus System Message Bus
  docker.service                loaded active running Docker Application Container Engine
  fail2ban.service              loaded active running Fail2Ban Service
  fwupd.service                 loaded active running Firmware update daemon
  gdm.service                   loaded active running GNOME Display Manager
  gnome-remote-desktop.service  loaded active running GNOME Remote Desktop
  kerneloops.service            loaded active running Tool to automatically collect and submit kernel crash signatures
  ModemManager.service          loaded active running Modem Manager
  NetworkManager.service        loaded active running Network Manager
  nvidia-persistenced.service   loaded active running NVIDIA Persistence Daemon
  polkit.service                loaded active running Authorization Manager
  power-profiles-daemon.service loaded active running Power Profiles daemon
  rsyslog.service               loaded active running System Logging Service
  rtkit-daemon.service          loaded active running RealtimeKit Scheduling Policy Service
  snapd.service                 loaded active running Snap Daemon
  ssh.service                   loaded active running OpenBSD Secure Shell server
  switcheroo-control.service    loaded active running Switcheroo Control Proxy service
  systemd-journald.service      loaded active running Journal Service
  systemd-logind.service        loaded active running User Login Management
  systemd-oomd.service          loaded active running Userspace Out-Of-Memory (OOM) Killer
  systemd-resolved.service      loaded active running Network Name Resolution
  systemd-timesyncd.service     loaded active running Network Time Synchronization
  systemd-udevd.service         loaded active running Rule-based Manager for Device Events and Processes
  udisks2.service               loaded active running Disk Manager
  unattended-upgrades.service   loaded active running Unattended Upgrades Shutdown
  upower.service                loaded active running Daemon for power management
  user@1000.service             loaded active running User Manager for UID 1000
  user@120.service              loaded active running User Manager for UID 120
  wpa_supplicant.service        loaded active running WPA supplicant
$ ssh nss-marker@10.144.144.5 'systemctl list-units --type=service --state=running --no-pager --no-legend | wc -l'
39
```

这是**桌面/开发机**：GNOME 会话（`gdm`、`gnome-remote-desktop`）、容器运行时
（`docker`、`containerd`）、打印（`cups`）、代理（`codex-mihomo`）、审计/更新
（`fail2ban`、`unattended-upgrades`、`snapd`、`systemd-oomd`）等常驻。
**共 39 个 running service**。与平台 README §6 一致：采数期间机器上仍运行着与本项目无关的
常驻服务，本轮**不主张整机独占**。

---

## 7. 频率相关

```console
$ ssh nss-marker@10.144.144.5 'cat /sys/devices/system/cpu/cpufreq/boost 2>&1; echo "--- amd_pstate"; cat /sys/devices/system/cpu/amd_pstate/status 2>&1; echo "--- policy2"; for f in scaling_driver scaling_governor scaling_min_freq scaling_max_freq scaling_cur_freq energy_performance_preference; do printf "%s=%s\n" "$f" "$(cat /sys/devices/system/cpu/cpufreq/policy2/$f 2>&1)"; done; echo "--- policy6"; ...'
1
--- amd_pstate
active
--- policy2
scaling_driver=amd-pstate-epp
scaling_governor=powersave
scaling_min_freq=2982259
scaling_max_freq=5756452
scaling_cur_freq=2982259
energy_performance_preference=balance_performance
--- policy6
scaling_driver=amd-pstate-epp
scaling_governor=powersave
scaling_min_freq=2982259
scaling_max_freq=5756452
scaling_cur_freq=2982259
energy_performance_preference=balance_performance
```

| 项 | 值（2026-10-16 03:59 UTC+8 静息态） |
|---|---|
| `/sys/devices/system/cpu/cpufreq/boost` | **1**（boost 开启） |
| `/sys/devices/system/cpu/amd_pstate/status` | **active**（amd-pstate 驱动生效） |
| policy2 `scaling_driver` | `amd-pstate-epp` |
| policy2 `scaling_governor` | `powersave` |
| policy2 `scaling_min_freq` / `scaling_max_freq` | `2982259` / `5756452` kHz |
| policy2 `scaling_cur_freq` | `2982259` kHz |
| policy2 `energy_performance_preference` | `balance_performance` |
| policy6（同上 6 项） | 与 policy2 **逐字相同** |

**与本轮采集条件的关系（必须一起读）**：

- 上表是**静息态**读数。T05 采集期间由唯一控制器写为
  `boost=0`、governor/EPP=`performance`、`min=max=4300000 kHz`，
  每次 run 的进入/退出快照逐字相同（见 [platform-collection README §1](../platform-collection-20261016/README.md)）。
- T07 本次只读，**没有**写任何频率文件；读数因此是静息态。
- 各 run 的 `.meta` 写死 `cpu_affinity=not_pinned`、`frequency_control=not_configured`
  （M4 写 `frequency_control=external_controller_required`）——这是采集件自身的固定字符串，
  **不是**采集时的真实状态；权威来源是控制器落盘记录。平台 README §7 已登记同一条。
- `scaling_cur_freq` 不是示波器测量；本页**不主张**逐调用物理恒频，也不给物理误差界。

---

## 8. 登记：本文件与既有证据目录不一致的三处

按仓库"缺证据不升级声明、如实登记"的约定，逐条登记（**已核对，不是推测**）：

1. **M4 的被测 ELF 来自 `build-software-v3` / `source-v3`**，
   而 `docs/evidence/m4-completion-20261016/software-native/software-logs-v2/` 记录的是
   `build-software-v2` / `source-v2`。判据：`M4/m4-*/controller/command.json` 的
   `command[0]` 逐字是 `.../build-software-v3/platform_m4_measure_{vulnerable,ct}`，
   且 `worker_sha256` 与本页 §3.5 实测的 sha256 逐字相同。两版 `flags.make` 的
   `C_FLAGS` 与 `C_DEFINES` 相同（只有 `source-v2`/`source-v3` 的包含路径不同）。
2. **M3 的被测 ELF 来自 `platform-m3-locate-20261016-4b102a339cc8`**，
   而 `docs/evidence/m3-completion-20261016/native-m3-selected-compile_commands.json`
   摘自 `platform-m3-20261016-8b6f2d91`。两棵树的 `platform_m3_{on,off}_measure` 选项集合相同，
   只有 `-I` 路径不同；判据同 1（`command.json` + `.meta` 的 `executable_digest` 实测相同）。
3. **M2 的被测 ELF 不在 `platform-m2kem-20261016-d75a4019/build-ordinary`**，
   而在同轮的 `collector-v2-2e894561892a/build-ordinary/collector/{unfixed,fixed}/`；
   该 collector 树**没有** `compile_commands.json`（Unix Makefiles、未导出），
   所以 M2 的编译行取自 `flags.make` + `link.txt` + `build.make`（§3.3）。

另有一条早已登记的同类问题（本轮复核仍然成立）：
各 run 的 `.meta` 写死 `cpu_affinity=not_pinned` / `frequency_control=not_configured`，
与真实锁频条件相反，权威来源是控制器记录（平台 README §7 第 1 条）。

---

## 9. 边界

- 本页是**环境与构建登记**，不是性能结论，也不是恒时证明。
- 编译行绑定到被测 ELF 的方式是**摘要比对**（§3.2–§3.6 逐一给出两边的值），
  只说明"该树产出的 ELF 就是被计时的那一个"，**不**说明该 ELF 的行为正确。
- `taskset` 亲和性 + 控制器写频**不是**内核级 CPU 隔离（§5.2），SMT 开启（§5.1），
  CPU2/CPU6 上有非零 IRQ 累计计数（§5.3），机器上另有 39 个常驻服务（§6）。
  **整机独占、零中断、物理核独占都不是本页的主张。**
- 读钟开销是**软件观测**：它给出窗口读出值的量级（17–20 ns）与量化粒度（最小步进 10 ns），
  不是硬件时间戳单元的精度界。
- 本页所有远端操作**只读**，唯一写入在自建新根 `Cry/r02-env-20261016-cad9a98501db/`
  之内（源码、ELF、`tmp/`），没有 sudo、没有装包、没有改动任何既有远端文件，也没有使用 CPU2/CPU6。
