# 文献综述：ML-KEM-768 解封装时序侧信道攻击与防御

> 调研范围：CRYSTALS-Kyber / ML-KEM（FIPS 203）实现安全性，重点是**解封装（decapsulation）时序侧信道**的攻击方式、可泄露信息、以及符合竞赛约束（禁止 sleep／随机延迟／空转／秘密输出／跳过 FO 重加密校验／固定拒绝密钥／未定义行为，必须保持密码语义与隐式拒绝）的防御方式。
> 配套材料：87 篇论文 PDF 已下载至 `workspace/literature/papers/`，检索记录（CSV）在 `workspace/literature/searches/`。文中方括号编号对应文末参考文献，标注了本地 PDF 路径。

---

## 1 引言：题目背景

### 1.1 ML-KEM 与 FIPS 203

2024 年 8 月，NIST 发布 FIPS 203《Module-Lattice-Based Key-Encapsulation Mechanism Standard》[1]，将 CRYSTALS-Kyber 算法 [2] 标准化为 ML-KEM。ML-KEM 基于模格（Module-LWE）困难问题，提供三个参数集：ML-KEM-512、**ML-KEM-768**（本项目目标参数集）、ML-KEM-1024。ML-KEM-768 的解封装失败概率为 2^-164.8 [1]，安全性约等价于 AES-192。PQC 实现侧信道攻防的全景综述可参见 Chowdhury 等 [10]、Delgado-Vargas 等 [11]、Olaluwe 等（聚焦深度学习辅助攻击）[12] 与 Ravi 等（聚焦格密码 Kyber/Dilithium）[13]。

### 1.2 Fujisaki-Okamoto 变换与隐式拒绝

ML-KEM 的 IND-CCA 安全性由 Fujisaki-Okamoto（FO）变换提供。FO 变换的现代模块化分析由 Hofheinz、Hövelmanns 与 Kiltz 给出 [3]，其将变换分解为 T/U 组件，并区分**显式拒绝**（输出 ⊥）与**隐式拒绝**（输出伪随机替代密钥）两种模式。FIPS 203 采用隐式拒绝变体；隐式拒绝在经典随机预言机模型 [3] 与量子随机预言机模型 [4,5] 下均有 IND-CCA 安全归约。

FIPS 203 算法 18（ML-KEM.Decaps_internal）的解封装流程 [1]：

1. 从解密密钥 dk 解析出 PKE 解密密钥 dk_PKE、PKE 加密密钥 ek_PKE、h = H(ek_PKE) 与隐式拒绝值 z；
2. m′ ← K-PKE.Decrypt(dk_PKE, c)；
3. (K′, r′) ← G(m′‖h)；
4. K̄ ← J(z‖c)（预计算的伪随机"替代密钥"）；
5. c′ ← K-PKE.Encrypt(ek_PKE, m′, r′)——**确定性重加密**；
6. 若 c ≠ c′，则 K′ ← K̄（隐式拒绝）；
7. 返回 K′。

解封装**永不输出失败符号**：密文无效时输出外观正常的伪随机密钥 J(z‖c)，通信双方后续的密钥确认必然失败，攻击者既无法复现该密钥也无法察觉拒绝发生——这是隐式拒绝的设计意图 [1,3]。

### 1.3 时序侧信道威胁模型与本题目的观测位置

本题目关注的是：攻击者通过**测量解封装的执行时间**（本地高精度计时，或远程网络时序统计）获得与秘密相关的信息。时序差异的来源可以是：秘密依赖的分支、秘密依赖的指令（除法、模约减、位移）、秘密依赖的内存访问（缓存命中/未命中）、乃至数据依赖功耗经 DVFS 反映的频率变化。本项目的计时覆盖**完整解封装**，输入生成与结果消费在计时窗口之外——这与文献中"端到端解封装时序"攻击的测量方式一致 [15,20]。

### 1.4 官方背景：NIST 对实现安全与时序防护的要求

经调研确认，截至 2026 年 10 月，NIST **没有**设立过专门面向"时序侧信道攻击/防御"的独立竞赛；该方向的活动嵌在以下官方机制中：

- **PQC 标准化进程本身把"抗侧信道攻击能力"列为算法评价准则**（NIST 官方状态报告，见 IR 8413 [7]、IR 8545 [8] 各轮次记录）。各轮次状态报告持续收录针对候选实现的真实攻击分析。
- **NIST SP 800-227《Recommendations for Key Encapsulation Mechanisms》草案**（2025 年 1 月发布，[9]）是时序防护要求首次进入 NIST KEM 推荐级文件的直接出处，其明确写道：*"This includes protecting against timing attacks with constant-time implementations"*，并要求 ML-KEM 实现通过 FIPS 140-3/CMVP 验证。
- **2025 年 2 月 NIST Workshop on Guidance for KEMs** 将"拒绝模式（显式/隐式）"列为正式议题，"KEM 实现的测试与验证"列入征稿主题。
- **功能验证体系**（CAVP/ACVP 已将 ML-KEM 纳入算法测试）验证正确性，但不认证恒时性；学术界事实标准的恒时性评估方法是 dudect 类统计检验 [90]。

### 1.5 竞赛约束对防御合法性的限定

本项目约束：缺陷变体只允许改变**有公开文献来源的目标时序机制**；禁止 sleep、随机延迟、空转、秘密输出、跳过重加密验证、固定拒绝密钥与未定义行为；必须保持密码语义与隐式拒绝。这一约束实质上把可行防御空间限定为：

- 消除秘密依赖时序（常数时间化）；
- 不改变密码语义的计算重组（乱序、分区、负载均衡、冗余表示）；
- 不改变拒绝语义的比较与选择恒定化（掩码比较、常数时间条件选择）。

把延迟插入、早退、检测中止、替换拒绝值等"掩盖式"手法排除在外——值得注意的是，文献恰好证明这些掩盖式手法既不合规也已被攻破（见 3.7 节）。

---

## 2 侧信道攻击方式与可泄露信息（问题一）

围绕 ML-KEM-768 解封装，文献中的攻击按信道可分为五大类。表 1 在 2.6 节汇总。

### 2.1 时序攻击（本题目的核心信道）

#### 2.1.1 FO 变换时序攻击：从拒绝路径到密钥恢复

**奠基工作**是 Guo、Johansson 与 Nilsson 针对 FrodoKEM 的密钥恢复时序攻击（PKC 2020）[14]。该文证明：FO 变换中消息编码（message-encoding）函数若存在数据依赖时序，攻击者可构造选择密文实现**明文检查预言机（PC oracle）**，通过时序测量判定重加密是否匹配，进而恢复 secret key 的 LWE 提示（hint），完成端到端密钥恢复。虽然目标为 FrodoKEM，但其攻击模型——"FO 重加密/比较步骤的数据依赖时序 → PC oracle → 格归约恢复长期密钥"——与 ML-KEM 解封装完全同构，是后续所有 FO 时序攻击的模板。

**直接针对 ML-KEM 的代表作是 KyberSlash**（Bernstein 等，eprint 2024/1049，TCHES 2025，CHES 2025 最佳论文）[15]。该文发现 Kyber 官方参考实现及多个主流库（pq-crystals、liboqs、wolfSSL 等）在解封装 FO 重加密路径的 `poly_tomsg`／`poly_compress` 中使用**除法指令**，而 x86 的 `div`/`divss` 指令执行时间依赖操作数。攻击者用端到端解封装时序构造选择密文预言机，恢复 FO 隐式拒绝机制内部的 message 比特，最终恢复 ML-KEM 共享密钥与长期密钥。该攻击同时适用于封装与解封装路径，且影响范围覆盖官方代码与多个部署库，是"非恒定时间算术击穿 ML-KEM"的最有力实证。

