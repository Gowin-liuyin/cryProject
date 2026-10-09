# 反馈读取模块准备记录

2026-10-10，本目录保存本轮执行前的真实资源读取与本地软件检查。正式运行另存新子目录，不以这里的准备状态代替实机成功。

`inventory.log/json` 是nss-m普通用户的实际工具/表清单与Linux身份；`firmware-nodes.log/json` 是CPU2/18缓存节点的path/uid/hid，分别对应C004/UID4与C005/UID5。精确内存执行源保存于本轮研究目录。两个SSH进程实际退出0，未创建远端项目文件；它们只检查资源及缓存映射。

`ubuntu-package.html` 是通过HTTPS取得的Ubuntu noble官方下载元数据原页，包名 `acpica-tools_20230628-1_amd64.deb`，大小919728字节，SHA-256 `1282c3e0f5f3e53759350e98e68b96bf31d1f381aaf1e0abdbd750f7a131841c`。本地已下载并核对相同摘要，仅供后续Cry内独立解码器使用。未安装系统包；许可证与实际工具摘要须在解码执行原件另存。

`local-normal/` 与 `local-sanitize/` 各保留实际CTest日志、CMake缓存、编译器/系统配置、flags/link和configure日志。两次自检各1/1通过，均无硬件设备读取；macOS/arm64不是Linux分支实测。没有单独保存完整build stdout，构建工具成功状态登记于 `local-check-notes.json`，不冒称完整原始构建回执。

独立源码审查见 `SOURCE_REVIEW.md`：C设备读取限定通过，collector初版三项缺口已在执行前修复。格式检查通过。所有源码执行前须按新提交冻结，本地构建不作为性能证据。
