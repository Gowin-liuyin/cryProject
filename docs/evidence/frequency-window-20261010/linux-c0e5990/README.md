# 真实 Linux 的进程转储限制与参考软件复核

2026-10-10，本记录接续 `linux-7e93048`，保留旧候选及其原件。本次唯一功能改动是
候选 C 入口在秘密生成之前禁用并回读自身 dumpable 状态，另增加独立软件检查入口；
reference 内核、公开 KAT 和原始窗口 JSONL 协议未改。

- 固定提交：`c0e5990bd4d764fbb08ff6857a2cf6cf21c9b8a2`。
- 候选 C SHA-256：`520bdc1bbcc1bbd805674a39c639e1cbcd13e66ae0b44dba78688115f02ef7f0`。
- 源 tar：`9f9803943f6ae724f895c57cd60c41828d0cba6a71d9deb7eb6f78907d95a8f5`。
- [完整软件原档](window-source-c0e5990-software.tar)：
  `f487f59544aaab302303944463cd32daa99963725cef54eded4d220c578202e7`。
- 云端原件：`/home/nss-marker/yhr/Cry/window-source-c0e5990/`，同级同名
  `-software.tar` 是导出。源码、构建、临时与缓存均在该新树内，未覆盖旧树。

真实机器是 `nss-m`、Linux `6.17.0-35-generic`、x86_64，GCC 13.3.0、CMake 3.28.3。
普通 RelWithDebInfo 与 ASan/UBSan 配置的 configure/build/test 六步均退出 0。
每配置 CTest 3/3：纯软件自检、进程自身转储限制及原参考 NIST KAT；后一检查实际输出
`process_dumping_disabled=true`、errno 为 0，同时声明没有硬件读或密码工作负载。
普通与动态配置各自的 [原始 LastTest](selected/build-normal/Testing/Temporary/LastTest.log)
和 [动态 LastTest](selected/build-sanitize/Testing/Temporary/LastTest.log) 保持原字节。

普通 worker 为 225384 字节，SHA-256
`023f56460a8dc4971e8132a22c5734ca0844314d3d71b8bc3b129a424e9ee69b`，
后续 G2 只能固定使用这个普通产物，不能使用 ASan 产物替代正式计时。
四份完整 ELF、摘要、编译命令、配置、六步日志及执行记录均在原档中；选取副本见 `selected/`。
可用 [verify_software.py](verify_software.py) 重算全部 617 清单载荷、138 源文件 Git blob、
选取原件、四 ELF 和每配置 3 项测试；结果见 [verification.json](verification.json)。

[tool-results.json](tool-results.json) 保存本次实际资源预检及上传、执行、下载的工具返回；
[orchestration-source.py](orchestration-source.py) 是此次实际发送的编排源，当时尚未提交，
不能把之后的文档提交冒称其执行来源。所有六步日志还在远端原件及完整归档中。

本机 AppleClang21 的普通与 ASan/UBSan 配置仍各 2/2，Linux 专用检查不在 Mac 注册。
本机 C 格式和仓库 format-check 通过；首次新增 CMake 块格式检查失败，按格式要求只调整
该新增块后检查通过，未重排既有构建内容。原始候选源码独立复核无未解决阻断项。

本记录只支持“Linux 软件编译、KAT 与自身转储设置检查通过”。普通无参入口、真实 MSR
长窗口、生命周期协议、活动频率、完整物理误差及 R02/R04 不由这里签收。转储保护仅从
C 入口设置成功起生效，不涵盖动态加载器或进入 C 前的崩溃。

接口依据为 Linux man-pages 的 [PR_SET_DUMPABLE](https://man7.org/linux/man-pages/man2/PR_SET_DUMPABLE.2const.html)
和 [execve 的进程属性变化](https://man7.org/linux/man-pages/man2/execve.2.html)。
指定上游 [Linux v6.17 coredump.c](https://raw.githubusercontent.com/torvalds/linux/v6.17/fs/coredump.c)
在非 dumpable 时于 pipe/file 处理前拒绝转储。这是固定上游源码解释；本轮没有逐行核对
Ubuntu 内核补丁，也没有故意制造崩溃或修改全局 core 配置来试验该路径。
