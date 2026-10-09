# 当前CPU分区接口的只读预检

2026-10-10北京时间；[原件](preflight.json)UTC为2026-10-09T16:55:27。代理按用户授权完成密码交互，严格核对已信任主机，普通UID1000运行[预检源码](../../research/aris-core-partition-20261010/preflight.py)，SSH正常退出0。没有sudo、后台任务、配置写入或远端项目文件写入；本地保存原输出字节。

真实机器仍为nss-m、Linux6.17.0-35-generic、x86_64、在线CPU0—31，CPU2/18为同一物理核的SMT同胞。根cgroup的subtree_control已含cpuset；检查的init.scope、system.slice、user.slice均是member、有效CPU0—31，cpus/exclusive请求为空。三单位的Delegate=no；user.slice未向下启用cpuset，UID1000不能写所查CPU控制接口。

这证明相关内核接口存在，不能证明已经预留CPU、已经取得普通用户委派、其他全部层级均无设置，或管理员无法分配资源。新执行仍需root、全相关状态新快照、独立恢复条件及实际回读；不能沿用旧609行预演的准备通过替代新方案。

对照[Linux6.17官方cpuset文档](https://docs.kernel.org/6.17/admin-guide/cgroup-v2.html#cpuset)，根是分区根，新的本地isolated分区可排除其他分区使用其CPU，并排除负载均衡和无绑定工作队列。这提供了避免逐线程批改的候选路线，尚未实施；IRQ、绑定内核线程、物理频率及测量精度仍需分别处理。新项目源码、恢复快照、日志和临时文件继续只能落盘Cry；旧/run方案仍禁用。
