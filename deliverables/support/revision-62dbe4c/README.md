# 最新匿名支撑材料

本目录ZIP约7.54MB，包含普通成本资格修复、有限模型校准、最新源码及演示。
本轮固定模型源为62dbe4c，另含a69368f边界自检；实际分发源以SOURCE_EXPORT.sha256标识，
不是Git提交。早先支撑包保持为旧快照，最新交付采用本目录文件。

```sh
shasum -a 256 -c SHA256SUMS
unzip 待编号-2026密码竞赛复赛相关支撑材料.zip
cd 待编号-2026密码竞赛复赛相关支撑材料/source
cmake --preset baseline
cmake --build --preset baseline --parallel 4
build/cmake/audit check
mkdir -p runs
build/cmake/audit replay "$PWD" "$PWD/runs/new-history"
build/cmake/audit performance-replay docs/evidence/native-final-20261007/performance runs/new-performance.report
build/cmake/audit calibrate runs/new-finite-calibration
cmp docs/evidence/finite-calibration-20261007/model/raw.csv runs/new-finite-calibration/raw.csv
```

匿名源新构建33项通过，40历史、普通性能及精确报告与包内转换过身份的归档报告逐字一致；
40964份有限模型原始行重新生成后字节一致，所有低检出及全零保留。44份固定SciPy外部
审计已在内部固定数据上完成，其版本及报告也在包内；默认重建不依赖SciPy。
113份原始数字CSV保持字节，文本身份/路径/自有版本仅作已声明的角色转换，元数据不冒称
内部原始字节。解压后顶层index.html包含实际60条普通短演示及校准结果。

同一成品ZIP已在原生x86_64 Linux/KVM实际解压、清单核验、全新GCC33项及所有上述复算
通过；仍是作者代理，不是非原作者执行。官方报告现为12页，保留旧真实性能数值，新增
有限模型表；审批页仍占位，尚未签署。真实密码总体校准、新受控防护链、界面截图和非原作者
记录仍缺，完整Goal未完成。正式编号、人员、分工、签名与上传须按团队真实信息完成。
