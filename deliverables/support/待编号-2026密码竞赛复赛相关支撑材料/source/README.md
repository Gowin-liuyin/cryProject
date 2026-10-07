# A1-13 本地审计与复算工程

对象ML-KEM-768、C11、Linux/macOS、GCC/Clang；CMake3.21+、Git工具、patch、shasum、OpenSSL为依赖。
源码导出不含.git，SOURCE_EXPORT.sha256验证构建输入；标识是导出摘要而非Git提交。
原库和独立NIST向量/许可证保持字节，第三方来源和名字不因匿名删除。

```sh
cmake --preset baseline
cmake --build --preset baseline --parallel 4
build/cmake/audit version
build/cmake/audit check
mkdir -p runs
build/cmake/audit collect demonstration 2026100703 20 runs/new-live
build/cmake/audit replay "$PWD" "$PWD/runs/new-history-replay"
build/cmake/audit performance-replay docs/evidence/native-final-20261007/performance runs/new-performance.report
build/cmake/audit analyze-pairs docs/evidence/controlled-comparison-20261007/confirmation-data/task-2.csv docs/evidence/controlled-comparison-20261007/confirmation-data/task-2.plan runs/new-exact.report
```

短采集不替代正式样本；历史重分析不重新采集。默认仅归档机制模式，旧主动时序集成脚本不在本分发包。
普通性能的源与数据身份固定在其原副本；后续复算器不回填为被测程序。
资料未证明全库恒时、新受控防护闭环或非原作者签收。编号及真实签署由团队完成。
SciPy只作已冻结的外部强对照；重建相同精确判定不依赖Python。
