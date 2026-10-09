# 裸金属频率接口预检原件

日期2026-10-10（北京时间）。主机与解释见[预检说明](../../research/aris-frequency-20261010/README.md)。本目录是新证据；既有频率未控制的记录保持原状。

- `preflight.log`：首次root读取的工具原输出，保留CRLF及连接关闭行。SHA-256为 `db1f84775ff795452df418ab17934027c53cbf0575b1692ca83a58f793a625c1`。
- `preflight.json`：从上述日志提取的同一JSON对象；只规范缩进和换行，字段、错误及字符串值不变。
- `cppc.log` / `cppc.json`：补充CPU2/18的CPPC累计计数与报告尺度，原日志和规范化对象。
- `cppc-execution.json`：实际补充读取工具返回的退出状态与调用上下文；源是当时的新文件，执行前HEAD为 `abdf272295cf743266cb92cef485e63c8159d90a`，不冒称已提交源码执行。
- `execution-notes.json`：首次读取上下文、会话标识及源摘要的事后整理；明确区别原始stdout与事后登记的外层状态。
- `INDEPENDENT_REVIEW.md`：独立只读源码与原值核查记录。
- `SHA256SUMS`、`verify_snapshot.py`、`verification.json`：冻结文件摘要与本机证据完整性检查。它们不验证CPU实频、时钟精度或正式统计前提。

执行源为 [preflight.py](../../research/aris-frequency-20261010/preflight.py) 和 [cppc_preflight.py](../../research/aris-frequency-20261010/cppc_preflight.py)，使用内存源文本，实际 `-I -B` 隔离执行。首次源SHA-256为 `4e6eb918f66925b4100c0b2e545d0ae6dfe37f71746ee420596e89ff5ea7717d`；主线程核对了执行字符串、工具捕获字节与保存文件相同。零写入字段是固定源码声明，由源码审查支持，不是动态写入监视器。

两次读取均退出0；首次外层会话87297的终态来自会话工具记录，未在原stdout内携带，`execution-notes.json`不冒称原始工具回执。补充读取的实际终态记录见 `cppc-execution.json`。两次都在Cry内工作，不产生远端项目文件；认证只交给实际终端提示，不进入上述文件。

本次只发现接口，并确认CPPC累计字段可读。尚未直接读取MSR、取得两个注册反馈时点或资格窗口；R02/R04均不升级。没有频率或隔离配置改变，SSH主连接已正常关闭。旧KVM未核验、未登录或迁移。
