# Proof Package：原学生化弱均值区间的有限样本下界

日期：2026-10-10。独立补充[原弱均值证明](../aris-replication-20261009/WEAK_MEAN_PROOF_PACKAGE.md)的W3；不修改该证明、[下一阶段协议](../aris-replication-20261009/NEXT_VALIDATION_PROTOCOL.md)、历史数据或已封存报告。本页是抽象随机设计的数学推导，没有执行实验、枚举或真实运行资格认证。不主张新统计方法。

## Claim

保持原来的登记单位平均效应$\theta$和通常学生化闭区间

$$
I=[\widehat\theta-z\sqrt{\widehat V},\ \widehat\theta+z\sqrt{\widehat V}],\qquad z>0.
$$

在下述独立Rademacher设计中，若$G>0$，令$h=H/G$、$\eta=\max_j\gamma_j^2/G$，对每个确定的$0<\epsilon<1$定义

$$
a_\epsilon=z\sqrt{\frac{U(1-\epsilon)(1+h)}{U-1+z^2}},
$$

$$
p_K(\epsilon,\eta,h)=
\begin{cases}
0,&h=0,\\[2pt]
\min\left\{1,\ \dfrac{4\eta h}{\epsilon^2(1+h)^2},
\exp\!\left[-\dfrac{\epsilon^2(1+h)^2}{8\eta h}\right]\right\},&h>0.
\end{cases}
$$

则有显式有限样本覆盖下界

$$
\boxed{\Pr\{\theta\in I\}\ \ge
\left[2\Phi(a_\epsilon)-1-2C_{\mathrm{BE}}\sqrt\eta
-p_K(\epsilon,\eta,h)\right]_+.}\tag{F1}
$$

其中$[x]_+=\max\{x,0\}$，$\Phi$是标准正态分布函数，本文件固定使用已核实原文所允许的保守数值$C_{\mathrm{BE}}=1$。若使用真实的$\beta=\sum_j|\gamma_j|^3/G^{3/2}$，式(F1)中的$\sqrt\eta$可以替换为$\beta$；两者都涉及潜在反事实。

不需要知道或假定$h=0$，还有对所有$h\ge0$同时有效的较弱界：

$$
a_\epsilon^{(0)}=z\sqrt{\frac{U(1-\epsilon)}{U-1+z^2}},\qquad
p_0(\epsilon,\eta)=\min\left\{1,\frac\eta{\epsilon^2},
\exp\!\left[-\frac{\epsilon^2}{2\eta}\right]\right\},
$$

$$
\boxed{\Pr\{\theta\in I\}\ \ge
\left[2\Phi(a_\epsilon^{(0)})-1-2\sqrt\eta-p_0(\epsilon,\eta)\right]_+.}\tag{F2}
$$

区间$I$没有换成使用已知$G$的oracle区间；$G,H,\eta$只用于描述这个既定区间的覆盖保证。界等于零时，仅得到零这个无信息下界。

## Status

| 主张 | 状态 | 本页实际得到的结论 |
|---|---|---|
| 给定下述设计与固定潜在数组，式(F1)—(F2)有限样本成立 | PROVABLE AS STATED | 下文完整证明；允许结论无信息 |
| 用事前可信的$\eta\le\eta_0$评价既定区间 | PROVABLE AFTER WEAKENING / EXTRA ASSUMPTION | 在式(F2)中代入确定上界$\eta_0$；仍须检查数值是否有用 |
| 任意$U$下通常正态区间都有名义覆盖 | NOT CURRENTLY JUSTIFIED | 原W2反例仍成立；这里没有修复成任意小样本的名义保证 |
| 当前真实运行已满足设计及$\eta$资格，可据此签收R04 | NOT CURRENTLY JUSTIFIED | 未观测反事实、携带/干扰、目标量级与现实执行条件仍未认证 |

## Assumptions

