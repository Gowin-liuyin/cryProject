# 最终实测证据

功能代码提交：`e519d941ddcf8a4dfb9e92f5b9343db53fc36064`。
在该提交的干净工作区从全新 build-release 构建；meta 的工作区状态为空，
tracked_delta_sha256 为 SHA-256 空输入摘要。随后才生成本目录文件，归档提交只增加证据和说明。

真实机器：Apple M5，macOS Darwin 25.6.0，ARM64；编译器 Apple Clang 21.0.0。
默认 O2，无 LTO；回归编码函数使用 optnone/noinline。当前未做真实 x86_64 Linux 验证。

- build-and-test.log：该次构建的实际完整命令与检查输出。
- reference.csv / vulnerable.csv：各 5000 次正式产物的原始解封装时间，五类各 1000；不删长尾。
- 对应 .meta：run_id、seed、时钟分辨率（1000ns）、CPU、编译器、构建清单、源版本及二进制 SHA3-256。
- record-checks.txt：C 记录校验、独立 OpenSSL 摘要及二进制 SHA-256 核对。
- binaries.sha256：采集和 CLI 可执行文件摘要；二进制留在忽略的 build-release，不作为源码文件提交。
- reference-encoder-arm64.txt / vulnerable-encoder-arm64.txt：实际采集程序中的消息编码函数。
- vulnerable-path-arm64.txt：同一采集程序的计时入口、解封装、重加密及编码调用路径。
- sanitize.log / sanitize-build.meta：独立 ASan/UBSan 运行及构建信息；当时未提交的源码现在属于上述功能提交。
  已比较 sanitizer 与 release 的 build_input_manifest，全部构建输入摘要一致，区别在编译选项和版本状态。

## 机器码核验

以下地址只属于本目录摘要标识的 ARM64 产物；换构建必须重新定位。

- main 的 0x1000008f0 读取起点，0x100000910 调用 mlkem_decapsulate，0x10000091c 读取终点。
- 0x100000938 起消费共享密钥字节，位于结束计时之后；0x100000978 才调用 save_measurements。
- 包装函数 0x10000171c 跳转到 baseline_native_dec（尾调用）。
- 解封装在 0x10000bec4 调用 indcpa_dec，在 0x10000bf80 调用 indcpa_enc 重加密。
- indcpa_enc 在 0x100007414 调用编码函数。
- 编码函数入口 0x100002c10；0x100002c44 的 ldrb 读取消息，0x100002c54 右移选位，
  0x100002c58 的 `tbz w8,#0` 按消息位选择写入 0 或 1665。该位来自解密消息 m'。
- 参考编码函数仅出现固定循环次数的分支；该局部观察不等于整个参考程序恒时证明。

源码秘密依赖、产物秘密相关分支和原始采集已确认。未进行统计检验；
不宣称已经观察到可靠时间差异，也不宣称参考版无泄露。原始数据可供下一阶段按预定规约分析。