**同一手法在其他 NIST KEM 上的独立复现**进一步说明该机制类的普遍性：Schröder、Gast 与 Guo 的 "Divide and Surrender"（USENIX Security 2024）[17] 利用 HQC 采样中除法指令的可变时序，并提出 DIV-SMT 技术在 SMT 线程上实现高分辨率除法时序测量，构造高精度 PC oracle 快速恢复 HQC 密钥。

#### 2.1.2 拒绝采样与重加密时序

Guo、Hlauschek、Johansson 等的 "Don't Reject This"（TCHES 2022）[16] 针对 HQC 与 BIKE，证明 FO 隐式拒绝所依赖的**拒绝采样（定重编码）步骤即使在"恒定时间风格"的实现中仍泄露秘密相关时序**，可构造 PC oracle 恢复密钥。Hlauschek、Lahr 与 Schröder 的前驱分析（eprint 2021/1485）[18] 系统梳理了 FO 确定性重加密各阶段的时序泄露面，其"逐阶段定时审计"方法论可直接移植到 ML-KEM 解封装流水线。D'Anvers 等（CCS 2019）[21] 则证明纠错码解码步骤的执行时间泄露被纠错误码的重量信息——ML-KEM 虽不用纠错码，但"辅助解码子程序时序泄露"这一类攻击面在复合实现中有类比意义。

#### 2.1.3 编译器引入的时序泄露：常数时间代码不再恒定的实证

2024 年 6 月，Purnal 在 NIST pqc-forum 披露 [20]：Clang 15–18 在 `-Os`、`-O1`、`-O2/-O3 -fno-vectorize` 等选项下，会把 Kyber/ML-KEM 参考实现中 `poly_frommsg` 里形如 `(-((x>>j)&1))&y` 的常数时间掩码写法识别为位测试并生成**秘密依赖的条件分支**；其 PoC（clangover）在笔记本上用端到端解封装时序测量于 10 分钟内恢复 ML-KEM-512 密钥。这一事件与 KyberSlash 共同确立了本领域最重要的教训：**常数时间是机器码与微架构性质，不是 C 源代码性质**；源码级无分支不保证编译产物无分支，编译器优化可以"安静地撤销"实现者采取的措施 [15,20,52]。

#### 2.1.4 经典时序攻击方法论参照

Merget 等的 Raccoon 攻击（USENIX Security 2021）[23]（目标为 TLS-DH，非 Kyber）确立了"时序测量 → 逐比特 oracle → 格基密钥恢复"的完整流水线，与 FO 时序攻击的 oracle→lattice 恢复流程一致。Bos 等的差分计算分析 DCA（CHES 2016）[24] 属于白盒软件 DPA（利用中间值计算迹而非时间），作为软件灰盒/白盒模型的对照收录。An 等（SCIS 2017）[22] 更早对格密码软件库（含 Kyber 前身 NewHope 及 LWE 类方案）实施了时序与故障组合攻击，是 KyberSlash 一类"库级时序审计"攻击思路的先声。

#### 2.1.5 时序信道泄露的信息小结

时序攻击直接泄露的信息按价值分层：

1. **message 比特**（m′ 的 Compress/Decode 结果）：经 FO 与 secret key 绑定，是最常见的中间泄露目标 [14,15,16,17]；
2. **比较/拒绝标志**（c = c′ 与否）：把隐式拒绝校验门变成 oracle [14,20]；
3. **NTT/约减中间值的 Hamming 重量或符号信息**（经微架构信道）：单条观测即可致命的逐层泄露 [26,27,28]；
4. 聚合后恢复 **LWE 秘密 → 长期密钥** [14,15]，或直接恢复 **会话共享秘密** [16]。

### 2.2 微架构时序信道（缓存、调频、SMT、分支预测）

- **缓存时序**：Groot Bruinderink、Hülsing、Lange 与 Yarom 的 "Flush, Gauss, and Reload"（CHES 2016）[25] 是格密码上首个 Flush+Reload 缓存攻击（目标为 BLISS 高斯采样器），确立"观测秘密依赖代码的缓存命中→推断秘密分支"的范式。ML-KEM 解封装中的消息解码分支、查表、采样步骤面临同类风险。
- **DVFS/调频时序**：Yu 等的 "Hints from Hertz"（TCHES 2024）[26] 将 Hertzbleed 式攻击引入格密码：测量 CPU 动态调频变化推断 NTT 中间数据的 Hamming 重量，对 Kyber 与 NTTRU 提取 secret key 提示，估计造成至少 35% 的安全损失。其启示是：**指令级恒定时间不足以封死时序信道**——数据依赖功耗经频率调制成为可远程读取的时序信号。
- **SMT 端口争用**：DIV-SMT 技术利用同核 SMT 兄弟线程精确测量除法指令时延 [17]。
- **位移指令时序**：Qiu 与 Aysu 的 NTT-PEEL（TCHES 2026）[27] 发现 FALCON 的 NTT 原址模约减中**位移指令的数据依赖时序**可实施单条迹攻击恢复签名密钥；NTT 的移位/约减序列在 Kyber 逆向 NTT 中结构相同，提示解封装 NTT 的按位操作时序同属需检测的泄露机制。

**泄露信息**：秘密依赖的访存地址模式（缓存命中序列）、中间值 Hamming 重量（经调频/功耗代理）、指令时延特征；均可归结为 NTT 各层中间值或 message 比特，进而恢复密钥 [25,26,27]。

### 2.3 功耗与电磁分析（PA/EMA）

功耗/电磁是文献中最成熟的信道，对 ML-KEM 解封装的威胁模型评估有重要参照价值：

- **单条迹攻击奠基**：Primas、Pessl 与 Mangard（CHES 2017）[28] 首次对**掩码格密码**实施单条迹攻击——不解掩码，直接在掩码共享值（NTT 输出、消息编码）上做模板/聚类分析，从 Kyber 解密单条迹恢复明文多项式，再结合 FO 重加密区分恢复 secret key。Pessl 与 Primas（LATINCRYPT 2019）[29] 进一步改进模板匹配与原址区分技术，显著降低攻击对迹质量的要求。
- **实现级实证**：Ji 等（DATE 2023）[30] 对 FPGA 上 Kyber 实现做深度学习功耗分析，从解封装 NTT/多项式乘法恢复秘密系数；Kuo 与 Takayasu（ICISC 2023）[31] 用 CPA 从解密功耗迹恢复 message 部分信息后再以格攻击整体恢复 secret key，展示"部分消息泄漏+格归约"的高效利用路径；Rodriguez 等（DTIS 2023）[32] 的相关性电磁分析（CEMA）以非侵入、空间分辨方式泄露消息多项式系数。Mujdei 等（ACM TECS 2024）[33] 系统研究了 Kyber/Saber 多项式乘法中间值的功耗与 EM 泄露。
- **选择密文放大**：Xu 等（SAC 2021）[36] 用选择密文把目标系数的泄漏信噪比放大，大幅降低 profiled 攻击所需迹数；Ravi 等（TCHES 2020）[40] 给出针对 FO 变换 CCA 安全 PKE/KEM 的泛型 EM 辅助消息恢复攻击（含 Kyber-512）。Ravi 等（IEEE TIFS 2021）[41] 与 Sim 等（IEEE Access 2020）针对消息编码/解码步骤的泄露恢复 FO 内部 message。
- **对防护组合的突破**：Hamburg 等（TCHES 2021）[35] 的选择密文 k-迹攻击绕过掩码保护恢复 CCA2 安全 Kyber 的秘密；Backlund 等（CARDIS 2023）[37] 与 Jendral 等（2023）[38] 分别在掩码+打乱组合防护下实现秘密恢复与单条迹消息恢复；Wang 等（2023）[39] 攻破 bitsliced 高阶掩码实现；Dubrova 等的 copy-paste 攻击（AsiaCCS 2023）[69] 与 Ngo 等的结论（eprint 2022/919）[70] 进一步表明高阶掩码单独使用并不足以阻止选择密文+单迹组合攻击。

