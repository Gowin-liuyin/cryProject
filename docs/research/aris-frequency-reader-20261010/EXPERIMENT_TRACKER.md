# 执行跟踪

| 编号 | 主张/目的 | 机器与对象 | 初始状态 | 结果入口 |
|---|---|---|---|---|
| F00 | 资源与缓存设备映射 | nss-m，Linux CPU2/18→ACPI C004/C005 | 实际只读成功；iasl/acpidump缺失 | 后续证据目录保留工具原值 |
| F01 | 固件原件和静态反馈描述 | DSDT/SSDT及缓存path/uid/hid | 14表原件已核对；原-da退出255，保留失败 | [原件与边界](RESULTS.md) |
| S01 | 新进程的目标静态诊断 | 同一14输入，另13作external、仅SSDT3目标 | 实际退出0；两个静态_CPC包及原AML独立核对通过，不称全体反编译成功 | [映射复核](../../evidence/frequency-reader-20261010/run-eed81a7/FIRMWARE_MAPPING_REVIEW.md) |
| F02 | C11软件读取及异常边界 | 本地与Linux独立CMake/CTest | 两平台普通/动态各1/1；实际Linux编译和原ELF核对通过 | [原日志](../../evidence/frequency-reader-20261010/run-eed81a7/README.md) |
| F03 | 实际只读MSR快照 | nss-m，CPU2/18各三读 | 单次实际退出0、六读成功、无超时，原件/tar回读相同 | [六读原值](../../evidence/frequency-reader-20261010/run-eed81a7/counter/stdout.json) |

本表是工作过程记录，状态不代替原件；最终证据在新目录登记。频率控制、活动观察窗口和正式R02/R04均不属于上述已执行范围。
