# ARIS 研究合稿核验

2026-10-08将限定研究包纳入新的[报告候选稿](../../../deliverables/submission/CACR2026EA16XZ/aris-20261008/README.md)。编辑基线为工作DOCX的SHA256 5be8723b93ff10822e82a7d92cbd37667cb25495195f9f05cf2a916b1be1776f；它在任务字体环境下为40页，区别于先前39页导出。

通过[科学合稿审查](scientific-review.md)后，修正对自动资格识别过强的一句表述。新增两条原生公式、直接先验与方法边界；原（4-2）顺延为（4-4）。原（5-4）中的fixed times文本在渲染时产生错误符号，改用已定义的固定时间向量下标，条件概率的含义不变。

首轮渲染未加载中文字体，已拒绝交付。使用本机现有Word字体及任务fontconfig重新渲染，不安装字体、不修改DOCX字体名。之后41页逐页验收，[1–22页记录](visual-review-1.md)与[23–41页记录](visual-review-2.md)完整保留。章末两行、结尾与单条文献孤页通过精简重复文字收口，字号与原格式保持。

[结构核验](verification.json)确认只有document.xml改变，其余40部件原字节相同，四分节、20表对象和18绘图对象保持。表XML完整一致；16幅编号图不变。目录42项按[最终页码](toc-map.json)核对。全部数字来自已有档案，没有新密码调用。

随后发现继承摘要将所有Linux普通探索区间概括为跨零，已按当前档案更正：KVM的E02/N01区间跨零，Ryzen裸金属区间不跨零。早期verification.json保留首轮版本摘要；当前版本与其关系由[范围修正核验](scopefix-verification.json)记录。当前DOCX摘要为223e6da18fbfbf2dd1987be9670d688609a54d30a3e48d070b30ab8974824b30。更正后41页，只有第37页图像不同，已重新按原分辨率查看且无新版面问题，其余40页图像与此前全页审查完全一致。没有新增数字。

采用bundled LibreOffice渲染及原生OOXML检查，没有在Microsoft Word中交互验收；不将旧报告或封存v3的通过记录改写成此次记录。另行生成的[匿名分发候选](../../../deliverables/support/CACR2026EA16XZ-aris-20261008/README.md)保留同一科学范围修正，真实签署与回执另行完成。
