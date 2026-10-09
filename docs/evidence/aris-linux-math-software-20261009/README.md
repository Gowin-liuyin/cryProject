# Linux纯数学软件验证证据

实际数据来自约定裸金属新目录/home/nss-marker/yhr/Cry/aris-linux-math-software-20261009-2025b63，原source/run目录未改。已验证密码访问，不在本目录保存口令。原预检、四配置CTest、源码前后清单、产物记录和只读复算输出保留；没有新的正式数学计时或密码实验。

[结果解释](../../research/aris-linux-math-software-20261009/RESULTS.md)、[独立审查](INDEPENDENT_RESULT_REVIEW.md)、[机器核验](independent-validation.json)及[实际执行收据](execution-receipt.json)分别说明适用范围。results/outputs的157份文件与取回tar绑定，新增解释文件不混入原tar，原数据及旧M01/M02身份不改。

原审计manifest的sanitizers=OFF为静态原配置字段；两份动态审计实际编译/链接参数启用ASan/UBSan，不能以旧字段声称没有启用，亦不声称字段完全一致。十二个远端ELF摘要未在本地重算，本文不补造该检查。

本地固定根拒绝曾因macOS realpath选项不兼容先退出，仅相对路径拒绝确实执行。此次Ubuntu负向调用实际进入固定根拒绝分支，根工具收据验证退出2且未创建输出；先前本地范围限制和失败保持。

范围为软件兼容与已有记录复算，不改变R02/R04和全目标签收。频率、时钟来源、CPU拓扑、温度和两次负载快照见preflight.log；静态快照不证明测量期间持续控制或资源独占。
