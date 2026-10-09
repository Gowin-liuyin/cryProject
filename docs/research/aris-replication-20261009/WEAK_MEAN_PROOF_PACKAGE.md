# 成对随机设计中平均时间差的推断依据

日期：2026-10-10。连接[下一阶段协议](NEXT_VALIDATION_PROTOCOL.md)的弱均值与区间缺口；不修改旧P1—P6或旧数据。以下是经典设计型推断在本项目对象上的自足推导，不主张新统计方法，也不是已执行的实验。

## 原主张与证明状态

原目标是对协议中登记单位的平均完整调用时间差$\theta$作差异或实质等价判断，不把它替换为尖锐零假设、截断时间或真实密文总体。

| 命题 | 状态 | 得到的保证 |
|---|---|---|
| W1 均值与方差恒等式 | PROVABLE AS STATED | 在下面的实际随机设计模型内有限样本成立 |
| W2 用常规标准误获得有限样本覆盖 | NOT CURRENTLY JUSTIFIED | 明确反例；方差估计期望偏大仍不足 |
| W3 不同质单位的正态区间 | PROVABLE AFTER WEAKENING / EXTRA ASSUMPTION | 无主导单位条件下仅渐近保守 |
| W4 事前确定幅度界区间 | PROVABLE AFTER WEAKENING / EXTRA ASSUMPTION | 有真实反事实上界时有限样本覆盖 |
| 当前真实运行可据此签收R04 | NOT CURRENTLY JUSTIFIED | 无干扰、反事实上界或渐近资格及用例门槛尚未成立 |

## 假设

1. $U\ge2$个匹配单位、每单位两个时段、每时段$J$次正常调用及等权目标在确认前固定。所有计划单位均记录；不依结果停止、换单位或删除长尾。缺失、失败或超时不能填零或删后应用本证明。
2. $Y_{jr}(A),Y_{jr}(B)$是单位$j\in\{1,\ldots,U\}$、时段$r\in\{1,2\}$在良性条件A/B下的有限完整调用均值，单位ns。固定这些潜在结果后，以赋值作为本节唯一随机性。可以条件于独立于赋值的外生背景轨迹；赋值相关的热状态、携带或跨单位干扰不能借此消除。
3. 每单位独立等概率选择AB或BA，且选择独立于潜在结果；观测均值等于实际分配条件对应的潜在均值。每个时段结果只依赖本时段条件，不依赖其他时段或单位的赋值。匹配、环境、处理和记录规则不得随已看到的结果改变。
4. 所有单位采用同一个预定测量对象。每时段内部调用可以相依；本节不把$2UJ$次调用当作独立样本，不要求各单位同分布或严格平稳。物理运行是否满足第2—3条，仍须独立论证。

## 记号

定义两个可能的A减B对差、对平均效应和方向扰动：

$$D_j^+=Y_{j1}(A)-Y_{j2}(B),\qquad
D_j^-=Y_{j2}(A)-Y_{j1}(B),$$
$$\theta_j=\frac{D_j^++D_j^-}{2}
=\frac{Y_{j1}(A)-Y_{j1}(B)+Y_{j2}(A)-Y_{j2}(B)}2,
\qquad \gamma_j=\frac{D_j^+-D_j^-}{2}.$$

AB取$R_j=+1$，BA取$R_j=-1$。按条件而非时间顺序计算观测对差，故

$$D_j=\theta_j+R_j\gamma_j,\qquad
\theta=\frac1U\sum_j\theta_j,\qquad
\widehat\theta=\overline D=\frac1U\sum_jD_j.$$

这是协议原先的两个时段潜在差等权平均，保持原目标。令

$$a_j=\theta_j-\theta,\quad
G=\sum_j\gamma_j^2,\quad H=\sum_ja_j^2,\quad Q=G+H,$$
$$W=\sum_jR_j\gamma_j,\quad K=\sum_ja_jR_j\gamma_j,\quad
\widehat V=\frac{\sum_j(D_j-\overline D)^2}{U(U-1)}.$$

