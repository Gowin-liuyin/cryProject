# 统计电池摘要

- CI/Welch：见 ci_welch.json；95% 正态近似区间、双侧正态近似 p，非精确 Student t 分布。
- RTLF：unavailable；α=0.01；固定 bootstrap 种子 2026101605；退出码 not_run。
- dudect 离线回放：unavailable；用原上游统计内核，输入 ns，无新采数，不等同于在线 rdtsc 检测。
- dudect 在线日志：unavailable；导入日志只保全原文，需单独核对来源、环境、预算。
- 原始 CSV 完整保留；主 CI 与 RTLF 无删尾。上游 dudect 自带预热、端点丢弃、裁剪与高阶检验单列记账。
- 不自行生成 Holm 家族；dudect 不进 Holm。不显著或工具不可用不构成恒时证明。