1. $U\ge2$在看到结果前固定。固定有限实数潜在数组$\theta_j,\gamma_j$，$j=1,\ldots,U$。它们沿用原证明从每对两个时段潜在完整调用均值定义的对象；没有删尾、截断、依结果停样或重分组。
2. $R_1,\ldots,R_U$相互独立，$\Pr(R_j=1)=\Pr(R_j=-1)=1/2$，且独立于潜在数组。观测满足$D_j=\theta_j+R_j\gamma_j$。概率仅对该真实赋值分布计算。
3. 原设计中的一致性、无赋值相关携带及跨单位干扰等条件，必须足以使第1—2条确实成立。它们不是本页概率不等式能够验证的物理事实。
4. $z>0$确定，区间为上面给定的闭区间，包含端点。即使$\widehat V=0$也使用区间定义；本证明不将零分母学生化比值强行定义成有限数。

不要求各单位同分布，不要求每时段内部的调用独立，也不把块内调用数当作$U$。本页不对现实噪声另加有界耗时假设。

## Notation

$$
\theta=\frac1U\sum_j\theta_j,\quad
\widehat\theta=\overline D=\frac1U\sum_jD_j,\quad
b_j=\theta_j-\theta,\quad \sum_jb_j=0,
$$

$$
G=\sum_j\gamma_j^2,\quad H=\sum_jb_j^2,\quad Q=G+H,
\quad W=\sum_jR_j\gamma_j,\quad K=\sum_jb_jR_j\gamma_j,
$$

$$
\widehat V=\frac{\sum_j(D_j-\overline D)^2}{U(U-1)}.
$$

这里用$b_j$表示原证明的$a_j$，仅避免与正态阈值$a_\epsilon$混淆，不改变定义。$\theta_j,\gamma_j,b_j,W,\widehat\theta$与原对象同为时间单位；$G,H,Q,K,\widehat V$为时间单位平方。$h,\eta,\beta,\epsilon,z,a_\epsilon$均无量纲。

当$G>0$时，$1/U\le\eta\le1$。每对只观测两种潜在差之一，故$\gamma_j$、$G$、$H$、$h$、$\eta$一般不能由一次实际赋值识别。

## Proof Strategy

先使用原方差分解，再将覆盖事件中的$W^2/U$精确移项。只需控制$K$的负偏离，不必再为$W^2$单独支付Markov尾界。对$W/\sqrt G$应用独立非同分布Berry–Esseen界，最后通过事件包含与并集界结合。这样直接控制原学生化区间，而不是先证明另一个已知方差区间有效再替换对象。

## Dependency Map

1. 有限方差分解和覆盖事件恒等式：只依赖设计代数、$U\ge2$及$\widehat V\ge0$。
2. $K$坏事件的Chebyshev界：依赖独立符号的二阶矩。
3. $K$坏事件的指数界：自足证明$\cosh x\le e^{x^2/2}$，再用独立性及Markov界。
4. $W$中央闭区间概率：独立非同分布Berry–Esseen定理、有限三阶绝对矩以及正态CDF连续性。[原文版本及阅读范围](REFERENCES.md)单列；没有使用只适用于iid的常数。
5. 式(F1)：中央事件与$K$好事件的包含关系、并集界；不假定两事件独立。
6. 式(F2)：$(1+h)^2\ge4h$及$1+h\ge1$。

## Proof

### 步骤1：保留原分母并精确改写覆盖事件

因为$\widehat\theta-\theta=W/U$且$\sum_jb_j=0$，展开平方和得到原恒等式

$$
\widehat V=\frac{Q+2K-W^2/U}{U(U-1)}.\tag{F3}
$$

在原设计中，式(F3)的分子是非负的中心化平方和。区间包含目标等价于

$$
|W|\le Uz\sqrt{\widehat V}.
$$

两边非负，平方和移项均保持等价；得到

$$
\boxed{\{\theta\in I\}=
\{(U-1+z^2)W^2\le z^2U(Q+2K)\}.}\tag{F4}
$$

该恒等式也覆盖$\widehat V=0$：此时必须$W=0$才覆盖，等值仍被纳入。这里没有除以$\widehat V$。

对确定的$0<\epsilon<1$，令

