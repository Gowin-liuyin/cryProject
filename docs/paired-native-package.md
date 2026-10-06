# 原生配对比较执行包

本轮用户确认暂无目标环境。本包软件已在ARM64 macOS检查；原生前置、开发选择和确认均
尚未执行。`tools/prepare_paired_native.sh`只做前置准备，不自动开始开发或确认。

依赖沿用CMake≥3.21、C11 GCC/Clang、Git、Make/Ninja、patch、shasum、OpenSSL、objdump、
file、POSIX sh/awk/sed；新增GNU coreutils的timeout及用于元数据清单的rg。
用完整固定提交检出，构建/测试输入不得有未提交或未跟踪变动。`.agents/`不读取。

环境提供者必须给出宿主型号和架构、裸机/VM/容器、QEMU/架构翻译情况、CPU亲和性、
频率与后台状态及核验方法。仅有uname或环境变量不能证明原生执行。
`review-note.txt`至少包含 `platform_review=accepted`、`dependency_review=accepted`或pending，
并解释依据。accepted是人工核查结论，不是脚本检测结果；没配置的控制不得写成已控制。

```sh
source_commit=$(git rev-parse HEAD)
NATIVE_X86_64_LINUX_CONFIRMED=yes sh tools/prepare_paired_native.sh \
    "$source_commit" /absolute/new-package /absolute/execution-note.txt /absolute/review-note.txt
```

300秒timeout限定无法预先读钟的自举构建，其墙钟按[0,300秒]保守计入。
自举后由C的CLOCK_MONOTONIC纳秒测量参考前置、必要编译、测试及产物取证。
共同完整解封装调用数采用40000上界，平分后各扣20000辅助预算：两套参考功能/普通入口、
新增批次/编排测试及原前置9000调用均有固定有限循环，实际在该上界内。
新增测试或扩大前置时必须重新核查上界，不能继续沿用。共享未知项不是0。
已保存的普通前置样本不是开发/确认数据；动态测试样本不作正式性能结果。

准备包包含输入种子排除表、拟议K4/K16各5对计划、一本共用预算账、构建与功能记录、
正式产物反汇编、执行说明和每步退出码。检查目标平台CPU读取路径、计时器/空窗及反汇编
之后才能接受前置；任何失败停止并保留材料。数据目录和输出必须是新路径。

前置接受后才执行两个开发计划，串行、不同时编译或跑动态检查：

```sh
package=/absolute/new-package
"$package/build/paired_runner" run development "$package/plans/development-k4.plan.csv" \
    "$package/build" "$package/development-k4" "$package/budget.meta"
"$package/build/analyze_paired" "$package/development-k4" "$package/development-k4.report"
"$package/build/paired_runner" run development "$package/plans/development-k16.plan.csv" \
    "$package/build" "$package/development-k16" "$package/budget.meta"
"$package/build/analyze_paired" "$package/development-k16" "$package/development-k16.report"
```

两个K不得各初始化账本；开发成本累计。所有失败保留，不自动重试。
报告的开发点估计只用于原规约选择，不作为确认；5对bootstrap可能有分母退化，不能删掉
这些重采样。只在数据、中心、依赖、预算和成本条件合格时按预定S比值选一个K，精确并列K4。
两者不合格就停止。当前没有开发数据，因此本轮没有选择或冻结K。

确认前另行提交选择依据、实际账、一个K、源/分析/产物摘要、20个新种子、输入与方法顺序、
平台和失败规则。排除表须重新扫历史与全部开发meta；拟议开发文件不能当确认冻结文件。
确认计划固定20对、每类2000、10对基线先10对候选先，按种子20261030的既定洗牌。
执行 `paired_runner run confirmation ...` 及 `analyze_paired`，仍使用同一本账。
确认入口不会替你生成合格的冻结证据；检查Git提交、预算和平台条件是开始前的必需步骤。

作者复算不要求旧构建目录存在。重新构建分析器，对封存目录运行analyze_paired，并核验
清单、CSV/meta/成本摘要；来源不完整、配对不一致、预算未闭合或环境依赖不可接受时不升级
声明。原生结果表目前所有实验值均为未执行，软件夹具不填进去。
