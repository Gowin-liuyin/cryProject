# Linux测试临时目录辅助程序核验

2026-10-10在已确认的裸金属nss-m执行，Linux 6.17.0-35-generic、x86_64、GCC 13.3.0、CMake 3.28.3，机器及版本原件见[日志](logs/uname.txt)。这是文件路径的软件检查，不是密码计时或正式统计实验。

源码固定于1faf87d87ecec7650cb64fac94228fdfbf3268d2。仅导出CMake所需的208个文件，无.git；[回读记录](readback.json)中的逐文件摘要与本机该提交归档完全一致，归档SHA256为689eb4913c054c0586da0bec44a5579d7b95f2dd69f4c6da512bec6a4b506603。导出目录不冒称完整Git工作树。

全部项目文件保留在`/home/nss-marker/yhr/Cry/temp-check-1faf87d`：source、两份build、compiler-tmp、logs、源码归档及运行回执均在此根。配置和编译前指定TMPDIR/TMP/TEMP，CTest再指定各build/test-tmp的四个变量；真实路径核对均在Cry内，运行树无符号链接，最终两份test-tmp及compiler-tmp为空。SSH连接已关闭。

实际只构建test_temp_directory：[普通构建](logs/build-gcc-build.log)、[动态检查构建](logs/build-gcc-san-build.log)均只有该辅助程序的编译和链接。[普通CTest](logs/build-gcc-ctest.log)1/1、[ASan/UBSan CTest](logs/build-gcc-san-ctest.log)1/1通过。回执保存真实编译、链接参数及两个原始ELF摘要，拉回的[普通ELF](artifacts/helper-gcc.elf)及[动态检查ELF](artifacts/helper-gcc-san.elf)均逐字节核对一致。没有构建密码库或变体补丁，没有运行其他34项测试、机制计时或统计确认。

[执行脚本](../../research/test-temp-linux-20261010/run.sh)字节摘要与实际远端执行件一致；[回读脚本](../../research/test-temp-linux-20261010/readback.py)检查来源、产物、环境及目录边界。CMake仍会生成其他目标的规则和构建目录内源码副本，这不表示那些目标已编译或执行。软件检查不能替代R02/R04的科学资格，也不能解决旧KVM的主机身份核验。

独立同模型代理只读审查通过：逐项从Git取回208个blob核对归档及回执，静态检查两ELF均为x86_64 PIE；动态检查件实际依赖libasan.so.8和libubsan.so.1并含检测符号。实际日志各仅一项、四环境变量正确、15项清单核验通过。代理未连接远端或运行ELF；这是内部独立检查，不冒称外部同行评审。
