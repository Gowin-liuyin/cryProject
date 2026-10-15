# M3 完整解封装人工 LUT 校准

本模块与早先独立 `fixtures/mem_lut_leak` 分开：这里实际调用完整 ML-KEM-768 解封装，
只在构建 overlay 的重加密消息编码中人工加入秘密地址。不是上游漏洞，不用于保护真实秘密。

`docs/patches/m3-mem-lut-toggle.patch` 改写 `mlk_poly_frommsg`，开版的消息位直接索引
64 字节分隔的 `{0,1665}` 系数表，读值成为实际多项式系数；关版采用上游值屏障与掩码选择。
`volatile` 保留实际 load；两版保持原重加密比较、拒绝种子与全部数学输出，不设置函数级 O0。
算法依据是既有上游函数中的 FIPS 203 `Decompress_1` 映射，不把人工补丁冒充官方修复。

```sh
cmake -S . -B build/platform-m3-s6/ordinary -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF
cmake --build build/platform-m3-s6/ordinary --target platform_m3 platform_m3_check --parallel 4
```

可执行文件位于 `platform-m3/on/{baseline,measure}` 与 `platform-m3/off/{baseline,measure}`；
库与源码 overlay 各自独立。`measure` 只构建，统计草案未冻结前不执行。
已有 NIST KAT/接口边界与随机源失败每版复用；新等价测试对 64 个**公开固定种子**、
五类输入分别生成完整公钥、测试私钥、密文和解封装值，在 CTest 构建临时目录逐字比较
reference/on/off 三份测试转录。这个专用测试不接收运行密钥，不作为产品输出或计时记录；
拒绝类另验证 `J(z||c)`。原始向量答案来自独立 NIST 数据。

Linux 安装标准 Valgrind 头后配置 `-DPLATFORM_M3_CTGRIND=ON`，新增完整解封装探针：

```sh
valgrind --tool=memcheck --track-origins=yes --error-exitcode=97 ./platform_m3_on_probe --secret
valgrind --tool=memcheck --track-origins=yes --error-exitcode=97 ./platform_m3_off_probe --secret
valgrind --tool=memcheck --error-exitcode=97 ./platform_m3_on_probe --defined
valgrind --tool=memcheck --error-exitcode=97 ./platform_m3_off_probe --defined
```

探针标记 1152 字节秘密 PKE 多项式与最后 32 字节拒绝种子，嵌入的公开封装键/哈希保持 defined；
运行后恢复标记再消费状态。每次完整跑五类公开人工输入；不输出运行秘密或内部验证结果。
探针未在 Valgrind 下运行返回 77，不能用普通运行冒充定位。

云端源码、构建、测试转录、日志、缓存、临时目录与归档必须都在 `/home/nss-marker/yhr/Cry`
的新物理子树；不能用默认 Docker 存储启动 Microwalk。工具缺失与降级依据见本轮证据 NOTES。
