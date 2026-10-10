# 有限样本补充的来源核查

日期：2026-10-10。只记录本补充实际使用或排除的来源与阅读范围，不改旧书目身份，不把定向定理核查称为全文精读。

## 实际证明依据

**Ilya Tyurin. _New estimates of the convergence rate in the Lyapunov theorem_. arXiv:0912.0726v1，2009-12-03登记。** [固定版本摘要](https://arxiv.org/abs/0912.0726v1)；[固定版本PDF](https://arxiv.org/pdf/0912.0726v1)。作者原始研究预印本，19页；不是本页新确认的同行评审全文。

核查范围：摘要、PDF第1—2页中独立中心化变量、总方差及三阶绝对矩的定义与式(1)，PDF第6页定理7；另查看PDF第15—17页相应证明的计算性部分，未独立重现其计算证书。定理7区分一般独立和iid情形；一般独立情形常数为$0.5606$。本补充只使用其蕴含的更宽常数$C_{\mathrm{BE}}=1$，不把iid常数用于不等权符号。

版本说明：arXiv登记与页眉标识为v1、2009-12-03；读取到的PDF正文另有“October 24, 2018”的排版日期。此处按存档版本标识引用，不将排版日期说成新版本或正式出版年。访问无版本URL得到同一v1标识；尝试v2返回404，未假称存在第二版。本文没有保存或改写该论文PDF。

自足部分：原设计的方差分解、覆盖事件移项、Chebyshev界、$\cosh$矩母函数界、事件并集及CDF左极限均在[PROOF_PACKAGE.md](PROOF_PACKAGE.md)完整推导；无需另外借一个只适用于已知方差的区间定理。

## 核查后未作为数值常数依据

**I. G. Shevtsova. _An improvement of convergence rate estimates in the Lyapunov theorem_. Doklady Mathematics 82, 862—864 (2010). DOI: 10.1134/S1064562410060062。** [出版方页面](https://link.springer.com/article/10.1134/S1064562410060062)；[出版方目录](https://www.pleiades.online/contents/danmath/danmath3_10v82cont.htm)。实际只核实题名、作者、卷页、DOI、2010-12-24出版日期及订阅访问状态。目录所连摘要页仅显示题名、作者、收稿日期与DOI，未提供可核对的定理陈述。

检索片段和其他论文提到$0.56$，但本次没有从这篇原文正文核实精确定理条件与常数。因此补充不以该数值为依据、不称全文已读，也不依赖二手帖子、百科、聚合摘要或工具代码证明定理。使用$1$已足以完成当前任务，无需为追求更小常数扩大检索。

## 本地方法上下文

- [原弱均值证明](../aris-replication-20261009/WEAK_MEAN_PROOF_PACKAGE.md)：实际阅读全文，保留其$\theta$、独立AB/BA模型、W2反例与W3边界。
- [下一阶段协议](../aris-replication-20261009/NEXT_VALIDATION_PROTOCOL.md)：核对登记单位、完整耗时对象、4—20入口边界及`NOT_READY_TO_RUN`状态。没有修改协议，也没有把理论补充回填为真实实验签收。

本次工作仅为数学与来源核查，没有执行数值模拟、精确符号枚举、编译、SSH或新的现实实验。
