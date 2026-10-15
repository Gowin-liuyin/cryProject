# 收尾阶段 0：基线核验（T00）

时刻：2026-10-16T03:57:41+08:00（Asia/Shanghai）

## 基线偏差声明（重要）

本计划书写明的基线是 `origin/main@c849c0f`。实际核验时基线已经前进：

```
e81c1ae docs: FINAL_AUDIT 第五版按提交后快照 7a71d5c 复核
7a71d5c docs: 补收尾轮交接并闭合末次审计的 C-11
7350e6a docs: FINAL_AUDIT 第四版并同步报告与进度记录
36fb0d4 test: 出 final4 匿名包并在包内复算 CTest
5e16d0c docs: 报告并入 R03 格式破损对照与 R05 全流程排查表，M4 改为只引用分臂数值
dc6522c docs: 把 R03 的实测数字补进 R05 排查表的族外对照一节
dd6f105 test: R03 格式破损/截断族外对照的锁频实测结果
a45a56d feat: 新增 R03 格式破损/截断输入族外对照计划与采集件
1cc538b docs: 新增 R05 解封装全流程六类来源排查表（赛题第 5 条）
b637d0d docs: 修掉末次审计的三条快照描述性不一致（C-02/C-03/C-04）
b94e942 fix: 把 M2 取证树里的 avx2/.gitignore 符号链接换成普通文件
```

因此 T01（C-02）、T02（C-03）、T03（C-04）、T04（循环链接）、T10（R03 PLAN）、
T11（R03 生成器）、T12（R03 锁频采集）、T13（R03 统计）、T14/T16（R05 表与流程图）、
T32（final4 匿名包）、T33（FINAL_AUDIT 第 4、5 版）**已在该区间完成并推送**，本轮不重做，
只做复核与引用。本轮实际基线 = `origin/main@e81c1ae`，且本地与远端一致。

## 仓库状态

```
HEAD            = e81c1aee541f5e9c2f93e061c8a5b5fa923c749d
origin/main     = e81c1aee541f5e9c2f93e061c8a5b5fa923c749d
ahead/behind    = 0 / 0
已跟踪改动      = 0
分支            = main
```

## 冻结 PLAN 的 sha256（阶段 5 前后比对用）

```
ab447adadeb5aae2b79843946ab38a6e7a5412506a13d9abd738c3c22a9a9a20  docs/evidence/m2-kem-20261016/PLAN.md
0176288fbe8b95419fbacd0a216fe6aa5106445f5b0ca368d0d33e79b62a408e  docs/evidence/m5-completion-20261016/PLAN.md
3fc60d1319d9da2a5246c1aa83760c46bcdac4131f98d610f9805be9f22ed4db  docs/evidence/m3-completion-20261016/PLAN.md
c1c2c7647c65f85e6b38df12132dc3e73f83cfcd1862207b7f5e24992539d34a  docs/evidence/m4-completion-20261016/PLAN.md
```

冻结提交 `efca8a1` 中四个 blob 的 sha256（与上表执行版本一致）：

```
0f706455c6a8fde28ecd3dc18fb12ae4562c2f57dc7e2d991b5ff83c5cd07142  docs/evidence/m2-kem-20261016/PLAN.md
15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44  docs/evidence/m5-completion-20261016/PLAN.md
be2db4599fb9c5d39852f001d3cf872173b68c2d65ebb4ca542ea0798e01a4a0  docs/evidence/m3-completion-20261016/PLAN.md
767f0378124645f9830b14cfbff61fb2571cbf050b451b93fbe74ac8256f509a  docs/evidence/m4-completion-20261016/PLAN.md
```

## 关键交付物的 sha256（本阶段快照）

```
9ec07698f86354cf9eba722b8c334cfafba9b960c1b0793b5908705f677e0d1c  docs/evidence/platform-completion-20261016/FINAL_AUDIT.md
9154df71e724ab11a77343a5abd6819d3b0815411a9741d666bfaf54c4140311  docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv
cc7ecff95ffd5a4e03c822b3e6ea36bc35393ad2fc42272bc5a2f2890d109bf9  docs/R05-全流程排查表.md
570ab957bc50d6f8f79839eb946ad7a05eb03fd807b9f93175c7f6721b669c53  deliverables/research/multi-leakage-platform-20261016/report.pdf
```

## ctest 基线

见同目录 `ctest-platform-on.log`（平台开，期望 87/87）、`ctest-ordinary.log`（期望 57/57）、
`ctest-sanitize.log`（期望 57/57）。本轮先记录，若与期望不符则写入 BLOCKERS。
