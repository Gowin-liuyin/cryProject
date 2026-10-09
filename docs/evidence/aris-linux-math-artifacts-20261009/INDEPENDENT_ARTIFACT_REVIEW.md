# Linux 数学原产物的独立静态复核

2026-10-09 后续补录。十二个本地 ELF 原件的 SHA-256 均与此前封存的远端原始摘要一致，四配置各三件无缺项。此项关闭的是原结果中“没有 ELF 原件，未在本地重算二进制摘要”的证据缺口；原时点记录保持，不倒写成先前已完成。

本复核只读取取回文件、ELF 结构和原构建记录，不执行 ELF、不构建、不运行 CTest、不连接服务器。没有新时间样本或密码调用。传输及远端取回过程由主代理另存收据，本页不替代该收据。

## 摘要与字节对应

取回包 SHA-256 为 `379d63c7fccbef9803643d17c659e5bbf65923ac52f9fa64c2213b2422faa538`。十二个普通文件与 tar 内对应成员逐字节一致；每件的本地摘要、原远端路径及对应摘要记录见 [机器可读复核](INDEPENDENT_ARTIFACT_REVIEW.json)。

| 配置 | 产物 | 本地 SHA-256，与原远端记录相同 |
|---|---|---|
| GCC13 普通 | update_cost | bb6c11127c54f1831e0547f68d1d1a183c67657bf0624670770f42f77ae9997a |
| GCC13 普通 | process_summary | 4ab94d7847560b572cb2a01e74b113560d8d332fb2a15f11e2a1bb90c5e7ca03 |
| GCC13 普通 | update_cost_result_review | 42140996d60fb50d8b86acd71736c628deab045d59236eb54e118b388e65e6af |
| GCC13 ASan/UBSan | update_cost | 2072548e770d9f6eb9be82ae3cd25bc16e302d018c74005b939fb5e016ff539f |
| GCC13 ASan/UBSan | process_summary | da8dce9878b2c50988ec05cdcbf7dc465ab56168c816fd35c9647370c2d3b251 |
| GCC13 ASan/UBSan | update_cost_result_review | bed133bdfeda629e2d9def3cf1dd3e48c912c0bc5a720f2df80d88db2142add3 |
| Clang18 普通 | update_cost | 71a86519ab697a81b15efa9b2ab7b99d2d162b18fc55828a51fc231ad98bbcbd |
| Clang18 普通 | process_summary | 32de97aa2f47da42d4d490535f5c1dbcb576e06a95c0d56eaa12f6325d8b67b9 |
| Clang18 普通 | update_cost_result_review | 50546a3e4d3f174c2210c058cf4f65eb4b41ce63ad0c9000179ed2608dae7ea1 |
| Clang18 ASan/UBSan | update_cost | 6d33dc0fe7dc1fbf5b61a880b36af6d373cf0b431f70350b66f96936cc6312cd |
| Clang18 ASan/UBSan | process_summary | f389854b75662c61aa578b810e6940b1f116a346363630fe1919dea74b78163b |
| Clang18 ASan/UBSan | update_cost_result_review | add9e62cb0f8c2dc96229e90b8b2938e364e341604488f524b32248d3a9b5bb6 |

同时重新读取 [原证据清单](../aris-linux-math-software-20261009/RESULT_SHA256SUMS)，其中 166 件文件均保持清单摘要。该检查保护封存边界，未修改原 157 件结果文件、解释记录或旧结论。

## 格式与配置核对

直接解析 ELF 头、程序头、节表、动态依赖与符号表，并用本机 `file` 工具作格式交叉核对。十二件均为 ELF64、小端、`EM_X86_64`、`ET_DYN` 的 PIE 产物，解释器均为 `/lib64/ld-linux-x86-64.so.2`；均保留调试信息及符号表。各件 `DT_NEEDED` 直接依赖均得到原远端 `ldd` 记录支持。未在本机调用 `ldd` 或加载产物。

逐件对应的原编译命令共 24 条、链接命令共 12 条，均保留 C11、`-O2`、`-fno-lto`，未见启用 LTO。普通六件无 sanitizer 链接参数、ASan/UBSan 符号或对应动态依赖；动态六件的实际编译、链接参数均含 `-fsanitize=address,undefined`。

GCC 动态三件直接依赖 `libasan.so.8` 和 `libubsan.so.1`，ELF 中存在 ASan/UBSan 未定义导入符号；原 `defined-symbols` 不含 UBSan 因而不能用于否认启用状态。Clang 动态三件没有上述独立库依赖，但均定义 313 个 ASan 与 49 个 UBSan 符号，体现运行库嵌入产物的不同链接方式。符号和依赖证明本次产物配置，不能证明所有路径均受动态检查覆盖。

原独立审计 manifest 在动态配置下仍写 `sanitizers=OFF`，其静态字段保持。有效配置由实际编译、链接、产物符号及原运行记录说明，不宣称全部字段一致。

## 身份与结论边界

`SOURCE-MATH-COST-01` 是导出件的匿名源码别名，`source_identity_kind=anonymous_source_alias_not_git` 明示它不是 Git 提交号；源码身份还由逐项源摘要固定。ELF 原件保留真实调试及构建路径，存放于内部工程证据，不纳入匿名支撑 ZIP。

本次关闭的是十二件实际 Linux 数学软件产物的本地字节核对。此前被复算的 M01/M02 原计时数据仍来自 `Darwin/arm64`，不能因为复算软件运行于 Linux 而改写数据来源。原 [软件验证结论](../../research/aris-linux-math-software-20261009/RESULTS.md)仍限定为真实 Linux 四配置的软件构建、检查与封存记录复算。

本补录不新增 Linux 成本实验、跨平台加速结论、频率控制、统计独立性、真实总体误报率或检出率、恒时结论，也不覆盖旧密码模块的 GCC 动态失败。R02/R04 仍为部分签收，完整研究目标尚未完成。
