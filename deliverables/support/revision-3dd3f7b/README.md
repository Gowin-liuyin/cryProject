# 模板排版与PPT图源修订包

本目录ZIP为最新支撑材料，更新了按附件二排版的论文图源及导出图，包含可编辑
figures/论文图源.pptx。源码和113份原数字CSV与上一份经过原生Linux验证的匿名包保持字节，
源码导出清单仍为c1e8af5e85bf38dffebf9f9fe896b64fc618603be1a713c7ff3161875deaa026。
本次没有把上一包原生执行日志冒称新ZIP的执行；环境执行参考见anonymous-finite-revision-20261007。

```sh
shasum -a 256 -c SHA256SUMS
unzip 待编号-2026密码竞赛复赛相关支撑材料.zip
cd 待编号-2026密码竞赛复赛相关支撑材料/source
cmake --preset baseline
cmake --build --preset baseline --parallel 4
build/cmake/audit check
```

打开解压包index.html可查看完整数据及下载PPT图源。本次排版修订的原件摘要、字体角色、
字号、三分节、页边距、页眉/页脚及图表数字核对见docs/template-fidelity.md及其证据目录。
原DOCX字体名保留，当前环境旧名映射为已安装字体；字体文件不分发。原科学结论与限制
保持，完整项目仍缺真实密码总体校准、新受控防护链、非原作者记录、截图和人工签署。
