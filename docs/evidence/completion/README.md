# 当前功能提交的收尾证据

源码：203eb253941e7d2b69c421d9d9f9eae79d186089；构建时工作区干净。
CMake 4.3.2 / Ninja / RelWithDebInfo，Apple Clang 21，Apple M5 ARM64 macOS。
采集程序无 sanitizer；sanitize-ctest.log 为同一功能源码在独立动态检查目录的结果。

- configure.log、build.log、ctest.log：从空目录构建与 8 项 CTest 全部通过。
- reference.csv / vulnerable.csv：各 500 条，五类各 100，未删长尾。
- .meta：源码、构建输入、实际 CPU/时钟/选项/二进制摘要；构建时状态为空、diff 摘要为空输入摘要。
- record-checks.txt：逐次记录校验和独立 OpenSSL SHA3-256 核对。
- binaries.sha256：实际采集文件的 SHA-256。可执行文件保留于 build/completion，未提交缓存或二进制。
- vulnerable-path-arm64.txt：与采样完全相同的文件，包含 main、封装、解封装、重加密及消息编码路径。
- reference-encoder-arm64.txt：相应参考产物的编码函数。

缺陷产物中，起点读钟为 0x100000cfc，完整解封装调用为 0x100000d1c，终点读钟为 0x100000d28；
0x100000d48 才读取共享密钥字节作结果消费，文件输出在整批循环后。
解封装分别在 0x10000b944 和 0x10000ba00 调用解密与重加密，重加密在 0x100006e94 调用编码。
编码入口 0x100002690；+0x48（0x1000026d8）的 tbz 按解密消息位选择 0 或 1665。
这些地址只对应本目录摘要标识的产物，重新构建需重新定位。

数据仅为软件基线验收。已确认目标机制并采集原始数据，时间差异尚未正式统计确认。
