# 环境与产物元数据（ENV.md）

记录日期：2026-10-16  
执行环境：裸金属主机 `nss-m`

---

## 1. 硬件与系统信息
- **主机名**：`nss-m`
- **处理器**：AMD Ryzen 9 9950X 16-Core Processor（32 逻辑核心）
- **架构**：x86_64
- **虚拟化检测**：`systemd-detect-virt=none`（裸金属）
- **操作系统**：Ubuntu 24.04.4 LTS
- **内核版本**：Linux 6.17.0-35-generic #35~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC
- **编译器**：Ubuntu Clang version 18.1.3 (1ubuntu1)

---

## 2. 频率管理与锁频口径
- **全局 Boost**：采集期间严格写入 `0` 禁用；结束后恢复为 `1`。
- **调速器与能耗偏好**：
  - 测试核心（CPU2 或 CPU6）写入 `scaling_governor=performance`，`energy_performance_preference=performance`。
  - 目标频率：`scaling_min_freq = 4300000 kHz`，`scaling_max_freq = 4300000 kHz`（约 4.30 GHz）。
  - 稳定性判定：预先连续采集 20 次 `scaling_cur_freq`，跨度 $\le 50000$ kHz（约 1%）方允许进入采集。
  - 采集全程监控：后台守护进程以 50ms 间隔采样记录测试核心的 `scaling_cur_freq`。
  - 退出恢复：通过快照脚本自动恢复全部 32 个 CPU 及全局 boost，并执行读回校验 `restore_match=yes`。

---

## 3. 构建参数与 CMake 配置
- **CMake 配置项**：
  - `-DCMAKE_BUILD_TYPE=RelWithDebInfo`
  - `-DCMAKE_C_COMPILER=clang`
  - `-DBUILD_TESTING=ON`
  - `-DBASELINE_ENABLE_LIBOQS010=ON`
  - `-DA113_ARCHIVED_CASE_ONLY=OFF`
  - `-DBASELINE_SANITIZERS=OFF`
  - `-DLIBOQS010_C_FLAGS="-Os -fno-vectorize"`
  - `-DOQS_DIST_BUILD=OFF`
  - `-DOQS_USE_AVX2_INSTRUCTIONS=OFF`
  - `-DOQS_ENABLE_KEM_ml_kem_768_ipd_avx2=OFF`
  - `-DOQS_OPT_TARGET=generic`
- **汇编与后端验证**：
  - 运行 `tests/check_liboqs010_poly_frommsg_disasm.sh` 输出 `disasm_check=pass`。
  - 未修版本：`poly_frommsg` 包含消息位条件跳转 `bt` 与 `jae`，跳转成立写入 `0x681`。
  - 已修版本：`poly_frommsg` 转换为无分支位提取 `bt` / `setb`，调用 `cmov_int16`，无 `jae`。

---

## 4. 二进制产物 SHA-256 摘要
- **未修解封装测量程序 (`historical-clangover/historical/measure`)**：
  `bd84ee9c2a44993fb5c6b43c4fb37027a168d265b4ca027eba3c3026798a0f78`
- **已修解封装测量程序 (`historical-fixed-982c762/historical/measure`)**：
  `1849821eca3039872cf5f103e3928141978b8846792a8da4e7c790ce96c2b5e9`
- **未修 dudect 测量程序 (`build/dudect/historical-dudect-vulnerable`)**：
  `a04dad85c2bc017bc7d0046b868c8712461629f414f87ffb50c4046305205b12`
- **已修 dudect 测量程序 (`build/dudect/historical-dudect-fixed`)**：
  `64d2e474746042ad9ee3dd80a078fe083c699bbeb210ea383e593ae2754e72eb`

---

## 5. 上游依赖与工具版本
- **上游 liboqs 原始快照**：tag 0.10.0，commit `36be57445d8ca53f7095160fde548efe82ace09d`（`vendor/liboqs-0.10.0/` 未做任何修改）
- **官方修复补丁**：liboqs commit `982c762c242ef549c914891b47bf6e0ed6321f91`
- **RTLF**：commit `2497d660e4b23fc9acd21b077a35e82178fcd728`，运行环境 Rscript (R) version 4.3.3
- **dudect**：commit `dc269651fb2567e46755cfb2a13d3875592968b5`
- **Valgrind**：3.22.0
- **cryProject 本仓库提交**：`4b1502cbf6ec511685df310c4a95b1852d8583cb`（含 `PLAN.md` 冻结）
