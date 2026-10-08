# FIPS 203 原文与固定源码的静态对应

核查日期：2026-10-08。标准为2024-08-13最终版；实现固定为b3ba7b32773e657dd37f6f87bce82528459ad8a4的便携C。只读核对，不修改上游，也不运行密码或机制复现。

[NIST发布页](https://csrc.nist.gov/pubs/fips/203/final)确认存在拟修订问题。[潜在勘误工作簿](https://csrc.nist.gov/files/pubs/fips/203/final/docs/fips-203-potential-updates.xlsx)在本轮2026-10-08 14:47:17北京时间的普通HTTP读取中返回403，浏览器接口也不可用。工作簿条目及完整适用性仍未认证；下述事实来自可读的[NIST原PDF](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.203.pdf)。

## 两项可核定的静态事实

| 原标准位置与事实 | 固定源码对应 | 当前判断 |
|---|---|---|
| 正文第44页附录A含128项表值，其中含索引0；算法9/10的索引实际为1至127 | poly.c前/逆NTT层使用相应非零索引区间；乘法缓存另取64至127 | 该便携C路径不读取索引0表项；不由此推断全部硬件后端 |
| 正文第31页算法15第6步产生差多项式w，第7步压缩w，末注释却写从v解码 | indcpa.c在解码前原地执行v减去sb，再约减和tomsg；此时v已是差多项式 | 原注释存在内部不一致；未发现固定源码照注释去解码未相减旧值 |

这两项是否等于工作簿全部正式条目仍未认证。标准静态一致性与官方勘误适用性是不同核定事项，不能用前者替代后者。也不把注释错误称为当前密码实现漏洞。

## 来源身份与范围

2026-10-08 14:55:54北京时间，固定上游raw文件均返回HTTP200，与本地文件逐字一致。主代理随后独立重算本地摘要，得到同一结果：

| 文件 | SHA256 |
|---|---|
| [poly.c固定来源](https://raw.githubusercontent.com/pq-code-package/mlkem-native/b3ba7b32773e657dd37f6f87bce82528459ad8a4/mlkem/src/poly.c) | f0e0643a2c3743181b7927a9d47af0930ce7870a9d79671f64e6089fe028982e |
| [indcpa.c固定来源](https://raw.githubusercontent.com/pq-code-package/mlkem-native/b3ba7b32773e657dd37f6f87bce82528459ad8a4/mlkem/src/indcpa.c) | deec4767a465d71656862d55c26a45775e9bf4328e0837c3cb2e23b6a06ea0ec |
| [zetas.inc固定来源](https://raw.githubusercontent.com/pq-code-package/mlkem-native/b3ba7b32773e657dd37f6f87bce82528459ad8a4/mlkem/src/zetas.inc) | 303d1abccc4757d49a5c8df5f88080fefef617b7360056db5311bd94354096d4 |

核查只覆盖上述源码路径和原文关系，不补成标准条款全覆盖、形式证明、模块认证或时序安全证明。T09可以记录这项实质进展，仍保留官方工作簿完整适用性未核。