$\theta,\gamma_j,\widehat\theta$的单位为ns，$G,H,Q,\widehat V$为ns平方。每对只观测$D_j^+$或$D_j^-$之一；潜在量的定义不意味着能够从一次运行识别它们。

## 证明策略与依赖图

W1依赖独立赋值的前两阶矩和中心化平方和恒等式。W2直接构造满足同一随机设计的全正潜在耗时。W3先证明标准误的一致上界，再用独立Rademacher三角阵列中心极限定理和Slutsky定理。W4用$\cosh$的矩母函数界及Chernoff界，不用正态近似。差异和等价的错误控制只依赖相应区间覆盖与事前固定的判断规则。

## W1：无偏均值与期望保守方差

**步骤1。** $E(R_j)=0$、$E(R_j^2)=1$，不同单位赋值独立。因此$E(W)=E(K)=0$、$E(W^2)=G$，得到

$$E(\widehat\theta)=\theta,\qquad
\operatorname{Var}(\widehat\theta)=\frac G{U^2}.$$

**步骤2。** $\sum_ja_j=0$且$\widehat\theta-\theta=W/U$。展开中心化平方和：

$$\sum_j(D_j-\overline D)^2
=\sum_j(a_j+R_j\gamma_j)^2-U(\overline D-\theta)^2
=Q+2K-\frac{W^2}{U}.$$

**步骤3。** 对上式取期望并除以$U(U-1)$：

$$E(\widehat V)=\frac{H+(1-1/U)G}{U(U-1)}
=\frac G{U^2}+\frac H{U(U-1)}
\ge\operatorname{Var}(\widehat\theta).\quad\square$$

