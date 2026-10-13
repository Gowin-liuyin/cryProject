# 模块 A 判定规则（v3 事后归因）

规则编号 `v3_attribution_20261013`。本文件与 `INPUTS.sha256`、`src/attribution_v3.c`
在看到归因数字之前入库。本地提交是作者自证顺序，不是第三方预注册。
分析程序只读这些密封输入，不打开网络，不追加样本，不改密封字节。

## 1. 输入与停止

工作目录是仓库根。`INPUTS.sha256` 每行三个字段：小写 SHA-256、角色、相对路径。
程序先核对每个文件的 SHA-256。任一不一致则退出状态 2，写出
`status=stopped_digest_mismatch`，不给科学判定。

角色与份数在 `--expect-sealed` 下必须恰好是：

- `decision:v1`、`decision:v2`、`decision:v3` 各 1
- `protocol:v2`、`protocol:v3` 各 1
- `csv:v1`、`empty:v1`、`meta:v1` 各 6
- `csv:dev_before`、`meta:dev_before`、`csv:dev_message`、`meta:dev_message`、`meta:v3` 各 1
- 没有 `csv:v2`、`csv:v3`、`empty:v2`、`empty:v3`

身份锚点，不一致则退出状态 3，`status=stopped_identity_mismatch`：

- v1 元数据 `seed=20261111`、`run_id=ryzen-vulnerable`，会话 `s1`–`s6` 各 1000 条
  message-zero 与 1000 条 message-ones；空窗文件恰好 256 行
- v2 协议含整行 `confirmation_seeds=8675309`，决策文件 20 个会话 `s1`–`s20`
- v3 协议含整行 `confirmation_seeds=31415926`，元数据 `seed=31415926`、
  `run_id=v3-vulnerable`、`empty_window_count=256`、`message-zero_count=5000`、
  `message-ones_count=5000`、`message-zero_unique_ciphertexts=1`、
  `message-ones_unique_ciphertexts=1`，决策文件 20 个会话 `s01`–`s20`
- 90210 的 before / message 元数据 `seed=90210`，run_id 分别为
  `dev-window-90210` 与 `dev-window-90210-message`，各 1 个会话、每类 200 条

会话效应是 message-zero 均值减 message-ones 均值，单位是 `CLOCK_MONOTONIC` 计数。
有原始 CSV 时用双精度累加后除以个数，与决策文件里 `session_effect` 的绝对差
不得超过 `1e-6` 计数，决策文件里的主效应也必须等于各会话效应的算术平均
（同一容差）。否则退出状态 3，`status=stopped_recompute_mismatch`。
v2 与 v3 的逐次原始表不在封存树内，不做这项复算，也不把缺失补成 0。

## 2. 描述统计（不单独改写主判定）

多会话运行（至少 3 个连续会话）做普通最小二乘：

```text
D_s = α + β u_s + ε_s
u_s = (s - 1) / (S - 1) - 0.5
```

`s` 从 1 到 S，按会话编号排序。`u_s` 关于会话居中，所以 `α` 等于 `D_s` 的
算术平均。居中线性项不移动均值点估计。斜率 `β` 是从第一个会话位置到最后一个
会话位置的拟合变化，单位仍是计数。检验是双侧 Student t。
`{α, β}` 组成一个 Holm 族，族水平 0.01。残差平方和为 0 时，系数为 0 则
p=1，系数非 0 则 p=0。

v1 有逐会话空窗时，空窗协变量是 256 个计数的中位数（偶数个取中间两数的算术平均）。
中位数对会话序号再做上面的一元回归，只报告斜率。把居中后的空窗中位数加进
`D_s` 的回归，报告其系数的双侧 p，水平 0.01，不进入第 3 节的判定族。
居中协变量同样不移动 `α` 的点估计，因此不能用来把均值“解释掉”。
v3 密封元数据里的单个 `empty_window_max` 只入档，不进入回归。

