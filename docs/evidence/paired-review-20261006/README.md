# 代码审查修复软件验收证据

固定软件源码951fb3ece9819cc58672a5de61325cf4b3ea31f2，ARM64 macOS，非原生Linux结果。
release-tests.log与sanitize-tests.log各13项通过；registered-tests.json只有注册信息（29项）。
软件失败目录来自实际C测试，ORIGIN明确范围；其中共享预留和拟议计划不是正式实验成本。
构造确认形状的资格夹具留在临时测试目录，不放入任何真实平台收益表。

所有构建身份/命令、源码摘要、二进制摘要及普通反汇编保留实际版本，不回填以后的文档提交。
六个源的静态分析、格式、原样旧证据及回放检查另存。中间编译/构建身份错误原日志保留，
不是最终通过结果。release-last-test.log来自CTest列举动作，未执行测试；真正失败原始日志为
release-failure-record-last-test.log与sanitize-last-test.log，不将列举数冒充执行数。

self-reproduction.log记录新临时检出、固定951fb3e、全新构建和复算：两份新报告与原软件
expected.report逐字一致。仍是作者自复现，没有第三方或目标设备重采。
原生成本、开发/K选择/20对确认均尚未执行；当前主比较证据不足。

SHA256SUMS用仓库相对路径覆盖本目录全部文本证据；不带二进制、构建缓存、symlink或锁。
必要source通过Git固定提交恢复，旧封存软件原数据保持原样。

```sh
shasum -a 256 -c docs/evidence/paired-review-20261006/SHA256SUMS
```
