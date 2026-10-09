# 普通参考窗口候选的真实Linux软件检查

2026-10-10，按[纯软件合同](../../../research/aris-frequency-window-20261010/LINUX_SOFTWARE_CHECK.md)在Cry新目录执行。源提交 `7e93048f3af885d14f1577b3a198bd3d52b8ee8e`；源tar `9229b613ead32f49ee73285fa39dff6b060b20287e3fce3a6bb9db944d8e84a4`，C源 `ead1029864025047ca0df2bf1d7bea179040f151313589389c043e3a7b9ef68a`。未修改reference核心、配置、vendor与公开向量随源导出，许可证保留。

`window-source-7e93048-software.tar` 为618唯一常规成员，含617载荷与清单，SHA-256 `408931d4b09ba516e22fc01c3dc748ace7b69d527c456ad9d8251461853c2dbc`。全量载荷摘要/长度、四个Linux x86_64 ELF头及全部选取副本已核对；树载荷8332713字节，source树无符号链接。

实际GNU13.3.0、CMake、RelWithDebInfo/C11/Werror，普通与ASan/UBSan各六项编译命令没有变体宏或补丁路径；编译/链接配置与两项CTest原日志在 `selected/`，全量原件在tar。每配置实际2/2：纯软件selfcheck、原NIST/接口/随机往返KAT。配置/构建/测试六步全部退出0；两个workload原ELF摘要如下，另两个KAT摘要在artifact-digests：

- normal：`a4cb64271735ff40a7a40c8bbf67ad5a08841c4f3e05fb9182bc7e1991de1cfc`。
- sanitize：`f783076bd7fe0e414a5ff293ed6921196861616179e2a63aaf77b5f3b7ce1703`。

[独立实物复核](ARTIFACT_REVIEW.md)逐字节比对138份固定源码、617项载荷、两套原测试及四个ELF；[验证器](verify_software.py)提供归档/选取副本、命令及原值身份的重复检查。[最终验证结果](verification.json)仍明确G2没有运行。

实机检查之后，当前CMake文件另经纯格式提交 `2bf202841e0e39dfded9c891e4f927ea8d9565a7` 整理布局，固定格式检查及本地独立configure通过；C源未变。本目录仍绑定7e93048原字节，不将旧Linux执行回填成新提交执行。

只运行 `--selfcheck` 与独立KAT，没有运行无参普通入口、读取MSR、采集密码时间或修改频率/亲和性/cgroup；ASan产物不作性能证据。Linux普通分支已经完整编译，此事实不能由先前Mac/ARM自检代替。

`orchestration-source.py`是当时未提交的精确内存执行源，使用固定源摘要和明确参数；六步原始结果/PID/启动ticks和命令均在run及逐步骤文件中。外层返回是分两次工具响应取得，未将最终完整envelope另存；不冒称外层凭证完整。实际逐步骤原日志、CTest与产物独立保留。

云端源码、构建、缓存和日志均在 `Cry/window-source-7e93048/`，导出在Cry同级 `window-source-7e93048-software.tar`，临时环境在该树内；本轮主连接已关闭。通过仅支持Linux编译及两项软件资格，G2长worker生命周期、真实频率窗口及R02/R04仍未签收。