有原始 CSV 时，按该会话数据行数把 `sample_index` 切成 4 段。段效应仍是
该段 message-zero 均值减 message-ones 均值。段漂移是第 4 段减第 1 段。
至少 6 个会话且两段都有定义时，对段漂移做一次单样本双侧 t，水平 0.01，
不进入判定族。

同一 CSV 上另算调用序号的时钟斜率（全部类别一起回归）和两类的平均
`sample_index` 之差。预测伪差 = 时钟斜率 × 位置差。残差效应 = 会话效应 − 预测伪差。
至少 6 个会话且每会话都有定义时，对残差效应做单样本双侧 t，水平 0.01。
未调整均值在同一水平被拒绝、残差均值不被拒绝，记
`clock_explains=yes`。这只描述有原始表的运行。v3 没有原始表，记
`not_in_sealed_tree`，既不支持也不排除调用级时钟混淆。

## 3. v3 主判定

只使用 v3 决策文件里的 20 个会话效应。两个预先分开的族，都是双侧、族水平
0.01，互不借阈值：

1. 线性族：第 2 节的 `{α, β}`，Holm。
2. 稳定族：前 10 个会话与后 10 个会话各自的单样本均值检验，Holm。
   全样本均值的符号记为稳定符号。两半都拒绝，且两半点估计都是这个符号，
   才记 `half_stable=yes`。

主令牌 `v3_effect_explained_by_drift` 只取下列之一：

| 条件 | 令牌 |
|---|---|
| 线性族中 `α` 未拒绝且 `β` 拒绝 | `yes_pure_trend` |
| 线性族中 `α` 拒绝，且 `half_stable=yes` | `no` |
| 线性族中 `α` 拒绝，`half_stable=no`，且 `β` 拒绝 | `partial` |
| 线性族中 `α` 拒绝，`half_stable=no`，且 `β` 未拒绝 | `not_linear` |
| 线性族中 `α` 与 `β` 都未拒绝 | `inconclusive` |

`no` 的含义是：密封主效应是前后半会话同号的稳定水平，会话序号上的线性漂移
没有把它解释掉。`yes_pure_trend` 的含义是：密封主效应与一条均值接近零的
线性趋势相容。`partial` 的含义是：水平检验仍拒绝，但前后半不稳定且存在
线性趋势。`not_linear` 的含义是：前后半不稳定，而线性斜率本身不被拒绝。
`inconclusive` 的含义是：这一族不支持稳定水平，也不支持线性漂移。

会话数小于 4 或为奇数时，稳定族无定义。此时只有“`α` 未拒绝且 `β` 拒绝”
仍记 `yes_pure_trend`，其余记 `not_run`。密封的 v1、v2、v3 会话数是 6、20、20。
同一套令牌也打印 v1 与 v2，字段名是 `context_token`，不进入 v3 的两个族，
也不改写 `v3_effect_explained_by_drift`。

报告正文用密封主效应的全精度，并在 `%.3f` 恰好为 `-5.467` 时注明该引用值。
引用值不是阈值。

## 4. 方向反转（不改写第 3 节）

观察 v1 决策主效应、90210 message 窗口的单会话效应、v3 决策主效应的符号。
三者不是同一符号时记 `sign_reversal=yes`。

线性跨度覆盖规则：`|β_v1| + |β_v3| >= |α_v1 - α_v3|` 时记
`reversal_within_run_span=yes`，否则为 `no`。90210 只有一个会话，不提供 `β`。
该规则只回答“两次运行内部的线性跨度加起来是否盖得住两次均值之差”，
不改写 `v3_effect_explained_by_drift`。

## 5. 程序

入口是 `attribution_v3`。密封运行：

```text
attribution_v3 --expect-sealed INPUTS.sha256 输出目录
```

输出目录必须已存在。程序把同一份结论写到标准输出和 `conclusion.txt`，
不写时间戳。两次运行的输出应当逐字节相同。
