# A1-13 ML-KEM C 实验基线

当前完成模块一：固定 mlkem-native 便携 C 库、ML-KEM-768 和隔离构建目录。

```sh
make
make reference
make vulnerable
make BUILD_DIR=build-clean
```

此阶段 vulnerable 目标仅预留独立构建入口，尚无缺陷行为差异；不代表已复现漏洞。
来源和平台边界见 [docs/sources.md](docs/sources.md)。后续模块将接入功能测试、
机制回归、CLI 和逐次计时。