**泄露信息**：NTT 蝶形输入输出、消息编码系数、乘法部分积等数据依赖中间值 → 恢复 m 的部分/全部系数 → 经 FO 校验门或格归约恢复 secret key。隐式拒绝只保证密码学语义，不防护物理泄漏 [28,35,40]。

### 2.4 故障注入攻击（FI）

故障注入把解封装的 FO 校验门变成解密 oracle：

- Hermelink、Pessl 与 Pöppelmann（2021）[42] 的 fault-enabled chosen-ciphertext 攻击：篡改密文使其解密出错误消息，再用故障在 FO 重加密时"纠正"密文使比较通过，从而利用校验门逐块恢复 Kyber secret key——ML-KEM 解封装故障攻击的代表作。
- Xagawa 等（2021）[43] 系统分析了对 Kyber、NTRU 等第三轮 KEM 候选的故障注入（含 FO 重加密跳过/比较跳过），给出密钥恢复条件。
- Pessl 与 Prokop（TCHES 2021）[44] 归纳了 CCA 安全格 KEM 的故障攻击面（解密、重加密、比较、隐式拒绝各阶段）并评估不同故障模型的可行性。
- Ravi 等（TCHES 2023）[45] 针对 NTT twiddle 常数的故障传播攻击。
- 理论对照：Hövelmanns 等（TCC 2025）[19] 从可证明安全角度界定 FO 重加密在故障/泄露模型下的安全性边界。

**泄露/效果**：比较结果被翻转、重加密被跳过或篡改，使无效密文"验证通过"→ FO 校验门成为解密 oracle → 恢复 secret key [42,44]。故障攻击虽非时序信道，但它揭示的攻击面（重加密校验）与时序攻击共享同一个 FO 结构弱点，防御设计必须同时考虑。更早地，D'Anvers 等（PQCrypto 2019）[6] 形式化了针对 FO 变换格 KEM 的解密失败攻击框架——这同时解释了 ML-KEM 极低解封装失败率参数（ML-KEM-768 为 2^-164.8 [1]）的选取动机：失败率越低，FO 归约损失越小，失败类攻击越不可行。

### 2.5 协议层 key mismatch 攻击（密钥复用滥用）

当 KEM 密钥对被复用（违反 ML-KEM 的 ephemeral 假设）时，攻击者构造特殊密文使共享密钥的某比特成为 secret key 某系数的函数，通过观测"匹配/不匹配"oracle 逐位恢复 s：

- Qin 等（eprint 2021/123）[48] 给出 NIST 候选 KEM 上 key mismatch 攻击的系统化框架；
- Guo 与 Mårtensson（PQCrypto 2023）[49] 的多位置并行 mismatch 攻击把对 Kyber-768 的恢复查询数压至接近理论下界；
- Guo、Mårtensson 与 Åström（eprint 2024/810）[50] 量化"有限次密钥复用"下恢复 secret 所需查询数；
- Mi、Jiang 与 Zhang（ACNS 2022）[51] 将 mismatch 与格归约结合，用少量 oracle 查询构造 LWE 实例以 BKZ 恢复完整密钥。

**泄露信息**：密钥复用场景下的 secret key 系数（逐位/多块）。此类攻击不需要物理接触，划定了 ML-KEM 解封装在实际协议中的安全边界条件，也是评估隐式拒绝实现时 misuse 维度的参照。

### 2.6 攻击方式与泄露信息汇总

**表 1：针对 ML-KEM-768/Kyber 解封装（及其同构方案）的侧信道攻击分类汇总**

| 攻击类别 | 代表工作 | 测量对象 | 直接泄露信息 | 最终恢复目标 | 与解封装的关系 |
|---|---|---|---|---|---|
| FO 时序攻击 | [14][15][16][17][18][21] | 端到端/函数级执行时间 | message 比特、比较/拒绝标志、拒绝采样重量 | 长期密钥（经 LWE hint + 格归约） | **最直接**：FO 重加密+比较即解封装核心步骤 |
| 编译器引入时序 | [20] | 端到端解封装时间 | message 比特（PC oracle） | ML-KEM-512 密钥（10 分钟级） | `poly_frommsg` 在封装与解封装均被调用 |
| 缓存时序 | [25] | 缓存命中/未命中序列 | 秘密分支、秘密索引的访存模式 | 采样器/解码状态 → 密钥 | 解码分支、查表、采样步骤同面临 |
| DVFS/调频时序 | [26] | 频率变化 | NTT 中间值 Hamming 重量 | secret key hints（≥35% 安全损失） | NTT 是解封装核心运算 |
| 位移指令时序 | [27] | 单条指令时延 | NTT 约减移位位数 | 签名密钥（同构提示） | 逆向 NTT 移位序列结构相同 |
| 功耗/电磁 | [28][29][30][31][32][33][35][36][37][38][39][40][41] | 功耗/EM 迹 | NTT 中间值、m 系数、掩码共享值 | m → 经 FO 门或格归约 → secret key | 解封装全流水线各单元均可被逐层剥离 |
| 故障注入 | [42][43][44][45] | 错误计算结果 | 比较翻转、重加密跳过 | secret key（校验门 oracle） | 攻击面=FO 校验门，与时序攻击共享结构弱点 |
| key mismatch | [48][49][50][51] | 共享密钥匹配性 | secret 系数（复用场景） | 完整 secret key | 划定 misuse 边界条件 |

---

## 3 防御方式及其对题目约束的符合性（问题二）

### 3.1 常数时间实现（基线防御，完全合规）

**原理**：消除秘密依赖的控制流与存储访问——无分支选择（用掩码+算术或 cmov）、固定索引、完整展开的 NTT、无早退循环、安全的模约减 [52,53]。Brumley 的《SoK: The Constant-Time Model》（2026）[52] 系统梳理了常数时间的操作语义定义，是从 Kocher/Bernstein 一脉到当代的形式化框架；Bernstein 的 cryptoint 库 [53] 给出可验证的常数时间整数运算原语（含对抗编译器窥孔优化的 optblocker 技术，直接回应 [20] 暴露的问题）。

**ML-KEM 特定工作**：

- **常数时间 NTT 与 twiddle 因子处理**：Liang 等（2026）[54] 直接针对 ML-KEM 的常数时间 NTT，给出半表/全表 twiddle 因子的统一成本模型，评估存储-时间权衡下的无分支重建逻辑。
- **安全约减**：Huang 等（2022）[55] 的 Plantard 算术以新的模乘约减替代 Montgomery/Barrett，无需预计算常数、输入范围更宽，软件实现指令更少且天然避免边界分支。
- **多项式乘法的结构分解**：Chung 等（TCHES 2021）[56] 把 NTT-unfriendly 环上的乘法分解为多个小 NTT（Good 技巧、多模数）；Becker 等（WAIFI 2022）[57] 的整数 NTT 乘法窗口技术；Bermudo Mera 等（TCHES 2020）[58] 的 Toom-Cook 时间-存储权衡；Abdulrahman 等（ACNS 2022）[59] 的 Cortex-M4 高效常数时间实现基线。这些工作的原始动机是性能，但其"把秘密相关计算拆成形状固定、互相独立的单元"的结构特征，恰好使乱序与负载均衡可施行且天然常数时间 [56,57,58]。
- **汇编层保证**：Becker 与 Klein 的 SLOTHY（TCHES 2022）[60] 用约束求解生成"既快又（可论证）常数时间"的手写汇编调度，是编译器/汇编层防御的正面工程范例。

