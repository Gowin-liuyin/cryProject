# 多泄漏平台匿名支撑包生成器（2026-10-16 刷新）

新报告与证据按白名单生成新 ZIP；旧支撑包（draft05/10/11/12）保持原字节。
当前最新已核验包为 [refresh-20261016](CACR2026EA16XZ-platform-refresh-20261016.zip)：
**758 成员、757 摘要、66 个本地 HTML 链接**，SHA-256
`61759372cb82e8d3cbe10df909b1fb96fa1df11100d77243581a8786ed7565b4`；报告为 17 页，
含题面第 3/4/5 条对照表与六类泄漏来源 × 四步定位表，M2–M5 统计处为 `«待主控数据»`。
**从该实包解出后**在新建目录独立重跑 CMake + build + CTest：**5/5 通过、0 失败**；
离线回放 6 份数据集、12 个 C 输出逐字一致，包内原始时间输入字节未变。
命令与逐项结果见
[zip-recompute.log](../../../docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute.log)，
逐项刷新记录见 [REFRESH.md](../../../docs/evidence/platform-report-20261016/refresh-20261016/REFRESH.md)。

```sh
python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/build_support.py --revision <新revision>
python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/verify_package.py <实际ZIP路径>
```

每次必须用新 revision，不覆盖已有包（`refresh-20261016` 已占用）。包内含报告、对照表数据、
自包含 C11 离线复算、有限证据副本与合法依赖许可证；不包含 RTLF/Mona 等许可未明确的工具源码、
私钥、凭证、构建 ELF、缓存或旧原件归档。

数值 CSV 保持原字节；路径和身份只在新文本副本转换，记录来源与副本 SHA-256；报告离线 HTML 的
证据链接在包内重写为 `evidence/files/` 下的副本路径。转换是有限的直接身份处理，不承诺公开内容
无法关联作者。真正验收须仅从实际 ZIP 提取，核对成员/摘要/引用/元数据/匿名，再构建并执行 C 复算；
主控回填 M2–M5 真实统计数字后，须再出一个最终 revision 并重新复算。
