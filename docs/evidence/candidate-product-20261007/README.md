# 候选版使用与证据展示核验

13个稳定编号、每项8字段；历史与本轮、文献与实际运行、普通性能与防护效果各自标注。
H01分布表10行仅读既有C报告；H1失败与后续掩码残差并列。E02/N01全部36套逐次CSV、
meta、成本与日志可直达；C02/C04原用途不改。新增完整N01输入清单绑定原2e94648导出，
[N01到产品差异](N01-to-product.patch)仅为帮助入口与其行为检查，旧数据不改绑到新源码。

help/--help/-h正确返回0，非法命令返回2并提示格式；复用现有audit，无新平台或新统计。
普通工作流与源导出2项检查通过；Clang本地ASan/UBSan同2项通过；新匿名包将另单验。
首轮selector误写workflow匹配0个测试，保留help-test.log并不计作通过；后使用真实audit_workflow
与--no-tests=error。补充帮助文字后format-check发现换行问题，help-final-build.log保留，
格式修正后help-final-build-retry.log和help-final-test.log通过。没有修改阈值或数据消除失败。

[初次展示审查](demo-review.json)及[最终链接核验](final-links.json)绑定本页直接相对文件。
真实界面截图未取得；人工说明要求实际画面、源身份、日志与退出，标明现场/封存及匿名
副本转换；真实非原作者和本人签署不得由Agent代填。R07/R11缺口不因页面或帮助完成升级。
