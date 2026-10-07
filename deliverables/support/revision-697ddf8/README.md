# 最新匿名支撑材料

本修订包含普通CSV/meta/cost的共同资格校验及真实失败用例。修复源697ddf8，验证记录见
docs/evidence/ordinary-cost-validation-20261007。早先支撑包保持为旧快照，交付采用本目录的ZIP。
正式作品编号、题名和人员信息继续占位；正式提交前由团队完成编号重命名及签署。

压缩包：`待编号-2026密码竞赛复赛相关支撑材料.zip`，约7.24MB，完整性及隐私检查见
submission-verification.json；SHA256SUMS使用本目录为工作目录核对。

```sh
shasum -a 256 -c SHA256SUMS
unzip 待编号-2026密码竞赛复赛相关支撑材料.zip
cd 待编号-2026密码竞赛复赛相关支撑材料/source
cmake --preset baseline
cmake --build --preset baseline --parallel 4
build/cmake/audit version
build/cmake/audit check
mkdir -p runs
build/cmake/audit replay "$PWD" "$PWD/runs/new-history"
build/cmake/audit performance-replay docs/evidence/native-final-20261007/performance runs/new-performance.report
```

解压后打开顶层index.html，可查看证据、修订说明及本包源码实际生成的60条普通短演示。
包中保留108份原始数字CSV字节；身份/路径/自有版本角色转换另作声明。匿名复算报告与
包内转换后的归档报告逐字核对，数值保持；不将角色转换后的元数据冒称内部原始字节。
源码以SOURCE_EXPORT.sha256验证，没有.git。展开目录是ZIP的本地副本，不另外维护源码。

全新匿名源32项检查通过，40历史报告、普通性能及精确成对报告复算一致。原生固定提交的
GCC及Clang动态检查也各32项通过；同一成品ZIP在原生Linux实际解压及全新GCC32项通过，
并重建全部上述报告。记录见docs/evidence/anonymous-cost-revision-20261007，仍为作者代理。
功能、证据完整性和研究结论分别签收：没有重新采集
正式秘密机制时序，没有关闭科学因果、校准或非原作者执行缺口。报告DOCX/PDF沿用已验证
版本，既有实验数值和结论范围保持。真实界面截图仍待团队手工补充。