$$
E_\epsilon=\{2K\ge-\epsilon Q\},\qquad
C_\epsilon=\{|W|/\sqrt G\le a_\epsilon\}.
$$

若$E_\epsilon$与$C_\epsilon$同时成立，则

$$
(U-1+z^2)W^2
\le z^2U(1-\epsilon)Q
\le z^2U(Q+2K).
$$

式(F4)给出$C_\epsilon\cap E_\epsilon\subseteq\{\theta\in I\}$。因此

$$
\Pr\{\theta\in I\}\ge\Pr(C_\epsilon)-\Pr(E_\epsilon^c).\tag{F5}
$$

$W$与$K$共享符号，通常相依；式(F5)使用事件包含和并集界，无需独立性。坏事件为严格的$K<-\epsilon Q/2$，好事件包含等值。

### 步骤2：负向方差扰动的有限尾界

独立且中心化的符号给出

$$
E(K)=0,\qquad E(K^2)=\sum_jb_j^2\gamma_j^2
\le(\max_j\gamma_j^2)H=\eta GH.\tag{F6}
$$

若$H=0$，所有$b_j=0$，因此$K=0$恒成立，$\Pr(E_\epsilon^c)=0$。

若$H>0$，对非负变量$K^2$用Markov界，得到Chebyshev形式

$$
\Pr(E_\epsilon^c)
=\Pr(K<-\epsilon Q/2)
\le\frac{4E(K^2)}{\epsilon^2Q^2}
\le\frac{4\eta h}{\epsilon^2(1+h)^2}.\tag{F7}
$$

另推导一个指数界。对$x\ge0$，$\tanh x\le x$，因为$x-\tanh x$在零点为零、导数为$\tanh^2x\ge0$。积分得到$\log\cosh x\le x^2/2$；负$x$由偶性得到同一不等式。因此对$t>0$，

$$
E(e^{-tK})=\prod_j\cosh(tb_j\gamma_j)
\le\exp\!\left(\frac{t^2}{2}\sum_jb_j^2\gamma_j^2\right)
\le\exp(t^2\eta GH/2).
$$

在$K<-\epsilon Q/2$上有$e^{-tK}>e^{t\epsilon Q/2}$。Markov界并取$t=\epsilon Q/(2\eta GH)>0$，得到

$$
\Pr(E_\epsilon^c)
\le\exp\!\left(-\frac{\epsilon^2Q^2}{8\eta GH}\right)
=\exp\!\left(-\frac{\epsilon^2(1+h)^2}{8\eta h}\right).\tag{F8}
$$

即使实际$E(K^2)=0$，使用正的上界$\eta GH$仍是有效但可能宽松的界。概率本身不超过1，合并式(F7)—(F8)即$\Pr(E_\epsilon^c)\le p_K(\epsilon,\eta,h)$。

### 步骤3：独立加权符号的正态近似与离散端点

令$X_j=R_j\gamma_j/\sqrt G$。它们独立，$E(X_j)=0$，总方差为1，三阶绝对矩之和为

$$
\beta=\sum_jE|X_j|^3
=\frac{\sum_j|\gamma_j|^3}{G^{3/2}}
\le\frac{(\max_j|\gamma_j|)\sum_j\gamma_j^2}{G^{3/2}}
=\sqrt\eta.\tag{F9}
$$

零权重项可直接删除；$G>0$使剩余和具有正方差。各$\gamma_j$可以不同，没有使用同分布条件。

