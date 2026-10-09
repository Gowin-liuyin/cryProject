# 测试临时目录修正的本地核验

2026-10-10。目录沿用工作开始日20261009，原日志时间保持。环境为macOS/ARM、Apple Clang21；本页不是Linux或正式测量结果。

九处C测试原硬编码/tmp的mkdtemp已统一改为C辅助入口，必须取得CTest配置的绝对A113_TEST_TMPDIR，缺失或相对路径、非法前缀及缓冲区不足均在创建前拒绝。128字节目录缓冲区给原有最短256字节派生文件路径保留余量；过长配置明确失败，不回退系统临时目录。CMake创建各构建自己的test-tmp，拒绝该目录为符号链接，并在全部注册后追加A113_TEST_TMPDIR、TMPDIR、TMP、TEMP。Shell测试的mktemp继承同一根，嵌套测试和并行测试使用各自唯一子目录。

实际[注册原件](ctest-registry.json)的35项测试均含四个预期变量；这仅证明配置，不是35项均执行。最终[相关十项](final-10-tests.log)10/10通过；ASan/UBSan仅对新增目录辅助测试执行，[结果](sanitize-helper.log)1/1通过。缺失/相对根、逃逸前缀、小缓冲区、目录唯一性/0700及清理有C断言覆盖。[符号链接根配置](symlink-configure.log)被拒绝，链接目标目录保持空。代码及CMake格式检查通过。

随后将新变量和容量宏补全bytes单位后，全部受影响测试重新编译，[最终十项](final-byte-unit-10-tests.log)仍10/10，当前辅助测试[动态检查](final-byte-unit-sanitize.log)仍1/1。实际编译/链接中的ASan、UBSan参数和两份辅助程序摘要见[产物核对](local-artifact-check.json)，不是只读取静态预设名称。

负结果保留：[首次十项](initial-10-tests.log)9/10，paired_runner在init失败；当时只重建测试端，配套CLI尚未同步。补齐运行器后[相关两项](second-related-tests.log)中paired_runner在工作程序阶段仍失败，原部分记录的预算source_commit为476d827，而工作程序meta为dc3380e。随后同步未修改参考工作程序和分析器，再[相关两项复查](third-related-tests.log)2/2通过；最后才完成同一组十项10/10。没有放宽来源校验或删除失败原件。初次新头文件编译还暴露macOS的mkdtemp声明来自unistd.h，补入自包含头文件后严格C11编译通过。

改动限测试文件放置和CTest配置，不改密码算法、统计核心或原始六模块。普通参考工作程序的小样本属于软件自检，不进入性能或统计确认；没有恢复旧K4/K16开发及20对正式路线。已封存源码和证据保持，不能把本次通过回填到旧快照；旧快照中的/tmp测试仍受AGENTS新路径规则限制。

独立同模型代理已只读审查9处调用、嵌套环境、追加属性和路径边界，未发现实质阻断；不冒称外部同行评审，也不宣称防止运行期间外部替换父目录。

用户再次授权密码登录后，对旧KVM尝试用原已信任的ECDSA算法进行严格身份核对，[结果](kvm-identity-check.json)仍为主机密钥不匹配、退出255；未发送密码、未改known_hosts。密码认证仍需先通过服务器身份校验，依据[OpenSSH说明](https://man.openbsd.org/ssh_config#StrictHostKeyChecking)。其身份及ubuntu账号凭据对应关系等待用户从可信控制台确认，不以主机密钥错误冒称密码错误。

另核实本机对该IP保存ECDSA、ED25519及RSA三类主机公钥记录；使用原RSA记录和强RSA-SHA2签名作[严格核对](kvm-rsa-identity-check.json)，同样拒绝且没有进入密码认证。未打印或归档用户身份密钥内容；现有记录未修改。该核对排除了仅新增算法导致选择不同的安全备用路线，当前仍需可信身份确认。