**符合性**：完全满足题目约束——不引入延迟、不改变密码语义、不跳过重加密。**局限**：KyberSlash 与 NTT-PEEL 表明编译器和微架构（除法、位移、向量化选择）可能重新引入泄漏 [15,20,27]，常数时间必须覆盖到指令级与机器码级 [52]。

### 3.2 FO 隐式拒绝的恒定时间化（核心防御方向，完全合规）

文献共识路线：**重加密照常完整执行（绝不跳过 FO 校验）**，比较与拒绝选择以恒定时间方式完成。

- FIPS 203 §6.3 明文规定：算法 18 第 9 步的比较标志是**秘密中间数据**，必须在解封装终止前销毁，不得以任何形式输出该标志 [1]——即比较结果不得经时序、错误码或任何侧信道泄露。
- Azouaoui 等（SAC 2021）[34] 系统量化了 Kyber 解密与 FO 重加密各步骤的泄露，明确"重加密比较"是选择密文攻击的关键泄漏点，支撑"接受/拒绝两路径必须执行相同指令序列（常数时间选择+隐式拒绝）"的设计。
- Almeida 等（CiC 2024）[61] 在 EasyCrypt 中给出首个 ML-KEM IND-CCA 安全性与正确性的机器验证证明，把"常数时间范式下的隐式拒绝"纳入形式化模型——为"防御不破坏 FO 安全归约"提供最高级别的可引用证据。
- Hövelmanns 与 Kudinov（PQCrypto 2025）[46] 系统比较显式/隐式拒绝：经典 ROM 中显式拒绝不弱于隐式拒绝；量子情形借助 eQROM。Hövelmanns 等（TCC 2025）[19] 界定 FO 重加密的正确实现条件（何种重加密语义能保持 IND-CCA），是防御改动的"语义保持性"判据来源。
- 警示面：Joux、Loss 与 Wagner（PKC 2025）[47] 指出隐式拒绝机制可被滥用为密钥渗出（kleptography）的载体——防御实现必须可审计、无隐藏行为。

**符合性**：完全满足——语义不变（仍为 FO+隐式拒绝，拒绝值仍为 J(z‖c)），只是消除比较与选择的时序差异。**这是与本题目约束契合度最高的防御方向**。

### 3.3 掩码（Masking，最强软件防御，合规但有代价）

**原理**：秘密拆成 d+1 个随机份额，所有运算在份额域进行，使单点泄漏只暴露份额 [62]。Bos 等（TCHES 2021）[62] 给出首个一阶与高阶掩码 Kyber 完整实现（解密、重加密、比较全部掩码化）；Heinz 等（2022）[63] 优化 Cortex-M4 一阶掩码实现；Fritzmann 等（TCHES 2021）[64] 设计掩码硬件加速器与指令集扩展。掩码的核心难点——Z_q 算术掩码与布尔掩码（比特压缩、密文比较）之间的安全转换——已由 Coron 等 [65,66]、Bronchain 与 Cassiers（bitslicing 转换）[67]、Aikata 等的 Kavach [68] 等解决。Kavach [68] 针对多项式算术的轻量掩码技术尤其适合资源受限场景。

**攻击进展与组合需求**：copy-paste 攻击 [69]、bitsliced 掩码实现被攻破 [39]、"高阶掩码不能阻止选择密文 k-迹攻击" [35,70]——掩码必须与 FO 结构联合分析，单独上掩码不等于安全。

**符合性**：满足约束——随机数用于份额拆分而非时延插入，密码语义与隐式拒绝完全保持。代价：约 2–10 倍性能开销与高质量随机源需求 [62,63]。

### 3.4 掩码密文比较（masked ciphertext comparison）

FO 重加密的密文比较是掩码化最难也最关键的环节：

- D'Anvers 等（ACNS 2021）[71] 把 FO 重加密的密文比较整体移到掩码域，高阶安全且不需要解掩码；其后续工作（IEEE TIFS 2022）[72] 进一步 bitslice 化并给出更适合 ARM 的算法变体；
- Bache 等（2020）[73] 给出多项式比较的高速度掩码实现；
- Bhasin 等（TCHES 2021）[74] 对掩码比较 gadget 做攻防评估，指出朴素实现的组合安全缺陷并给出修复——对防御评估方法论有直接价值。

**符合性**：满足约束——比较结果不再以明文布尔值泄漏，无延迟插入、语义不变。结合 3.2 节，"掩码比较+常数时间选择"构成隐式拒绝恒定化的高阶完备方案 [71,72]。

### 3.5 乱序（Shuffling，低成本补充，机制合规但不可单独依赖）

**原理**：随机化互相独立操作（同一 stage 内蝶形、系数处理顺序）的执行顺序，使攻击者的单迹对齐失效。防御侧工作：Chen、Ma 与 Jing（TCAD 2022）[75]、Ravi 等（COSADE 2020）[77] 对可配置 NTT 防御（乱序+掩码组合）的性能评估、Xu 等（TCAS-II 2025）[78] 的硬件友好乱序，以及面向 ML-KEM 的一阶掩码细粒度乱序组合实现 [83]。

**关键合规性辨析**：乱序只改变**无数据依赖操作**的执行顺序，随机的是执行顺序而非时延，不插入延迟、不改变计算结果——**机制本身完全符合"只改变目标时序机制、保持密码语义"的约束**；工程上必须保证乱序不跨越数据依赖（同 stage 蝶形互相独立才可乱序）。

**攻击侧结论**：Hermelink 等（TCHES 2023）[76] 用因子图+置信传播在**单条迹**内对齐被乱序的 NTT 并恢复秘密；Zhang 等（eprint 2025/1956）[79] 对 shuffled Kyber 的选择密文攻击。结论：纯乱序对高分辨率单迹攻击防护有限，必须与常数时间、掩码组合 [76,77,79]。

### 3.6 分区/窗口/预计算与负载均衡（NTT 结构层面，合规）

"把秘密相关计算拆成形状固定、互相独立的单元"的结构性思路：

- **分区**：Chung 等 [56] 的 Good 技巧多 NTT 分区、Ravi 等 [77] 的可配置 NTT 防御评估中均体现"固定形状子块"思想；
- **窗口法/预计算**：Becker 等 [57] 的窗口化整数-NTT 乘法、twiddle 因子的窗口/查表组织 [54]；
- **时间-存储权衡**：Bermudo Mera 等 [58] 的 Toom-Cook TMTO。

**说明**：调研中**未能验证**一篇标题或核心术语为"load-balanced partitioning of NTT"且署名 Becker/Hwang/Kannwischer/Yang 的论文——最接近的已验证工作是上述 [56][57][77]。涉及该类机制的写作应引用这三篇。

**符合性**：分区/窗口法本身常数时间、无秘密依赖控制，与题目约束兼容；其价值在于使乱序与负载均衡可施行。

### 3.7 反面教材：检测式与掩盖式防御为何不合规且无效

Ravi 等（TCHES 2024）[80] 攻破了"密文健全性检查（ciphertext sanity check）"与"解封装失败检查（decapsulation failure check）"两类**检测式**低成本防御：它们靠检测恶意密文后中止/丢弃来实现。这类手法：(a) 本质上改变了拒绝路径行为（中止/丢弃 ≠ 输出 J(z‖c)），不符合"保持密码语义与隐式拒绝"的题目要求；(b) 已被实际攻破 [80]。同理，sleep/随机延迟/空转只能降低信噪比，不提供可证明保护，且为题目明确禁止。文献给出的正面结论是：**唯一同时满足合规性与有效性的路线是消除秘密依赖时序本身**（3.1–3.4），而非掩盖或检测 [52,80]。

### 3.8 泄漏评估方法论

