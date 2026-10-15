# M3 人工 LUT 夹具：本轮前置计划

日期：2026-10-16。工作环境：`/Users/yin/code/cryProject`，macOS/ARM。本计划先于本轮构建和自检，未授权也不执行采数。

本轮只建立人工访存校准夹具：32 字节输入逐字节通过公开 256 项置换表，输出映射为 `(197*x+101) mod 256`。开版本故意按秘密字节下标读取；关版本以公开固定顺序扫描全部表项，掩码选择同一结果。它不是 ML-KEM 解封装、上游真实漏洞或密码实现。

软件验证预定：严格 C11 普通构建；开、关分别穷举每个字节的全部 256 个取值及全部 32 个位置；检查空指针、错误输入长度、短输出、不写越界、原地及部分重叠；ASan/UBSan 独立构建。检查本机产物以保留机制信息，不将反汇编升级为恒时证明。

工具前置：探测 Valgrind、Intel Pin、Microwalk；提供可选 Valgrind Memcheck client request，使输入在 `mem_lut_apply` 调用前标为未定义，调用结束后恢复定义再消费结果。工具缺失时记录阻塞，不空跑、不生成定位阳性。

本轮没有时间 CSV、假设检验或 Holm 家族。后续采数须另冻结含类对、样本量、独立单位、环境、α 和停止规则的 PLAN 并提交；dudect 只能单列，不进入 Holm 家族。锁频采数由主控串行安排，boost 关、performance、约 4.30 GHz、taskset、进出 restore_match，退出恢复。本路不改全局配置。

主控在本机资格完成后授权追加只读定位：通过其已核验的共享 SSH，在 `/home/nss-marker/yhr/Cry/platform-s7-20261016-<nonce>/` 新物理目录部署同一夹具，设置本树内全部临时/缓存目录；使用系统 Valgrind Memcheck 实际运行开、关 poison probe，保存退出码、完整日志、编译器/主机/产物摘要。预期开版本出现未初始化地址使用，关版本无同类报警；失败照实记录。该阶段不是锁频采数，不写频率/隔离、不占用 CPU2/CPU6 的采数合同、不关闭主控共享 SSH。Intel Pin/Microwalk 仍仅探测。

旧 M1 vendor 与证据只读；不做密钥恢复、不跑 exploit、不修改 `sources/`、不 push。
