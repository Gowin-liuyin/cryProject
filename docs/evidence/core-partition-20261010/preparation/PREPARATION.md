# 内核分区管理的准备核验

2026-10-10。本页记录准备，不表示已分区或已完成Linux预演。root只读预检实际UID0，PID/cgroup/mount命名空间与PID1相同，80个cpuset分组全member/空请求，isolated为空，无配置写入。

实际管理源码SHA256为dda496a5b1f1fd81688af30e4361ee9fee32f10d7a5145012266ccbe835b8f61，CMake/CTest本地macOS软件检查1/1，覆盖CPU解析、清理继续、pipe EOF、inode拒绝、原子回执及不覆盖、真实空任务启动屏障、故障回收和SIGCHLD默认重置。它不是Linux/root真实分区结果。

扩展开发检查先后暴露macOS没有pipe2和/bin/true两处平台假设；负日志保持，改为Python默认不可exec继承的os.pipe及/usr/bin/true后通过。开发迭代未冻结旧源码，不把旧回溯行号冒称当前源码身份。

独立同模型代理及其协议审查者检查实际候选并修正原子回执、FD路径、人工恢复缺回执拒绝、有限等待、进程回收、nonce及归档持久化等问题；最终只读部署审查通过。最后SIGCHLD故障注入验证先重置默认才fork，保护未回收自有PID的前提。内部审查不是外部同行评审或对未来实机成功预签。

合同限定normal和controller-SIGKILL两case各一次，唯一guard写内核，只有自有空任务及新虚拟组；实际源码/状态/恢复/日志都落盘Cry，无systemd单位或/run项目文件。guard自身死亡/OOM及外部管理员干预不享有自动恢复保证。R02/R04及完整目标仍未完成。