防御有效性需要统计证据链：

- **TVLA**（Test Vector Leakage Assessment）：Goodwill 等（2011）[84] 提出的固定 vs 随机 t 检验（阈值 |t| > 4.5）是所有泄漏评估的地基；Becker 等（ICMC 2013）[85] 给出实践要点；Schneider 与 Moradi（CHES 2015）[86] 给出评估流程路线图。
- **dudect**：Reparaz 等（DATE 2017）[90] 的 t 检验恒时性检测工具，是业界对 ML-KEM 实现做恒时验证的事实标准 [20]。
- **PQC 适用性**：Kamucheka 等 [89] 的 PQC 功耗侧信道分析实践；Saarinen（HOST 2022）[87] 讨论 ISO 17825 标准测试对 NIST PQC 算法的适用性——与本项目"统计验证/正式签收"流程直接对应。
- **仿真评估**：PROLEAD_SW（TCHES 2025）[88] 提供无需真实测量设备的软件实现物理攻击安全评估框架，可作离线评估环节的工具候选。

### 3.9 防御方式 × 题目约束符合性矩阵

**表 2：防御措施与竞赛约束符合性**

| 防御措施 | 改变语义/拒绝行为 | 引入延迟/随机时延 | 跳过 FO 校验 | 保持隐式拒绝 | 有公开文献来源 | 结论 |
|---|---|---|---|---|---|---|
| 常数时间实现 [52-60] | 否 | 否 | 否 | 是 | 是（大量） | **完全符合**（基线） |
| FO 比较/选择恒定化 [1,34,61] | 否 | 否 | 否 | 是（标志销毁） | 是 | **完全符合**（核心） |
| 掩码+掩码比较 [62-74] | 否 | 否（随机数用于份额） | 否 | 是 | 是 | 符合（高性能代价） |
| 乱序 NTT [75,77,78] | 否 | 否（顺序随机≠时延随机） | 否 | 是 | 是 | 符合（须组合使用） |
| 分区/窗口/预计算 [54,56,57,58] | 否 | 否 | 否 | 是 | 是 | 符合 |
| 冗余表示/负载随机化（RNR、RIC）[81,82] | 否 | 否 | 否 | 是 | 是 | 符合（新兴） |
| 检测式防御（健全性/失败检查）[80] | **是** | 否 | 变相 | 否（改变拒绝路径） | 是 | **不合规且已被攻破** |
| sleep/随机延迟/空转 | 否 | **是** | 否 | 是 | — | **题目明确禁止** |

---

## 4 与本题目的对应关系与研究空白

**对齐点**：

1. **威胁模型**：本项目"计时覆盖完整解封装"的测量方式与 KyberSlash、clangover 的端到端攻击设置一致 [15,20]；FO 重加密+比较是已验证的最高价值时序攻击面 [14,15,34]。
2. **防御路线**：题目约束（只改有文献来源的目标时序机制、保持语义与隐式拒绝）与文献共识路线（常数时间化 + FO 恒定化 [52,61]）精确重合；掩码比较 [71,72] 与乱序 [75,77] 是文献支撑的可选叠加层。
3. **评估方法**：dudect/TVLA 统计检验 [84,90] 与"分别报告功能正确、机制、原始数据、观察差异与正式统计确认"的证据分级流程直接对接。

**研究空白与机会**：

- **微架构残余泄露**：除法 [15]、位移 [27]、调频 [26]、编译器优化 [20] 表明"源代码级常数时间"不等于"机器码级恒定"；针对 ML-KEM-768 全解封装流水线的**指令级时序审计清单**仍不完整（如逆向 NTT 的移位序列、K-PKE 重加密各原语）。
- **FO 恒定化的低成本方案**：掩码比较开销较大 [71-73]，是否存在保持语义、无随机数需求、更低成本的恒定比较实现，是竞赛场景下的实际问题。
- **组合防御的系统评估**：文献多为单点防御+单点攻击 [76,79,80]，针对"常数时间+乱序"组合的端到端泄漏评估框架尚未标准化。
- **统计签收方法论**：如何由 TVLA/dudect 的"无检测到泄漏"过渡到竞赛要求的"正式统计确认"，需要明确样本量、效应量与检验功效的关系 [84,86,87]。

---

## 5 结论

围绕 ML-KEM-768 解封装时序侧信道，文献给出的图景清晰：**攻击侧**，FO 变换的重加密与比较步骤是最有价值的时序攻击面——从 FrodoKEM 的奠基性 FO 时序攻击 [14]、到直接击穿 ML-KEM 官方实现的 KyberSlash [15]、再到编译器引入分支的 clangover 事件 [20]，"秘密依赖的算术/控制流 → PC oracle → 格恢复长期密钥"的攻击链已被反复验证；微架构（缓存、调频、SMT）与物理（功耗/EM、故障）信道进一步放大了同一攻击面。**防御侧**，唯一同时满足本项目竞赛约束（无延迟插入、无语义改变、保持隐式拒绝、有文献来源）且被证实有效的路线是**消除秘密依赖时序本身**：常数时间实现为基线 [52-60]，FO 比较与拒绝选择的恒定化为核心 [1,34,61]，掩码与掩码比较 [62-74]、乱序 [75,77,78]、分区/窗口 [54,56,57] 为可叠加层；检测式与掩盖式手法既不合规也已被攻破 [80]。评估环节应以 TVLA/dudect 统计检验 [84,90] 提供可复核的证据链。本综述引用的 87 篇文献（其中约 70 篇已下载至本地 `workspace/literature/papers/`）为后续实验设计、防御选型与报告写作提供了完整的文献基础。

---

## 参考文献

**背景与标准**

[1] NIST. FIPS 203: Module-Lattice-Based Key-Encapsulation Mechanism Standard. 2024. 本地：`papers/fips203_ml_kem.pdf`
[2] J. Bos, L. Ducas, E. Kiltz, T. Lepoint, V. Lyubashevsky, J. M. Schanck, P. Schwabe, G. Seiler, D. Stehlé. CRYSTALS–Kyber: a CCA-secure module-lattice-based KEM. EuroS&P 2018. 本地：`papers/kyber_original_2018.pdf`
[3] D. Hofheinz, K. Hövelmanns, E. Kiltz. A Modular Analysis of the Fujisaki-Okamoto Transformation. TCC 2017. ePrint 2017/604. 本地：`papers/fo_modular_analysis_2017.pdf`
[4] H. Jiang, Z. Zhang, Z. Ma. IND-CCA-secure key encapsulation mechanism in the quantum random oracle model. ePrint 2017/1096. 本地：`papers/jiang_zhang_ma_qrom_kem_2017.pdf`
[5] H. Jiang, Z. Zhang, Z. Ma. Key encapsulation mechanism with explicit rejection in the quantum random oracle model. PKC 2019. ePrint 2019/052. 本地：`papers/jiang_zhang_ma_explicit_rejection_2019.pdf`
[6] J.-P. D'Anvers, Q. Guo, T. Johansson, A. Nilsson, F. Vercauteren, I. Verbauwhede. Decryption Failure Attacks on IND-CCA Secure Lattice-Based Schemes. PQCrypto 2019. 本地：`papers/danvers_decryption_failure_2019.pdf`
[7] NIST (Alagic et al.). Status Report on the Third Round of the NIST PQC Standardization Process, IR 8413. 2022. 本地：`papers/nist_ir_8413_2022.pdf`
[8] NIST (Alagic et al.). Status Report on the Fourth Round of the NIST PQC Standardization Process, IR 8545. 2025. 本地：`papers/nist_ir_8545_2025.pdf`
[9] NIST (Alagic et al.). SP 800-227 (ipd): Recommendations for Key Encapsulation Mechanisms. 2025. 本地：`papers/nist_sp_800_227_ipd.pdf`
[10] Chowdhury et al. Physical Security in the Post-Quantum Era: A Survey on Side-Channel Analysis, RNGs and PUFs. JCE 2022 (arXiv 2005.04344). 本地：`papers/pqc_physical_security_survey_2022.pdf`
[11] Delgado-Vargas et al. A Look at Side-Channel Attacks on Post-Quantum Cryptography. Computación y Sistemas 28(4), 2024. 本地：`papers/pqc_sc_survey_2024.pdf`
[12] Olaluwe et al. Machine Learning and Side-Channel Attacks on Post-Quantum Cryptography. ePrint 2025/1754, 2025. 本地：`papers/pqc_ml_sc_survey_2025.pdf`
[13] P. Ravi, A. Chattopadhyay, J.-P. D'Anvers, A. Baksi. Side-Channel and Fault-Injection Attacks over Lattice-Based Post-Quantum Schemes (Kyber, Dilithium): Survey and New Results. ACM Computing Surveys, 2024. 无本地 PDF（付费墙）

