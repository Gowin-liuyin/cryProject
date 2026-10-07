# 历史防御案例只读核验

本目录核对历史multiseed、mitigation、deployable和NIST向量完整SHA清单，均成功。
frozen-source-diff.txt为空：相对开工c4f26db，上游、固定向量、原人工补丁及指定封存数据未改。
replay-40-reports.log由C audit调用两套原分析器，只读20份CSV重建40份报告，全部逐字一致。
这是作者复算，不是新时序实验、第三方签收或误报校准。

四版功能、等价与隐式拒绝在macOS相关测试及native-final-20261007的GCC普通/Clang动态
31项中核验。源码、旧实际产物、旧观察及新静态对象的身份分开，说明见defensive-case.md。
R05–R07仍缺新的受控机制前后数据和因果分离，不由这里的成功日志自动签收。
