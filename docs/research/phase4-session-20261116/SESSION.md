# P4（修复模式库 + MCP server）会话报告（2026-11-16）

## 1. 开工自检（原文）

```text
$ cd ~/cryProject-work && git branch --show-current
main
$ git status --porcelain | head -5
（无输出）
$ git log --oneline -2
88d25b9f test(pipeline): 回放端到端测试与会话记录
3ab852ae feat(pipeline): manifest/findings 模式与 freeze/verify/run-local/report 编排器

$ python3 --version
Python 3.13.12

$ ls docs/research/phase3-session-20261116/manifests/
m1-r0204-replay.json
m5-reference.json
```

《任务书》§6 复述：T4.1 产出 `tools/pipeline/repair_patterns/` 四条目与
`repair_propose.py`（positive 定位项 × 反汇编文本 → 纯文本补丁建议，不自动应用）；
T4.2 产出 `tools/pipeline/mcp_server.py`（stdio JSON-RPC 2.0 八工具）与
`tests/test_mcp_smoke.sh` 冒烟测试。

## 2. 每任务状态与关键数字

### 提交 1｜T4.1 修复模式库与建议器 —— 完成

- 四条模式（均含 `id/disasm_pattern/mechanism/patch_template/known_example/
  known_counterexample/risk_note`）：
  1. `secret_branch_to_mask`：bt / 立即数位 test 驱动的条件跳转；known_example =
     `docs/patches/m2-frommsg-barrier-asm.patch`。
  2. `secret_div_to_mulshift`：div/idiv 寄存器或内存操作数；known_example =
     `docs/evidence/m2-kyberslash-20261016/version-audit/upstream-remediation.diff` 摘录。
  3. `secret_index_to_ctselect`：base+index*2/4 的 mov 表查找；known_example =
     `docs/patches/message-constant-time.patch`。
  4. `early_exit_compare_to_or`：循环内秘密相关早退比较；known_example =
     `fixtures/early_reject_memcmp/compare_ct.c`，known_counterexample = 同目录
     `compare_early.c`。
- `repair_propose.py --finding <findings.json> --disasm <objdump.txt>`：只读输入文件、
  不调用 objdump、不写文件；对 `verdict=positive, layer=localize` 的项逐模式匹配，
  输出命中指令、所在函数、模板渲染的 diff 建议，末尾附
  「不自动应用，人工审阅后按新提交落盘」。
- 自检三分支（输出在 `build/p4-selfcheck/`，gitignored；命令见本报告 §5）：
  - **a** R0a 未修基线 `docs/evidence/r0a-branch-fix-20261116/disasm/baseline-poly_frommsg.asm`
    （含 `bt → jae`）→ **命中 `secret_branch_to_mask`（1 个候选）**；
  - **b** `fixtures/early_reject_memcmp/compare_early.c` 编译后 objdump → **命中
    `early_exit_compare_to_or`（2 个候选：函数内两处 `cmp mem,%reg` + jcc）**；
  - **c** `build/cmake-platform/platform_m5_poison` 的 `baseline_native_poly_frommsg`
    objdump → **四模式零命中（0 个候选）**。
- 补充对照：`unfixed poly_compress` 反汇编的 `div %r8d` 命中
  `secret_div_to_mulshift`（1 条）；合成 `movzwl (%rsi,%rax,2),%ecx` 片段命中
  `secret_index_to_ctselect`（1 条）。同一次 poly_compress 反汇编里 `secret_index_to_ctselect`
  也对公开循环索引的 scale-2 载入报出 1 条 —— 这是预期的人工复核噪声
  （模式只按反汇编形态匹配，risk_note 已注明不能自动定性），如实记录。

### 提交 2｜T4.2 MCP server 与冒烟 —— 完成

- `tools/pipeline/mcp_server.py`：stdio、换行分隔 JSON-RPC 2.0
  （`initialize`/`tools/list`/`tools/call`，含错误码 -32700/-32600/-32601/-32602/-32603），
  纯标准库；八工具：
  `registry_list`（列 P3 两个真实 manifest）、`qualify_dry`（只汇编构建命令不执行）、
  `detect_submit`/`job_status`（作业入队/查询，状态写 `build/pipeline-runs/jobs.json`）、
  `findings_get`（读 run 的 findings.json）、`repair_propose`（包 T4.1）、
  `report_generate`（包 `pipeline.py report`）、`evidence_get`（docs/ 或 tools/ 内文件的
  路径 + SHA-256，只读）。