**时序攻击**

[14] Q. Guo, T. Johansson, A. Nilsson. A key-recovery timing attack on post-quantum primitives using the Fujisaki-Okamoto transformation and its application on FrodoKEM. PKC 2020. ePrint 2020/743. 本地：`papers/guo_fo_timing_2020.pdf`（另有 Springer 版 `papers/guo_johansson_nilsson_timing_2020.pdf`）
[15] D. J. Bernstein, K. Bhargavan, S. Bhasin, A. Chattopadhyay, T. K. Chia, M. J. Kannwischer, F. Kiefer, T. B. Paiva, P. Ravi, G. Tamvada. KyberSlash: Exploiting secret-dependent division timings in Kyber implementations. TCHES 2025(2), CHES 2025 最佳论文. ePrint 2024/1049. 本地：`papers/KyberSlash_timing_2024.pdf`
[16] Q. Guo, C. Hlauschek, T. Johansson, N. Lahr, A. Nilsson, R. L. Schröder. Don't Reject This: Key-Recovery Timing Attacks Due to Rejection-Sampling in HQC and BIKE. TCHES 2022(3). 本地：`papers/Guo_dont_reject_2022.pdf`
[17] R. L. Schröder, S. Gast, Q. Guo. Divide and Surrender: Exploiting Variable Division Instruction Timing in HQC Key Recovery Attacks. USENIX Security 2024. 本地：`papers/schroder_divide_surrender_2024.pdf`
[18] C. Hlauschek, N. Lahr, R. L. Schröder. On the Timing Leakage of the Deterministic Re-encryption in HQC KEM. ePrint 2021/1485, 2021. 本地：`papers/hlauschek_hqc_timing_2021.pdf`
[19] K. Hövelmanns, A. Hülsing, C. Majenz 等. (Un)breakable Curses — Re-encryption in the Fujisaki-Okamoto Transform. TCC 2025. ePrint 2025/299. 本地：`papers/Hovelmanns_unbreakable_curses_2025.pdf`
[20] A. Purnal. Compiler-introduced timing leak in Kyber reference implementation. NIST pqc-forum 披露（2024-06），PoC 见 github.com/antoonpurnal/clangover. 网页来源，无本地 PDF
[21] J.-P. D'Anvers, M. Tiepelt, F. Vercauteren, I. Verbauwhede. Timing Attacks on Error Correcting Codes in Post-Quantum Schemes. CCS 2019. 本地：`papers/danvers_ecc_timing_2019.pdf`
[22] H. An, S. Kim, J. Lee, R. Choi, K. Kim. Timing and Fault Attacks on Lattice-based Cryptographic Libraries. SCIS 2017. 本地：`papers/an_lattice_libs_2017.pdf`
[23] R. Merget, M. Brinkmann, N. Aviram, J. Somorovsky, J. Mittmann, J. Schwenk. Raccoon Attack: Finding and Exploiting Most-Significant-Bit-Oracles in TLS-DH(E). USENIX Security 2021. 本地：`papers/merget_raccoon_2021.pdf`（方法论参照，非 Kyber）
[24] J. W. Bos, C. Hubain, W. Michiels, P. Teuwen. Differential Computation Analysis: Hiding Your White-Box Designs is Not Enough. CHES 2016. 本地：`papers/bos_dca_whitebox_2016.pdf`（白盒 DCA，非时序信道）

**微架构信道**

[25] L. Groot Bruinderink, A. Hülsing, T. Lange, Y. Yarom. Flush, Gauss, and Reload – A Cache Attack on the BLISS Lattice-Based Signature Scheme. CHES 2016. ePrint 2016/300. 本地：`papers/GrootBruinderink_flush_gauss_reload_2016.pdf`
[26] T. Yu, C. Cheng, Z. Yang, Y. Wang, Y. Pan, J. Weng. Hints from Hertz: Dynamic Frequency Scaling Side-Channel Analysis of Number Theoretic Transform in Lattice-Based KEMs. TCHES 2024(3). ePrint 2024/070. 本地：`papers/yu_hints_2024.pdf`
[27] J. Qiu, A. Aysu. NTT-PEEL: Bit Shift Side-Channel in FALCON's Number Theoretic Transform. TCHES 2026(2). 本地：`papers/Qiu_ntt_peel_2026.pdf`

**功耗与电磁分析**

[28] R. Primas, P. Pessl, S. Mangard. Single-Trace Side-Channel Attacks on Masked Lattice-Based Encryption. CHES 2017. ePrint 2017/594. 本地：`papers/Primas_masked_single_trace_2017.pdf`
[29] P. Pessl, R. Primas. More Practical Single-Trace Attacks on the Number Theoretic Transform. LATINCRYPT 2019. ePrint 2019/795. 本地：`papers/Pessl_single_trace_NTT_2019.pdf`
[30] Y. Ji, R. Wang, K. Ngo, E. Dubrova 等. A Side-Channel Attack on a Hardware Implementation of CRYSTALS-Kyber. DATE 2023. ePrint 2022/1452. 本地：`papers/Ji_power_kyber_2023.pdf`
[31] Y.-T. Kuo, A. Takayasu. A Lattice Attack on CRYSTALS-Kyber with Correlation Power Analysis. ICISC 2023. ePrint 2023/1781. 本地：`papers/Kuo_cpa_lattice_kyber_2023.pdf`
[32] R. C. Rodriguez, F. Bruguier, E. Valea 等. Correlation Electromagnetic Analysis on an FPGA Implementation of CRYSTALS-Kyber. DTIS 2023. ePrint 2022/1361. 本地：`papers/Rodriguez_em_kyber_2023.pdf`
[33] C. Mujdei, L. Wouters, A. Karmakar, A. Beckers 等. Side-Channel Analysis of Lattice-Based Post-Quantum Cryptography: Exploiting Polynomial Multiplication. ACM TECS 2024. 无本地 PDF（ACM 付费墙）
[34] M. Azouaoui, O. Bronchain, C. Hoffmann, Y. Kuzovkova, T. Schneider, F.-X. Standaert. Systematic Study of Decryption and Re-encryption Leakage: the Case of Kyber. SAC 2021. ePrint 2022/036. 本地：`papers/Azouaoui_leakage_kyber_2022.pdf`
[35] M. Hamburg, J. Hermelink, R. Primas 等. Chosen Ciphertext k-Trace Attacks on Masked CCA2 Secure Kyber. TCHES 2021. 本地：`papers/Hamburg_k_trace_kyber_2021.pdf`
[36] Z. Xu, O. Pemberton, S. S. Roy, D. Oswald 等. Magnifying Side-Channel Leakage of Lattice-Based Cryptosystems with Chosen Ciphertexts. SAC 2021. 本地：`papers/Xu_magnifying_leakage_2021.pdf`
[37] L. Backlund, K. Ngo, J. Gärtner, E. Dubrova. Secret Key Recovery Attack on Masked and Shuffled Implementations of CRYSTALS-Kyber. CARDIS 2023. ePrint 2022/1692. 本地：`papers/Backlund_masked_shuffled_kyber_2023.pdf`
[38] S. Jendral, K. Ngo, R. Wang, E. Dubrova. A Single-Trace Message Recovery Attack on a Masked and Shuffled Implementation of Kyber. ePrint 2023/1587. 本地：`papers/Jendral_single_trace_masked_2023.pdf`
[39] R. Wang, M. Brisfors, E. Dubrova. A Side-Channel Attack on a Bitsliced Higher-Order Masked CRYSTALS-Kyber Implementation. ePrint 2023/1042. 本地：`papers/Wang_bitsliced_masked_kyber_2023.pdf`
[40] P. Ravi, S. S. Roy, A. Chattopadhyay, S. Bhasin. Generic Side-channel Attacks on CCA-secure Lattice-based PKE and KEMs. TCHES 2020(3). 本地：`papers/Ravi_generic_cca_2020.pdf`
[41] P. Ravi, S. Bhasin, S. S. Roy, A. Chattopadhyay. On the Exploitability of Message Leakage in (few) NIST PQC Candidates for Practical Message Recovery Attacks. IEEE TIFS 2021. 本地：`papers/Ravi_message_leakage_2021.pdf`

