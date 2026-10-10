# 最终草稿的独立数值与声明复核

审查通过：RESULTS.md的六行主表、六行预热表、六行时间账、五行采样间隙以及完整算法调用表均与原C表/摘要、原CSV边界和全量独立verification相符。差异清单为空。只读审查，没有修改docs、运行C/SSH/collector或新增采样。

逐字绑定本次被审草稿：

- `docs/research/aris-ordinary-repeatability-20261010/RESULTS.md`：SHA-256 `a17ebec83c23f007203d1ac72754fc77d2c5f2689accf2b623f93f41cffed21f`，11079字节。
- `docs/research/aris-ordinary-repeatability-20261010/RESULT_TO_CLAIM.md`：SHA-256 `9ae7886ec8184802405737a55ba8a27ca0d3a81ecba14881c24f8b9b0aeb1d76`，2149字节。
- `docs/research/aris-ordinary-repeatability-20261010/findings.md`：SHA-256 `06af9f995e9926bcc3d145675346bdbe6f60d2b82c7d8381e3386f3547662547`，1290字节。

40ns主中位数范围与70ns主P99范围仅为六进程观察范围，不是误差界；预热max68449ns保留。固定25000次预热实际wall为768859389—770464881ns，文中约0.769—0.770秒是三位小数近似，不冒称一秒或旧G2同条件。

两管理阶段实际7.467984377872199秒/5.215190363116562秒与state一致；管理入口在前置核验之前启动计时，导出/上传/认证/下载不在该工作量内，E1含构建与两配置资格而E2复用，草稿明确不作公平效率或端到端比较。

调用单位核对为直接完整算法入口：每配置65次KAT路径+1次公开fixture=66，两配置132；Linux计132资格+300000计时+6setup=300138，其中decap300030、keygen54、encap54。Mac另132，本研究本轮合计300270；参数拒绝/直接密钥校验/测试SHAKE单列，非内部动态插桩总数，管理读钟不混入600000采样读钟。Mac实际两4/4日志、资格回执与Linux原state均另核，不以计划数代替完成。

source四摘要和普通collector/analyzer两ELF摘要均与此前全量实物绑定相同；当前证据两tar的大小/SHA亦一致。C原摘要三个接受相关false以及precision/iid/R02/R04 false均保留，管理另核接受，两层未混同。

RESULT_TO_CLAIM.md与findings.md把yes限定于冻结同fixture/普通产物的六新进程有限描述；同boot RAW间隙不作独立环境/长期稳定，旧G2条件不同不作算法提升，R02/R04仍partial，外部Codex仍pending。三个被审文件的9处本地链接均存在，未发现缺失链接。

完整机器可读核对见draft-verification.json；此为同模型独立内部审查，不称外部同行评审。
