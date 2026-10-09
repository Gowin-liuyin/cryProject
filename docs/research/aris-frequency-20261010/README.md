# R02频率接口只读预检

2026-10-10（北京时间），仅在已核验身份的裸金属 `nss-marker@10.144.144.5` 上读取系统接口。完整原值及核验入口见[证据记录](../../evidence/frequency-preflight-20261010/README.md)。这是资源资格准备，不是受控测量、恒频数据集或R02签收。

用户授权直接用密码交互。两次读取均以 `/home/nss-marker/yhr/Cry` 为工作目录，通过 `sudo /usr/bin/python3 -I -B -c <源文本>` 在内存执行；没有创建远端项目源码、缓存、日志或临时文件，没有调用外部负载。源码中的两个零写入字段是固定声明，经独立源码审查支持，不是系统调用审计器的运行计数。认证内容不入材料。

## 实际接口与尺度

| 对象 | 原值与范围 | 当前解释 |
|---|---|---|
| 机器 | `nss-m`，Linux `6.17.0-35-generic`，x86_64，root读取 | 实际Linux记录，非macOS替代 |
| CPU2/18 | SMT同胞 `2,18`；分别对应独立 `policy2/policy18`，各策略的 `related_cpus/affected_cpus` 为自身单CPU | 一个物理核，不是两份独立频率实验 |
| 全部32策略 | `amd-pstate-epp`，`powersave`，EPP `balance_performance`；min `2982259`、max `5756452` kHz；boost `1` | 预检时配置，未修改 |
| 全局 | amd-pstate `active`，prefcore `enabled`，boost `1` | 未切换驱动模式或全局boost |
| CPU2/18频率读数 | `scaling_cur_freq=cpuinfo_avg_freq=2982259` kHz；`cpuinfo_cur_freq` 不存在 | 两个接口不能当作独立实频证据，也未判定其必然来自缓存 |
| CPU2/18 CPPC | `nominal_freq=4300` MHz，`nominal_perf=reference_perf=124`，`highest_perf=231`，`lowest_nonlinear_perf=86`，`lowest_perf=18` | 频率报告尺度和抽象性能尺度，不能混成硬件恒频保证 |
| CPPC累计反馈 | CPU2：ref `86844627444315` / del `76430118985511`；CPU18：ref `15244518571229` / del `14845306105942` | 各只有一次累计快照；此次不计算比值、差分或MHz |
| CPPC wraparound_time | 字符串 `18446744073709551615` | 原值保留，不把这个极大值当作经验证的采样保证 |
| MSR能力发现 | 两个 `/dev/cpu/<CPU>/msr` 存在；msr模块和aperf/mperf/tsc事件接口存在 | 尚未直接打开MSR读取；不从存在性推断可用性 |
| 时钟 | clocksource `tsc`；`CLOCK_MONOTONIC_RAW` 报告分辨率 `1e-9` s | 分辨率不是测量精度，也不证明执行频率恒定 |

第一次系统快照UTC为 `2026-10-09T20:27:29.413406+00:00`，补充CPPC快照为 `2026-10-09T20:53:06.020732+00:00`。它们不是同一瞬间的原子读取；所有字段按实际顺序读取。计数以原十进制字符串保存，未经过浮点数转换。

## 支持与未支持的结论

Linux v6.17的 `arch_freq_get_on_cpu()` 在无有效计数或样本过旧时回退请求/缓存值；amd-pstate-epp又会把缓存 `policy->cur` 置为最低策略值。因而相同的两个频率显示值不足以证明实际恒频。这是依据[指定版本APERF/MPERF源码](https://raw.githubusercontent.com/torvalds/linux/v6.17/arch/x86/kernel/cpu/aperfmperf.c)与[AMD驱动源码](https://raw.githubusercontent.com/torvalds/linux/v6.17/drivers/cpufreq/amd-pstate.c)的条件解释，不是对Ubuntu补丁或本次回退路径的直接跟踪。

[CPPC文档](https://docs.kernel.org/6.17/admin-guide/acpi/cppc_sysfs.html)要求两个不同时间的反馈快照才能计算平均交付性能，并区分reference性能与nominal频率。当前只证明CPPC接口实际可读；未取得活动区间、明确的硬件计数映射或有效参考率验证。ACPI `highest_perf=231` 与驱动 `amd_pstate_highest_perf=166` 也不能直接互换。

指定版本的[CPPC读取实现](https://raw.githubusercontent.com/torvalds/linux/v6.17/drivers/acpi/cppc_acpi.c)读取固件 `_CPC` 的参考及交付计数描述；[x86 FFH实现](https://raw.githubusercontent.com/torvalds/linux/v6.17/arch/x86/kernel/acpi/cppc.c)按其中地址、位宽与偏移读MSR，没有硬编码二者必为E7/E8。当前尚未核对本机固件映射，因此仍称“CPPC累计反馈”。同一源码中的可选字段默认逻辑也可能产生极大的wraparound值；本次不能判断该字段具体来源。

驱动的preferred-core性能分子可使用166，原始最高能力另用于排序，所以231与166不矛盾，后者不是前者实测降频后的结果。将来两个有效快照可先得到平均交付性能 `124 × Δdel / Δref`，按驱动名义尺度表达为 `4300 × Δdel / Δref MHz`；它依然不是活动状态语义、物理Hz精度或瞬时恒频的证明。本次没有实施该换算。

下一步先冻结反馈来源、窗口与读取误差的解释，再完善仅CPU2/18的可见范围请求及恢复合同。即使min=max回读成功，也只说明请求和可见策略范围；活动平均入带不代表每次短调用或每一瞬间入带。正式普通参考测量仍受[下一验证协议](../aris-replication-20261009/NEXT_VALIDATION_PROTOCOL.md)的目标、精度、统计前提与预算约束。

本次没有频率、boost、SMT、IRQ或cgroup配置写入，没有密码算法运行、主动缺陷测量或新统计结论。SSH主连接已关闭。旧KVM仍待可信控制台核验变化后的主机密钥；已授权的密码认证偏好保持，但不替代服务器身份核验。