**故障注入**

[42] J. Hermelink, P. Pessl, T. Pöppelmann. Fault-Enabled Chosen-Ciphertext Attacks on Kyber. 2021. ePrint 2021/1222. 本地：`papers/Hermelink_fault_kyber_2021.pdf`
[43] K. Xagawa, A. Ito, R. Ueno, J. Takahashi, N. Homma. Fault-Injection Attacks against NIST's Post-Quantum Cryptography Round 3 KEM Candidates. 2021. ePrint 2021/840. 本地：`papers/Xagawa_fault_r3_kem_2021.pdf`
[44] P. Pessl, L. Prokop. Fault Attacks on CCA-Secure Lattice KEMs. TCHES 2021(2). 本地：`papers/Pessl_fault_cca_kem_2021.pdf`
[45] P. Ravi, B. Yang, S. Bhasin, F. Zhang, A. Chattopadhyay. Fault Injection Analysis of the Number Theoretic Transform (Fiddling the Twiddle Constants). TCHES 2023(2). ePrint 2022/824. 本地：`papers/Ravi_fault_ntt_2023.pdf`
[46] K. Hövelmanns, M. Kudinov. Treating Dishonest Ciphertexts in PQ KEMs — Explicit vs. Implicit Rejection in the FO Transform. PQCrypto 2025. ePrint 2025/062. 本地：`papers/Hovelmanns_explicit_implicit_2025.pdf`
[47] A. Joux, J. Loss, B. Wagner. Kleptographic Attacks against Implicit Rejection. PKC 2025. ePrint 2024/260. 本地：`papers/Joux_kleptographic_implicit_2025.pdf`

**Key mismatch 攻击**

[48] Y. Qin, C. Cheng, X. Zhang, Y. Pan, L. Hu, J. Ding. A Systematic Approach and Analysis of Key Mismatch Attacks on Lattice-Based NIST Candidate KEMs. ePrint 2021/123. 本地：`papers/Qin_key_mismatch_2021.pdf`
[49] Q. Guo, E. Mårtensson. Do Not Bound to a Single Position: Near-Optimal Multi-Positional Mismatch Attacks against Kyber and Saber. PQCrypto 2023. ePrint 2022/983. 本地：`papers/Guo_multipos_mismatch_2023.pdf`
[50] Q. Guo, E. Mårtensson, A. Åström. The Perils of Limited Key Reuse: Adaptive and Parallel Mismatch Attacks with Post-Processing against Kyber. ePrint 2024/810. 本地：`papers/Guo_limited_reuse_mismatch_2024.pdf`
[51] R. Mi, H. Jiang, Z. Zhang. Lattice Reduction Meets Key-Mismatch: New Misuse Attack on Lattice-Based NIST Candidates. ACNS 2022. ePrint 2022/1064. 本地：`papers/Mi_lattice_mismatch_2022.pdf`

**防御：常数时间实现**

[52] B. B. Brumley. SoK: The Constant-Time Model. arXiv 2606.13000, 2026. 本地：`papers/Brumley_sok_ct_2026.pdf`
[53] D. J. Bernstein. The Cryptoint Library. 2025. 本地：`papers/Bernstein_cryptoint_2025.pdf`
[54] X. Liang, Y. Qin, S. Pan, L. Tan. Constant-Time Symmetry Exploitation for NTT Twiddle Factors in ML-KEM: A Unified Cost Model for Embedded Deployments. Computers, Materials & Continua, 2026. 本地：`papers/Liang_ct_ntt_twiddle_2026.pdf`
[55] J. Huang, J. Zhang, H. Zhao, Z. Liu 等. Improved Plantard Arithmetic for Lattice-Based Cryptography. IEEE TC 2022. ePrint 2022/1295. 本地：`papers/Huang_plantard_2022.pdf`
[56] C.-M. M. Chung, V. Hwang, M. J. Kannwischer, G. Seiler, C.-J. Shih, B.-Y. Yang. NTT Multiplication for NTT-unfriendly Rings: New Speed Records for Saber and NTRU on Cortex-M4 and AVX2. TCHES 2021(2). ePrint 2020/1397. 本地：`papers/Chung_ntt_unfriendly_rings_2021.pdf`
[57] H. Becker, V. Hwang, M. J. Kannwischer, L. Panny, B.-Y. Yang. Efficient Multiplication of Somewhat Small Integers Using Number-Theoretic Transforms. WAIFI 2022. 本地：`papers/Becker_ntt_int_mul_2022.pdf`
[58] J. M. Bermudo Mera, A. Karmakar 等. Time-Memory Trade-Off in Toom-Cook Multiplication: An Application to Module-Lattice Based Cryptography. TCHES 2020(3). 本地：`papers/Bermudo_mera_toomcook_2020.pdf`
[59] A. Abdulrahman, V. Hwang, M. J. Kannwischer, D. Sprenkels. Faster Kyber and Dilithium on the Cortex-M4. ACNS 2022. ePrint 2022/112. 本地：`papers/Abdulrahman_faster_kyber_m4_2022.pdf`
[60] H. Becker, F. Klein. Towards Perfect CRYSTALS in Helium (SLOTHY). TCHES 2022. ePrint 2022/1303. 本地：`papers/Becker_helium_slothy_2022.pdf`
[61] J. B. Almeida, S. Arranz Olmos, M. Barbosa 等. Formally Verifying Kyber: Episode V: Machine-Checked IND-CCA Security and Correctness of ML-KEM in EasyCrypt. IACR CiC 2024. ePrint 2024/843. 本地：`papers/Almeida_easy_crypt_mlkem_2024.pdf`

**防御：掩码与掩码比较**