[Tyurin，arXiv:0912.0726v1，式(1)及定理7](https://arxiv.org/pdf/0912.0726v1)对独立中心化、总方差为正且三阶绝对矩有限的和给出Berry–Esseen界；其非同分布常数上界$0.5606$允许本页保守取$C_{\mathrm{BE}}=1$。定义$F(x)=\Pr(W/\sqrt G\le x)$，便有

$$
\sup_{x\in\mathbb R}|F(x)-\Phi(x)|\le C_{\mathrm{BE}}\beta.\tag{F10}
$$

对任何$a\ge0$，闭中央区间的概率是$F(a)-F(-a-)$，其中$F(-a-)=\lim_{x\uparrow-a}F(x)$。式(F10)及$\Phi$连续给出

$$
F(a)\ge\Phi(a)-C_{\mathrm{BE}}\beta,\qquad
F(-a-)\le\Phi(-a)+C_{\mathrm{BE}}\beta.
$$

因此

$$
\Pr\{|W|/\sqrt G\le a\}
\ge2\Phi(a)-1-2C_{\mathrm{BE}}\beta.\tag{F11}
$$

使用左极限是为了保留$-a$与$a$上的Rademacher原子。不能未经说明把闭区间改成严格不等式，或在离散分布中写成$F(a)-F(-a)$后声称等值都已计入。

### 步骤4：得到原区间的有限覆盖下界

在式(F5)中代入$a=a_\epsilon$的式(F11)、式(F9)及$K$坏事件界，得到

$$
\Pr\{\theta\in I\}
\ge2\Phi(a_\epsilon)-1-2C_{\mathrm{BE}}\sqrt\eta-p_K(\epsilon,\eta,h).
$$

覆盖概率还非负，故得到式(F1)。该证明的被覆盖事件始终是原学生化区间$I$，其半宽仍为$z\sqrt{\widehat V}$。$\square$

### 步骤5：移除对$H/G$的具体数值依赖

对$h>0$，$(h-1)^2\ge0$给出$(1+h)^2\ge4h$。由此

$$
\frac{4\eta h}{\epsilon^2(1+h)^2}\le\frac\eta{\epsilon^2},\qquad
\exp\!\left[-\frac{\epsilon^2(1+h)^2}{8\eta h}\right]
\le\exp\!\left[-\frac{\epsilon^2}{2\eta}\right].
$$

并且$a_\epsilon\ge a_\epsilon^{(0)}$。$h=0$时坏事件概率为零，也不超过$p_0$。将这些界代入式(F1)，得到式(F2)。$\square$

若事前有确定的$\eta\le\eta_0\le1$，式(F2)可用$\eta_0$代入：被减去的$2\sqrt\eta$与$p_0$都随$\eta$不减，阈值$a_\epsilon^{(0)}$不含$\eta$。若仅有$h$的区间而非确值，不应直接把上端点代入式(F1)，因为$h/(1+h)^2$并非单调；使用式(F2)，或对可信范围取下确界。

## Boundary Cases

### $G=0$

全部$\gamma_j=0$，因此$W=K=0$、$\widehat\theta=\theta$，原区间以概率1包含目标。此时不定义$\eta$、$h$或$W/\sqrt G$，也不把它们填成零再套式(F1)。观察到$\widehat V=0$不能反推$G=0$；原W2已经给出$G>0$但观测标准误为零的情形。

### $H=0$而$G>0$

此时$K=0$恒成立，不必支付坏事件概率，并允许在步骤1直接取$\epsilon=0$。式(F4)给出更直接的精确事件

$$
\{\theta\in I\}
=\left\{|W|/\sqrt G\le z\sqrt{\frac U{U-1+z^2}}\right\}.
$$

因而

$$
\Pr\{\theta\in I\}\ge
\left[2\Phi\!\left(z\sqrt{\frac U{U-1+z^2}}\right)
-1-2\sqrt\eta\right]_+.\tag{F12}
$$

$H=0$是额外结构，不能由一次样本效应看起来一致而认证。若$z>1$，有限$U$的中央阈值小于$z$，该近似下界不能自行达到与$z$对应的名义覆盖。

### $\eta$未知或下界无信息

无主导单位并非“观测最大差较小”。即使实际AB/BA独立，$D_j$也没有同时揭示$\theta_j$和$\gamma_j$，现有逐次时间或资格检查不会自动识别$\eta$。若只能使用普遍事实$\eta\le1$，本页取$C_{\mathrm{BE}}=1$的BE下界为零。不能以$\eta\ge1/U$这个下界代替所需的上界，更不能默认真实$\eta=1/U$。

零下界表明这条推导不能认证所需覆盖，不证明真实覆盖为零，也不证明其他理论不可能得到更好界。即使式(F1)给出正数，若低于事先要求的覆盖，仍不能签收。优化确定的$\epsilon$只改计算得到的保证，不改变$I$；不能把未知反事实当成调参输入。

## 与W3渐近路线及4—20单位实现的关系

### 定性极限没有改变

若原W3的$\eta_U\to0$成立，$1/U\le\eta_U$也使$U\to\infty$。在式(F2)中取$\epsilon_U=\eta_U^{1/3}$，则$\eta_U/\epsilon_U^2=\eta_U^{1/3}\to0$，$a_{\epsilon_U}^{(0)}\to z$，BE损失也趋于零。对固定$0<\alpha<1$及$z=\Phi^{-1}(1-\alpha/2)$，恢复

$$
\liminf_{U\to\infty}\Pr\{\theta\in I\}\ge1-\alpha.
$$

这是原对象的定量补充，没有要求$H/G\to0$。已知$h$有时能使式(F1)更有信息，但异质性项不能凭空删去。

### 一个有终点的均衡权重量级推演

仅作解析说明：若所有$|\gamma_j|$相同且非零，则$\eta=1/U$。这并不要求$H=0$，但它本身仍是现实中待论证的潜在数组结构。取

$$
\epsilon_U=\sqrt{\frac{2\log U}{U}}\in(0,1),\qquad U\ge2.
$$

其取值合法：$U-2\log U$在$U\ge2$上不减，且在$U=2$处为正。

式(F2)的指数坏事件界不超过$1/U$，故

$$
\Pr\{\theta\in I\}\ge
\left[2\Phi\!\left(z\sqrt{
\frac{U\left(1-\sqrt{2\log U/U}\right)}{U-1+z^2}}
\right)-1-\frac2{\sqrt U}-\frac1U\right]_+.\tag{F13}
$$

本页没有对式(F13)执行数值搜索或模拟。量级可以直接分析：令$k_z=\sqrt{2/\pi}\,z$、$c_z=\max\{z^2-1,0\}$。正态密度上界$1/\sqrt{2\pi}$及$1-\sqrt r\le1-r$（$0\le r\le1$）给出

$$
\big[2\Phi(z)-2\Phi(a_\epsilon^{(0)})\big]_+
\le k_z\left(\epsilon+\frac{c_z}U\right).
$$

当$z<1$时分母变化使$a_\epsilon^{(0)}$变大，仍可用同一界；当$a_\epsilon^{(0)}\ge z$时左侧为零。因此在均衡权重假设下，式(F13)还蕴含

$$
\Pr\{\theta\in I\}\ge
\left[1-\alpha-k_z\sqrt{\frac{2\log U}{U}}
-\frac{k_zc_z+1}U-\frac2{\sqrt U}\right]_+.\tag{F14}
$$

对固定$z$，这个充分界的覆盖损失是$O(\sqrt{\log U/U})$。把允许的“相对名义覆盖少至多$\delta$”在确认前固定，再使式(F14)中三个损失项之和不超过$\delta$，是一个明确的数学预算。取$U$为足够大常数乘$\delta^{-2}\log(1/\delta)$，代入有$\log U=2\log(1/\delta)+O(\log\log(1/\delta))$，故对充分小$\delta>0$可以满足该预算；充分规模为$U=O(\delta^{-2}\log(1/\delta))$。这里不是最优必要样本量或真实功效计算。

对现有4—20单位入口，甚至只看BE项就能确认本界无法支持接近常用名义水平的声明：所有中央概率至多1，且$\eta\ge1/U$，故本页BE形式的下界值至多$[1-2/\sqrt U]_+$。$U\le20$时该上限不超过$1-1/\sqrt5<0.56$；这说的是本页保证的上限，绝不是实际覆盖率小于0.56。若想靠该界认证至少$1-\alpha$，仅BE项给出的必要条件已是$U\ge4/\alpha^2$，例如$\alpha=0.05$时至少1600；其余损失使这一条件远非充分，且$H=0$时本页下界在有限$U$还低于名义值。

因此不能凭新公式宣布现有4—20入口合格，也不能把多个20对检验拼成大样本确认。只有在可信反事实资格和覆盖预算成立之后，才有理由另审单位数及实现。提高临界值会改变方法合同；本文件没有这样做。

## 建议的有限独立检查夹具（未执行）

下列仅建议给独立C检查器核对代数、事件包含及端点规则，不是统计模拟或实验结果。全部使用抽象无量纲实数，每个夹具至多16种完整独立符号；含$\gamma_j=0$的符号仍保留在赋值空间中。

| 夹具 | 固定参数 | 应核对的事实 |
|---|---|---|
| 均衡与等值端点 | $U=4$，全部$\theta_j=0$、$\gamma_j=1$；分别取$z=1,2$ | 式(F3)—(F4)逐赋值相等；两者覆盖均为$14/16$。$z=1$时$W=\pm2$恰好命中闭区间端点；误用严格区间会只剩$6/16$ |
| 原W2主导单位 | $U=4$，$(\theta_j)_{j=1}^4=(3,-1,-1,-1)$，$(\gamma_j)_{j=1}^4=(4,0,0,0)$，$z=2$ | 覆盖$8/16$；坏的一半$\widehat V=0$且$W\ne0$。$\eta=1$时本页下界为零，与反例相容 |
| 共享符号的$W,K$ | $U=4$，$(\theta_j)_{j=1}^4=(1,-1,1,-1)$，$(\gamma_j)_{j=1}^4=(1,1,2,0)$，$z=2$、$\epsilon=1/2$ | $G=6,H=4,Q=10$；逐赋值核对$E_\epsilon\cap C_\epsilon$包含于覆盖事件。此处$W$与$K$不能按独立事件相乘；不预报未经枚举的覆盖计数 |
| $G=0$ | $U=4$，$(\theta_j)_{j=1}^4=(1,-1,1,-1)$，全部$\gamma_j=0$，$z=1$ | 所有赋值均覆盖；$\widehat V=1/3$，不计算未定义的$h,\eta$ |

前两个计数可解析核对：均衡夹具的$W\in\{-4,-2,0,2,4\}$，$z=1,2$均仅排除全同号的2种赋值；严格$z=1$中央区间只留两正两负的$\binom42=6$种。主导单位夹具中，$R_1=-1$的8种赋值全部漏盖，$R_1=1$的8种赋值全部覆盖。

检查器宜用式(F4)的平方与有理数比较核对等值，避免浮点平方根把边界误判。夹具证明软件算式一致不证明现实潜在结果条件、BE常数的文献计算证书或真实运行覆盖。

## Corrections or Missing Assumptions

本页补上了原W3“有限误差没有量化”的一条显式理论路线，保留原目标和原区间。它没有证明有限样本名义覆盖，没有消除未观测反事实，也没有把期望保守方差升级成逐次保守方差。采用保守$C_{\mathrm{BE}}=1$源于可核实的非同分布原文；本页不借未核实的$0.56$减少误差预算。

## Open Risks

1. 当前现实运行仍缺独立于赋值的固定潜在数组、无携带/干扰与可信$\eta$上界；这些不是低自相关、随机次序或资格检查通过就能推出的。
2. 既有4—20单位方法没有被此下界认证。较大$U$、新的临界值、其他有限样本方法或新的数据对象都需单独审合同；本页不授权改变。
3. 可信$\eta$资格即使成立，也不提供用例等价界、最小关注差异、真实类别零/备择标签或检出功效。覆盖预算与功效预算不同。
4. 本页没有运行数值枚举、C测试、现实采集或SSH。原协议仍为`NOT_READY_TO_RUN`，R02/R04仍部分签收。

下一动作可以从“没有有限界可检查”改为“用一个明确且可能无信息的有限界检查方法预算，并独立核对代数夹具”；不能改为启动真实确认或签收总体错误率。该补充的完成终点是公式、完整证明、来源边界与夹具合同，不继续扩张成通用统计平台。
