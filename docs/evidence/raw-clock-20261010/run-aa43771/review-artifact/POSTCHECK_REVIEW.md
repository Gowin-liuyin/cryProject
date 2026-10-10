# 结束后PID与SSH关闭回读补充审查

结论：root保存的实际结束后回读完整覆盖本次33个已记录PID，全部观察为`/proc`不存在；最终SSH控制连接关闭回执一致。本补充关闭`ARTIFACT_REVIEW.md`中外部原PID核查和SSH关闭的两项待核，不改变原科学适用边界。

本审查只读root已经取得的`postcheck.stdout/json`与`ssh-close.stderr/json`，与实际归档中的`run-state.json`、`commands.json`和case PID逐项对照。审查者没有再次SSH、运行C或修改原归档。

核对集合为管理PID3675161、29条命令的29个不同supervisor PID，以及三个collector PID3675337、3675340、3675343。三类集合互不重叠，合并恰为33个，与回读`pid_checks`键集合完全相等，无遗漏或额外PID。每项均为`present=false`、`start_ticks=null`；这里的null是进程不存在时没有可读启动tick，不补造退出tick或启动值。原管理进程的343006206启动tick仍由开始认领与归档状态另行绑定。

回读同时记录当前普通用户调用者亲和性为CPU0—31，运行根、同级归档和上传包三个路径均存在、非符号链接，实际物理路径逐项等于原Cry内路径。远端回读归档SHA及本地实际归档SHA仍为`e6dfd03f03e1e2e4e28a4eb0c251a8f7d684745980727843263e4ad8ff1870e6`。回读记录没有配置写入或云端项目文件写入。这是所记录路径与调用者状态的时点核查，不把当前调用者亲和性推成全机独占或全局调频恢复证明。

`postcheck.stdout`解析后与`postcheck.json`逐项相同。关闭回执记录控制连接退出0、套接字已不存在；stderr原字节为`Exit request sent.\r\n`，关闭UTC为2026-10-10 10:59:19.348216。它晚于归档内工作截止UTC。回读JSON本身没有另含查询UTC或外层命令退出码，本补充依据root保存的实际回读内容及关闭记录，不声称独立复执行或补写未记录的值。

| 已核原件 | SHA-256 |
|---|---|
| `postcheck.stdout` | `85d1fa26a5272290aad959d71567d1965d4bc68b3196185331cb4491727d5cf4` |
| `postcheck.json` | `a0593037befa8778fbfc9234deff052e6af2cd9252235e3c736c12488dd049b1` |
| `ssh-close.stderr` | `f221bc2585c4efebca01f34f20087bcddc8e9389f57abc26d57eab159b7d1b2b` |
| `ssh-close.json` | `e3c54ef465a4b65b42a400d89fe2fddcd12fdcd0c8268f1610d967c9087fce74` |

完整PID清单与机读核对见同目录`postcheck-verification.json`。33个记录过的PID在回读时消失，不是全机所有进程、未记录任务或任意异常路径的认证。该补充不产生新采样，不证明恒频、测量绝对精度或统计前提；R02/R04保持部分签收。
