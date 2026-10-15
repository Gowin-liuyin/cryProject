# M5 本轮实际环境与产物

本机为 macOS/ARM，只执行软件资格；普通与ASan/UBSan各1/1（完整poison harness功能模式/非instrumented拒绝）。
原生工具结果来自真实Linux nss-m x86_64；未执行任何M5时序采集或调频/亲和写入。

| 项 | 实际值 |
|---|---|
| 主机 | nss-m，Linux6.17.0-35-generic，x86_64，32在线逻辑CPU |
| 编译器 | Ubuntu Clang18.1.3，/usr/bin/clang-18 |
| 构建 | CMake3.28.3，C11，RelWithDebInfo，ordinary=-O2 -g -DNDEBUG；无LTO，portable reference |
| sanitizer | 独立build，ASan+UBSan、-O1 -g；只作功能资格，不作为计时或Valgrind产物 |
| 系统Memcheck | Valgrind3.22.0；system模式不加不存在的varlat选项 |
| 补丁Memcheck | S3 Valgrind3.25.1，两原20250805补丁，显式varlat=no/yes |
| 源身份 | 工作区完整verified source export，不能冒称单一Git提交 |
| 私钥标记 | PKE[0,1152)，z[2368,2400)，共1184秘密字节；pk/hash/ct公开 |
| 动态输入 | 公开seed31337/424242，每seed五类；每模式10次被标记完整decap |
| 资格 | v1与v2普通/ASan各7/7；NIST KAT/边界/随机源、CLI/向量拒绝、向量完整性、poison功能、dudect无读钟自检 |

唯一独占物理根：`/home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26`。
`source/`、`source-v2/`、`build-ordinary/`、`build-sanitize/`、`build-v2-ordinary/`、`build-v2-sanitize/`、
上传载体、`logs/`、`logs-v2/`与最终归档全部保留，不覆盖旧原件。
TMPDIR/TMP/TEMP/R_TMPDIR=`<根>/runtime`，XDG_CACHE_HOME=`<根>/cache`。
source-v2含413个普通源/测试/构建/计划文件，SOURCE_EXPORT.sha256已全量核对。
源/构建/runtime/cache链接清单为空，无物理越界；测试与C源无显式/tmp或/run/路径。
编译最多-j4，未装系统包，未改HOME，未关闭主控共享SSH。
结束匹配M5源码根的worker清单为空。

v1用于首次普通/动态资格；v2新增online原始tick写出及无读钟写出自检，完整重新资格与定位。
两代均未运行online --collect。反汇编中包含潜在计时入口不表示已执行该入口。

## 固定摘要

| 原件 | SHA256 |
|---|---|
| source-upload.tar.gz | f2409900ceecb9b277af73aa0e1de1c46af5b0cbc68b217579207a28bd19bd79 |
| source-upload-v2.tar.gz | 6c598f7ecfffac2d6737561af343dce9805da68b320fb8c595825d8a30bdc52d |
| v2 ordinary platform_m5_poison | 586c2d65bbb6d0ea04c4f027e29d3a2e9c8fe207965817bb67813061a6c4d6d0 |
| v2 ordinary platform_m5_dudect | 3be8772155774ad7cbcdc3ca1633d282f6209bfc5a6964eb60d7d705f902f77d |
| v2 ordinary reference/measure | 4ff0956ac79550bc62caa0ea8d88968d3de8a926aebace9535481cb232145fa8 |
| v2 ordinary reference/libmlkem.a | ed9a658183562a88a96a631602cdcdd137d4bb405bd224fc2ac8cf682514416a |
| 系统memcheck-amd64-linux | 12f414dd4d8ecd531777d12813242e3b3560792a21781573af55d7a16099e792 |
| S3 patched memcheck-amd64-linux | c040a127b5c61fdc0c3b0b7fb94edd869fc8248416733cde84ad3b6b56dd48f6 |
| software-dynamic-evidence.tar.gz | b280855412d389fcc76a8cd19f53346164524d6aa93a32d7a07c803939d7eb02 |

本地资格归档约481KiB，下载后摘要与远端一致。含两代源清单、完整编译/CTest/Valgrind日志、
两个普通ELF的完整反汇编、符号/链接/编译命令、工具与产物摘要、路径与结束扫描、
v2自有工具/测试/CMake/准备期PLAN副本。完整上传源码与ELF留在同一Cry根及本地build。
源码导出中PLAN是准备期版本，最终采集合同应以主控之后的本地提交为准。