[62] J. W. Bos, M. O. Gourjon, J. Renes, T. Schneider, C. van Vredendaal. Masking Kyber: First- and Higher-Order Implementations. TCHES 2021(4). ePrint 2019/1207. 本地：`papers/Bos_masking_kyber_2021.pdf`
[63] D. Heinz, M. J. Kannwischer, G. Land, P. Longa. First-Order Masked Kyber on ARM Cortex-M4. SAC 2022. ePrint 2022/058. 本地：`papers/Heinz_first_order_masked_kyber_2022.pdf`
[64] T. Fritzmann, M. Van Beirendonck 等. Masked Accelerators and Instruction Set Extensions for Post-Quantum Cryptography. TCHES 2021(3). ePrint 2021/1093. 本地：`papers/Fritzmann_masked_accelerators_2021.pdf`
[65] J.-S. Coron, F. Gérard, S. Montoya, R. Zeitoun. High-Order Table-Based Conversion Algorithms and Masking Lattice-Based Encryption. TCHES 2022(1). ePrint 2021/1314. 本地：`papers/Coron_table_conversion_2022.pdf`
[66] J.-S. Coron, F. Gérard, S. Montoya, R. Zeitoun. High-Order Polynomial Comparison and Masking Lattice-Based Encryption. ePrint 2021/1615 / TCHES 2022. 本地：`papers/Coron_high_order_comparison_2021.pdf`
[67] O. Bronchain, G. Cassiers. Bitslicing Arithmetic/Boolean Masking Conversions for Fun and Profit. TCHES 2022(4). 本地：`papers/Bronchain_bitslicing_2022.pdf`
[68] A. Aikata, A. Basso, G. Cassiers, A. C. Mert 等. Kavach: Lightweight Masking Techniques for Polynomial Arithmetic in Lattice-Based Cryptography. TCHES 2023(3). 本地：`papers/Aikata_kavach_2023.pdf`
[69] E. Dubrova, K. Ngo, J. Gärtner, R. Wang. Breaking a Fifth-Order Masked Implementation of CRYSTALS-Kyber by Copy-Paste. AsiaCCS 2023. ePrint 2022/1713. 本地：`papers/Dubrova_copy_paste_2023.pdf`
[70] K. Ngo, R. Wang, E. Dubrova 等. Side-Channel Attacks on Lattice-Based KEMs Are Not Prevented by Higher-Order Masking. ePrint 2022/919. 本地：`papers/Ngo_higher_order_not_prevented_2022.pdf`
[71] J.-P. D'Anvers, D. Heinz, P. Pessl, M. Van Beirendonck, I. Verbauwhede. Higher-Order Masked Ciphertext Comparison for Lattice-Based Cryptography. ACNS 2021. ePrint 2021/1425. 本地：`papers/Danvers_masked_ct_comparison_2021.pdf`
[72] J.-P. D'Anvers, M. Van Beirendonck 等. Revisiting Higher-Order Masked Comparison for Lattice-Based Cryptography: Algorithms and Bit-Sliced Implementations. IEEE TIFS 2022. ePrint 2022/712. 本地：`papers/Danvers_revisiting_masked_comparison_2022.pdf`
[73] F. Bache, C. Paglialonga, T. Oder, T. Schneider, F.-X. Standaert 等. High-Speed Masking for Polynomial Comparison in Lattice-Based KEMs. SAC 2020 / TCHES. 本地：`papers/Bache_highspeed_comparison_2020.pdf`
[74] S. Bhasin, J.-P. D'Anvers, D. Heinz, M. Van Beirendonck, I. Verbauwhede. Attacking and Defending Masked Polynomial Comparison for Lattice-Based Cryptography. TCHES 2021(3). 本地：`papers/Bhasin_masked_comparison_attack_2021.pdf`

**防御：乱序、分区与随机化**

[75] Z. Chen, Y. Ma, J. Jing. Low-Cost Shuffling Countermeasures Against Side-Channel Attacks for NTT-Based Post-Quantum Cryptography. IEEE TCAD 2022. 无本地 PDF（IEEE 付费墙）
[76] J. Hermelink, S. Streit, E. Strieder, T. Strieder. Adapting Belief Propagation to Counter Shuffling of NTTs. TCHES 2023(3). ePrint 2022/555. 本地：`papers/Hermelink_belief_propagation_shuffling_2023.pdf`
[77] P. Ravi, R. Poussier, S. Bhasin, A. Chattopadhyay. On Configurable SCA Countermeasures Against Single-Trace Attacks for the NTT: A Performance Evaluation Study over Kyber and Dilithium on the ARM Cortex-M4. COSADE 2020. ePrint 2020/1038. 本地：`papers/Ravi_configurable_ntt_countermeasures_2020.pdf`
[78] D. Xu, K. Wang, J. Tian. A Hardware-Friendly Shuffling Countermeasure Against Side-Channel Attacks for Kyber. IEEE TCAS-II 2025 (arXiv 2407.02452). 本地：`papers/Xu_shuffling_kyber_hw_2025.pdf`
[79] H. Zhang, Z. Ye, T. Wang 等. A Chosen-Ciphertext Side-Channel Attack on Shuffled CRYSTALS-Kyber. ePrint 2025/1956. 本地：`papers/Zhang_shuffled_kyber_attack_2025.pdf`
[80] P. Ravi, T. Paiva, D. Jap, J.-P. D'Anvers, S. Bhasin. Defeating Low-Cost Countermeasures Against Side-Channel Attacks in Lattice-Based Encryption: A Case Study on CRYSTALS-Kyber. TCHES 2024(2). ePrint 2023/1627. 本地：`papers/Ravi_lowcost_2024.pdf`
[81] M. Duparc, M. Taha. Improved NTT and CRT-Based RNR Blinding for Side-Channel and Fault Resistant Kyber. ePrint 2025/181. 本地：`papers/Duparc_rnr_blinding_2025.pdf`
[82] RIC: Randomize Invalid Coefficients to Mitigate Side-Channel Leakage. TCHES 2026. ePrint 2026/924. 本地：`papers/Ric_invalid_coefficients_2026.pdf`
[83] N. Ait Manssour, S. Duval 等. First-Order Masked Fine-Shuffling Implementation Against Side-Channel Attacks with Application to ML-KEM. ePrint 2026/934. 本地：`papers/Duparc_masked_fine_shuffling_2026.pdf`

**评估方法论**

[84] B. J. G. Goodwill, B. Jun, J. Jaffe, P. Rohatgi. A Testing Methodology for Side-Channel Resistance Validation (TVLA). NIST NIAT Workshop 2011. 本地：`papers/Goodwill_tvla_2011.pdf`
[85] G. Becker, J. Cooper, E. DeMulder, G. Goodwill 等. Test Vector Leakage Assessment (TVLA) Methodology in Practice. ICMC 2013. 无本地 PDF（原链接失效）
[86] T. Schneider, A. Moradi. Leakage Assessment Methodology — A Clear Roadmap for Side-Channel Evaluations. CHES 2015. 无本地 PDF（Springer 付费墙）
[87] M.-J. O. Saarinen. Wip: Applicability of ISO Standard Side-Channel Leakage Tests to NIST PQC. HOST 2022. ePrint 2022/229. 本地：`papers/Saarinen_iso_tvla_2022.pdf`
[88] PROLEAD_SW: Evaluating the Security of Software Implementations Against Physical Attacks. TCHES 2025. 本地：`papers/Prolead_sw_2025.pdf`
[89] T. Kamucheka, M. Fahr, T. Teague, A. Nelson, J. Kizza. Power-Based Side-Channel Attack Analysis on PQC Algorithms. ePrint 2021/1021. 本地：`papers/Kamucheka_tvla_pqc_2021.pdf`
[90] O. Reparaz, J. Balasch, I. Verbauwhede. dude, is my code constant time? DATE 2017. ePrint 2016/1127. 本地：`papers/reparaz_dudect_2017.pdf`

**补充条目**：目录中另有 `papers/Rajendran_parallel_pc_oracle_2023.pdf`（并行 PC oracle 构造方向，2023，本次未单列编号），供扩展阅读；全部检索 CSV 见 `searches/`。

---

*调研完成时间：2026-10-11。论文元数据来自 Scholar 学术检索与网页验证；未发明任何条目；付费墙条目已如实标注"无本地 PDF"。*