- 冒烟 `tests/test_mcp_smoke.sh`：printf 三条 JSON-RPC（initialize / tools/list /
  tools/call registry_list）管道给 server，断言 **3 条响应、工具数=8、registry_list
  返回两个真实 manifest**；已按 P3 方式在根 `CMakeLists.txt` 注册（+6 行）。
- 全部 8 个工具另做一次手工逐工具调用（`build/p4-selfcheck/mcp-requests.jsonl`）：
  initialize/tools/list + 8 tools/call 全部成功，`detect_submit` 生成 `job-0001`、
  `job_status` 可查、`findings_get` 读到 16 条 findings、`repair_propose` 命中
  branch 候选、`report_generate` 重新生成 m5 report、`evidence_get` 返回补丁 SHA-256。
- `ctest --preset baseline-wsl`：**59/59 通过**（原 58 + test_mcp_smoke）；
  format-check 通过。

## 3. 两个提交（本地 main，作者/提交者 `Gowin-liuyin`，未 push）

| hash | 信息 |
|---|---|
| `787aa182` | `feat(pipeline): 修复模式库四条目与 repair_propose 补丁建议器` |
| 本文件所在提交 | `feat(pipeline): MCP server 八工具与冒烟测试`（hash 见 `git log -1`，文件无法自引用） |

## 4. 自检命令（可复跑）

```sh
# a/b/c 三分支 + 补充对照（输出 build/p4-selfcheck/*.txt）
sh build/p4-selfcheck/run_selfcheck.sh
# 8 工具逐工具自检
python3 tools/pipeline/mcp_server.py < build/p4-selfcheck/mcp-requests.jsonl \
    > build/p4-selfcheck/mcp-responses.jsonl
python3 build/p4-selfcheck/check_mcp_tools.py build/p4-selfcheck/mcp-responses.jsonl
# 冒烟 CTest
ctest --preset baseline-wsl -R test_mcp_smoke --output-on-failure
```

## 5. 偏离项及理由

1. **自检输出位置**：三分支的 objdump、findings fixture 与输出文本全部写
   `build/p4-selfcheck/`（gitignored），未进 git；SESSION 记录命令与结论。
2. **early 分支候选数=2**：`compare_early.o` 中确有两处「内存操作数 cmp + 条件跳转」
   （首字节比较 `jne` 早退、循环内 `je` 继续），同一模式报 2 条为如实结果，未按函数去重。
3. **索引模式的人工复核噪声**：`secret_index_to_ctselect` 只按 `base+index*2/4` 的 mov
   形态匹配，无法从反汇编单独证明索引来自秘密（`risk_note` 已写明）；补充对照里
   poly_compress 的公开循环索引载入也被报出 1 条，属预期噪声，不视为阳性结论。
4. **MCP 写边界**：仅 `detect_submit` 写 `build/pipeline-runs/jobs.json`；
   `repair_propose` 只返回文本；`evidence_get` 限定 docs/ 或 tools/ 且只读；
   `report_generate` 仅经既有 `pipeline.py report` 写 run 目录。
5. **构建与平台树**：本轮未重建平台树；仅构建 M5 自检产物 `platform_m5_poison`
   与两个 compare fixture 到 `build/`（产物，gitignored）。
6. **工具环境限制**：WSL 既有文件经 `\\wsl.localhost` 编辑报 `GetFileSecurityW EIO`，
   `CMakeLists.txt` 与模式 JSON 的修订用“Windows 临时文件 + cp”/`sed -i` 落地，
   `git diff` 核对为预期新增/修订。

## 6. 卡点

- 无阻塞性卡点（纯离线：未取件、未联网、未 pip 安装、未采集）。
- 边界：模式库与建议器是**人工审阅辅助**，不自动定性、不自动应用补丁；
  MCP 是本地编排接口，不是通用服务；P5/P6 观测者与自适应引擎留待后续阶段。