与[Imai 2008，第3.2节式6—9、命题1及附录A.1](https://imai.fas.harvard.edu/research/files/matched-pair.pdf)的设计型结果对应。这里的保守性在期望意义上，既不是每次$\widehat V$都大于真实方差，也不是有限样本置信区间覆盖定理。异质项$H$来自登记对的效应差异，不能未经依据令其为零。

## W2：独立赋值仍不能保证小样本区间或弱零假设翻转检验

**步骤1，构造。** 任取$U\ge2$和$c>0$，令

$$\theta_1=(U-1)c,\quad \theta_j=-c\ (j\ge2),\qquad
\gamma_1=Uc,\quad\gamma_j=0\ (j\ge2).$$

真实目标$\theta=0$。取固定正基线$L=2c$，定义

$$Y_{j1}(B)=L+\gamma_j,\quad Y_{j2}(B)=L,\qquad
Y_{jr}(A)=Y_{jr}(B)+\theta_j.$$

所有潜在耗时严格为正，且同一对的两个时段具有相同A减B效应。代入定义恰得上述$\theta_j,\gamma_j$。赋值依然是各对独立抛币，无共同符号或跨对干扰。

**步骤2，区间失败。** 以概率$1/2$出现$R_1=-1$，其余符号不影响结果，此时全部$D_j=-c$，故$\widehat\theta=-c$、$\widehat V=0$。任何以有限临界值$q>0$构造的常规区间$[\widehat\theta-q\sqrt{\widehat V},\widehat\theta+q\sqrt{\widehat V}]$都漏掉0。另一半赋值得$\widehat\theta=c$、$\widehat V=4c^2$。所以覆盖至多$1/2$，与W1的期望保守性不矛盾。

**步骤3，正方差版本。** 将$\theta_j$加上$\varepsilon h_j$，其中$h=(1,-1,0,\ldots,0)$、$\varepsilon>0$，保持$\gamma_j$不变。目标仍为0。在$R_1=-1$分支，

$$\widehat\theta=-c,\qquad
\widehat V=\frac{2\varepsilon^2}{U(U-1)}>0.$$

对任何给定有限$q$，选足够小的$\varepsilon<c$使$q\varepsilon\sqrt{2/[U(U-1)]}<c$，区间仍漏掉0；潜在耗时仍为正。仅拦截观测零方差不能修复一般有限样本覆盖。

**步骤4，现有翻转统计量的边界。** 回到未扰动构造。在坏的半数赋值中，所有观测差为$-c$。对绝对和值、完整独立符号空间及含等值尾，只有全同号两种标签达到最大值$Uc$，所以$p=2^{1-U}$。当$U\ge8$时$p\le0.01$；实际弱零假设$\theta=0$却至少有一半赋值被拒绝。这没有违反旧P1：尖锐零假设不成立，观测差在真实赋值下不是对已观测差进行所有符号翻转的分布。它不同于旧P2的共同符号反例，明确说明真实独立AB/BA也不足以把尖锐零假设保证改称均值保证。此为抽象数学构造，不是真实密码类别的错误率实验。$\square$

## W3：无需同分布的渐近保守区间

**附加条件。** 考虑$U\to\infty$的一系列预先固定潜在结果，每一行均满足前述随机设计；下标$U$在记号中省略。最终$G>0$，并要求

$$\eta_U=\frac{\max_j\gamma_j^2}{G}\longrightarrow0.$$

这是任何一个登记对不支配全部赋值方差的充分条件，涉及未观测反事实；不能用一次数据的最大差或低自相关直接认证。

**步骤1，标准误的上界一致性。** 独立符号给出

$$E(K^2)=\sum_ja_j^2\gamma_j^2
\le(\max_j\gamma_j^2)H,$$
$$\frac{E(K^2)}{Q^2}\le\eta_U\frac{GH}{(G+H)^2}\le\frac{\eta_U}{4}\to0.$$

最后一个不等式由$(G-H)^2\ge0$得到。Chebyshev界使$K/Q\to_p0$。同时$W^2/(UQ)\ge0$且其期望$G/(UQ)\le1/U$；Markov界使该项也趋于0。将W1的精确分解乘以$U^2/Q$，得到

$$\frac{U^2\widehat V}{Q}
=\frac U{U-1}\left(1+\frac{2K}{Q}-\frac{W^2}{UQ}\right)
\longrightarrow_p1.$$

它相对一致估计的是$Q/U^2$这个渐近上界，一般不是实际方差$G/U^2$的相对一致估计；若再有$H/G\to0$，才得到两者的比值趋于1。

**步骤2，均值中心极限定理。** $R_j\gamma_j/\sqrt G$独立、均值为0，总方差为1。对任意固定$\epsilon>0$，$\eta_U\to0$使所有项的绝对值最终都小于$\epsilon$；因此Lindeberg截尾二阶矩和最终为0。Lindeberg–Feller三角阵列中心极限定理适用，故$W/\sqrt G\Rightarrow N(0,1)$。这里没有把单位假定成同分布。

**步骤3，覆盖下界。** 固定$0<\alpha<1$，令$z=\Phi^{-1}(1-\alpha/2)>0$。区间为

$$I_U=[\widehat\theta-z\sqrt{\widehat V},\widehat\theta+z\sqrt{\widehat V}].$$

因为$Q\ge G$且$U^2\widehat V/Q\to_p1$，对任意$0<\epsilon<1$，概率趋于1的事件上有$U\sqrt{\widehat V}/\sqrt G\ge\sqrt{1-\epsilon}$。因而

$$\liminf_{U\to\infty}\Pr\{\theta\in I_U\}
\ge2\Phi(z\sqrt{1-\epsilon})-1.$$

让$\epsilon\downarrow0$，得到覆盖下界$1-\alpha$。这不要求$G/Q$有极限；若额外$G/Q\to\rho\in[0,1]$，Slutsky定理给出学生化极限$N(0,\rho)$，$\rho=0$指零点退化分布。分母为零的事件概率趋于0，不影响极限，但有限样本遇到零标准误不能据此宣称等价。$\square$

**范围。** 没有推出任意给定$U$的覆盖率或误差界，尤其不能宣布现有4—20单位入口已经合格。换成$t$临界值本身不会提供有限样本保证。若所需$U$或分析对象超出现有合同，应另审实现，不拆多个20对检验拼确认。

## W4：有事前真实幅度界时的有限样本区间

**附加条件。** 确认前已知确定数$b_j\ge|\gamma_j|$，且它们覆盖全部潜在赋值结果；不是从当前观测最大值估计。令$B=\sum_jb_j^2$。

**步骤1，矩母函数。** 对实数$t$，由独立赋值，

$$E(e^{tW})=\prod_j\cosh(t\gamma_j)
\le\exp(t^2G/2)\le\exp(t^2B/2).$$

$\log\cosh x\le x^2/2$可由$x\ge0$时$\tanh x\le x$积分得到，负$x$由偶性处理。

**步骤2，双尾界。** 若$B>0$，对任意$r>0$用Markov界及$t=Ur/B$，单尾概率至多$\exp[-U^2r^2/(2B)]$；对$-W$用同一界并合并双尾，得到

$$\Pr(|\widehat\theta-\theta|>r)\le2\exp[-U^2r^2/(2B)].$$

故

$$I_B=\left[\widehat\theta-\frac{\sqrt{2B\log(2/\alpha)}}U,
\widehat\theta+\frac{\sqrt{2B\log(2/\alpha)}}U\right]$$

对有限$U$具有至少$1-\alpha$覆盖。若已知$B=0$，全部$\gamma_j=0$，估计误差恒为0，单点区间有效；这不同于仅观测到$\widehat V=0$。$\square$

这是[Hoeffding 1963有界和浓缩思想](https://doi.org/10.1080/01621459.1963.10500830)的本设计特化。实际系统调度可能有长尾；观测最大值、解析器上限、失败退出或超时阈值都不证明由全部潜在完整耗时决定的$|\gamma_j|\le b_j$。把耗时截断会改变原估计对象，本页没有这样做。当前没有可信$b_j$，故不能把此公式作为已就绪的执行方法。

## 差异、等价与需要纠正的推论

对具有相应覆盖保证的预定区间，排除0可支持限定的非零均值判断。若用例事前确定等价界$\Delta>0$，仅在整个区间位于$[-\Delta,+\Delta]$内时判等价：当真实$|\theta|>\Delta$时，误判等价必使区间漏掉$\theta$，所以错误概率受同一非覆盖界控制。严格边界是否纳入零假设及区间端点规则须在研究卡固定；检验$|\theta|\ge\Delta$时采用严格区间内含。W3只给渐近控制，W4在其界有效时给有限控制；多个正式判断仍须预分家族误差。

[Wu与Ding正式论文](https://doi.org/10.1080/01621459.2020.1750415)提供尖锐与弱零假设、学生化和渐近控制的相关理论。但本轮实际读取的[作者预印本v5第5.1节](https://arxiv.org/html/1809.07419v5#S5.SS1)明确把分层结果限定为固定层数、层内样本增大，并说明未覆盖大量小层。不能直接把那条分层定理当作本项目每层两时段的证明；W3使用上面的独立符号推导，不依赖该不适用扩展。

阅读深度如实限定：Imai核查第3.2节、命题1及附录A.1；Wu与Ding核查摘要和第5.1节适用范围；Hoeffding核查正式书目信息并自行推导此处矩母函数特化。[增补BibTeX](weak-mean-references.bib)不改旧书目身份。不称三篇全文精读，不将本项目自足构造称为文献首创。

## 尚未解决的风险与执行门

本补充关闭“只有尖锐检验、尚无任何均值区间理论路线”的方法缺口，保留原均值目标。它不证明当前真实运行的潜在结果固定、无携带/干扰、无主导单位或确定幅度界，也不提供用例容许差异、真实零效应/备择标签、功效预算或受控频率数据。小样本渐近误差未被量化；未知反事实不能由资格软件自动填齐。

因此[下一阶段协议](NEXT_VALIDATION_PROTOCOL.md)仍为NOT_READY_TO_RUN，R02/R04仍部分签收。未来确认前须明确选择W3或W4及其适用依据，另审实际分析实现和单位数；不能把这个证明文件回填成历史数据已经通过，不能升级为恒时证明、真实类别误报/检出或安全漏洞结论。
