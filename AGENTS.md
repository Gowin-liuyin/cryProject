# A1-13 长期工程约定

- 本仓库直接在 `main` 开发；不新建开发分支，不自动 push，不强制重置、覆盖用户修改或改写历史。
- 开工先读适用 AGENTS.md、README、方案和构建配置，检查状态、远端、身份及真实环境；工作环境和目录以文末「工作环境与工作目录」为准。复用有效实现。代码发现优先使用可用的知识图谱工具，不足时回退文本搜索。
- 作者和提交者名称均为 `Gowin-liuyin`；邮箱必须来自账号已验证邮箱或设置中显示的 noreply 邮箱，只设置本仓库配置。无法确认时先询问，不能冒用身份。
- 按模块执行“实现 → 必要检查 → 检查 diff → commit”，完成即提交，再进入下一模块。每次提交核对 main、作者、提交者、邮箱及 hash。只暂存本模块文件；修复使用新提交。
- 参考项目镜像的 `sources/` 为只读，不编辑、移动、删除同步资料。工程只在本仓库根目录维护。
- 本阶段交付 C11、ML-KEM-768 的可运行参赛作品：原生参考验收、有限比较、历史防御案例审计、统计验证、复算、离线展示、官方报告与匿名支撑包。CMake/CTest 为唯一构建与测试配置来源；根 Makefile 只做兼容转发。核心算法、CLI、生成器、测试、计时、统计与运行校验均用 C；不建立通用统计平台、云服务、网络攻击、密钥恢复、STM32 或多算法框架。
- 自有函数、变量、字段采用明确的 snake_case；宏采用 UPPER_SNAKE_CASE。数量、长度、时间标明语义和单位，循环索引也须见名知意。避免 a/b/i/n/tmp/buf/pk/sk/ct/ss 等含糊缩写。
- 注释只用必要、简短、自然的中文，说明原因、边界和故意保留的实验缺陷；不逐行翻译。上游快照不改名、不修改，保留许可证；自有补丁单独维护。
- 固定第三方完整提交号/摘要、许可证、标准口径和构建条件。旧 Kyber 不冒称 FIPS 203；人工机制回归须明示。
- 缺陷变体只改变有来源的目标时序机制，保持密码语义和隐式拒绝；禁止 sleep、随机延迟、空转、秘密输出、跳过重加密验证、固定拒绝密钥或未定义行为。
- 普通运行用系统安全随机源并处理失败；确定性入口仅供明确的测试场景。错误状态不得泄露内部验证结果。长度/空指针先在封装层检查，短缓冲区不得传给固定长度内核。
- 参考/缺陷构建隔离，核对实际链接和调用路径。独立公开 KAT、不正确长度、篡改/随机密文、两版本等价及适用 sanitizer 均按模块验证。不用自产预期答案证明自身正确。
- 计时在 C 中覆盖完整解封装；输入生成、分配、结果消费、日志和 I/O 在窗口外。保存逐次原始值、可复现类别乱序、时钟及单位，不删普通长尾。
- 记录源版本、未提交改动摘要、编译器、选项、真实机器、二进制摘要及反汇编。动态检查产物与正式采集产物分开。
- 分别报告功能正确、源码秘密依赖、产物机制、原始数据、观察差异及正式统计确认；缺证据不升级声明。macOS/ARM、交叉编译或模拟器不能冒充真实 x86_64 Linux 实测。
- 原始六模块不重建。推进顺序为官方材料与验收表、固定原生快照、有限批次路线收口、防御案例、固定改进合同、受控验证、产品入口、干净复算、报告、演示及匿名包。维护 docs/full-work-progress.md；分别记录软件完成、实验执行、假设成立和竞赛验收，缺证据不签收。
- 自有代码格式遵循 .clang-format、.cmake-format.json、.editorconfig 和 docs/style.md；C 分支/循环必须带大括号，单变量声明，不压缩多条语句。格式提交与功能修复分别验证；提交前运行 format-check，禁止格式化 vendor、固定向量和已封存证据。

## 工作环境与工作目录

三套环境各有固定根目录。代码和文档只在本仓库改。Linux 实测按机器落到下面的目录，拉回的副本放进对应的 `docs/evidence/` 子目录。口令和私钥内容不写入仓库、证据或命令记录。身份文件只记录路径。

- 用户已明确授权两台云端主机直接使用密码交互登录。仅在实际 SSH/sudo 密码提示出现后通过终端输入，不要求用户重复代输；密码认证仍须先通过主机身份核验，不能用它跳过已变化的主机密钥检查。

### 云端文件的唯一存放边界（2026-10-09用户明确约定）

- 当前云端主机为 `nss-marker@10.144.144.5`。本项目全部云端文件的唯一存放根是 `/home/nss-marker/yhr/Cry`，只能使用该目录及其子目录，`yhr`下其他位置也不使用。源码、输入、构建、实验结果、证据副本、归档、日志、缓存、临时工作及恢复快照都遵守此边界；真实落盘路径不得通过符号链接越出 `Cry`。
- 不在其他云端目录新建本项目的工作文件，包括 `/tmp`、`/run`、用户主目录的其他位置及旧KVM工作根。辅助工具产生的项目文件也须纳入路径核查；依赖边界外项目文件的旧方案先停止使用并改方案，不能仅以“临时文件”作为例外。
- 用户已明确授权：若发现本项目以前存放在 `/home/nss-marker/yhr/Cry` 外的内容，先搬回 `Cry` 下的新归档或工作目录，核对来源、文件清单和摘要，确认迁移完整后再删除旧位置副本。迁移前检查相关任务是否仍在运行；只处理确认属于本项目的内容，不按模糊名称删除他人文件或系统文件。
- 保存旧路径到新路径的映射及迁移/校验/删除结果，不改写原始证据内容。下文其他云端路径只作为历史记录，不再构成新建或继续使用这些路径的授权。本机仓库和 `build/` 不属于此云端路径限制。
- 远端运行测试前同时检查环境临时目录和源码中的显式临时路径；仅设置 `TMPDIR` 不能修正旧测试中硬编码的 `/tmp`。未满足上述路径边界的旧测试或快照不在云端执行。

### 本机：仓库根目录

- 当前克隆是 `/Users/yin/code/cryProject`。换机器后仍以该克隆的根目录为工程目录，远端 `https://github.com/Gowin-liuyin/cryProject.git`，分支 `main`。
- 源码、文档和提交都在这个根目录完成。本地构建在 `build/`，CMake 预设产物在 `build/cmake`。`build/` 只供本机编译，不作为证据。
- 这台机器是 Apple Silicon 上的 macOS。这里的编译和计时记为 macOS/ARM。
- `sources/` 只读。已封存证据和已提交的 `docs/evidence/` 记录不就地改写。

### KVM：`/home/ubuntu/cryproject-a113-20261007`

- SSH 别名 `cryproject-native-x86`，地址 `ubuntu@119.45.121.134`，端口 22，身份文件 `/Users/yin/.ssh/id_ed25519`。
- 2026-10-08 预检：主机名 `VM-0-17-ubuntu`，Ubuntu 24.04.4，Linux 6.8.0-138-generic，x86_64，`systemd-detect-virt=kvm`，4 vCPU，内存 7806156 kB。GCC 13.3.0、Clang 18.1.3、CMake 3.28.3、Ninja 1.11.1。客户机没有可配置的 cpufreq，物理频率在这台机器上不能锁定。
- 持久工作根目录是 `/home/ubuntu/cryproject-a113-20261007`。源码按提交放在 `source-<短提交号>/`，一次运行的构建和输出放在 `runs/<名称>/`。新运行新建子目录，保留已有的 `source-*` 和 `runs/*`。
- 2026-10-08 有两处已经结束的临时目录，构建树没有留在持久根目录：R07 是 `/tmp/cryproject-r07.G6Vreo`，封存包代理重跑是 `/tmp/cryproject-author-proxy-20261008.kSvlwt`。下次工作使用持久根目录下的新子目录。拉回副本分别是 `docs/evidence/r07-linux-20261008` 和 `docs/evidence/author-proxy-v3-20261008`。

### 裸金属：`/home/nss-marker/yhr/Cry`

- 登录命令是 `ssh nss-marker@10.144.144.5`。本机 `~/.ssh/config` 里的 Host `nss-marker-cloud` 指向 `10.144.144.3`；连这台裸金属时写完整地址 `10.144.144.5`。
- 2026-10-08 预检：主机名 `nss-m`，Ubuntu 24.04.4，Linux 6.17.0-35-generic，x86_64，`systemd-detect-virt=none`，AMD Ryzen 9 9950X，32 线程，内存 63385244 kB。调速器保持 `powersave`，记录中的 `frequency_control=not_configured`。GCC 13.3.0、Clang 18.1.3、CMake 3.28.3。
- 工作根目录是 `/home/nss-marker/yhr/Cry`。2026-10-08 这次的目录是：
  - `source/`：源码，提交 `a5340330f4d647c850f15329ef6bb7615c7d88ea`。普通 `audit` 构建在 `source/build/cmake`。
  - `run/build-mechanism`：机制计时构建，GCC、RelWithDebInfo、sanitizer 关闭、`A113_ARCHIVED_CASE_ONLY=OFF`。
  - `run/mechanism`：四变体机制 CSV 与分析报告。
  - `run/performance`：普通性能。`run/collect`：短演示。`run/calibrate`：有限模型。`run/reference-label-control`：后赋标签。`run/replay`：封存历史重放。
- 拉回副本是 `docs/evidence/baremetal-ryzen-20261008`，单独存放，不并入 `docs/evidence/r07-linux-20261008`。这些记录不是频率锁定、恒时证明或竞赛签收。下次新跑仍以 `/home/nss-marker/yhr/Cry` 为根，另建子目录，保留这次的 `source/` 和 `run/`。
- 2026-10-10单核分区管理预演：固定源码上传/自检在 `Cry/partition-source-c4bb88a` 和 `Cry/partition-source-b0fd479`；前者前置解析拒绝，后者是提交 `b0fd4797d44d5d79cd0aec84b3996cc5473c190a`。root私有原件在 `Cry/core-partition-20261010-44fee52e576a`，可读归档为同级同名 `.tar`，锁在 `Cry/partition-admin.lock`。以上均在唯一存放边界内，保留原件。
- 此次仅执行normal和controller单进程SIGKILL两条空任务恢复路径；临时内核分区已删除，CPU0—31归还、原四进程不存在、锁空闲，SSH已关闭。记录在 `docs/evidence/core-partition-20261010`。它不表示当前仍独占、频率已锁定、guard自身死亡可恢复或R02/R04已签收；旧依赖 `/run` 工作文件的方案仍禁用。
- 2026-10-10反馈读取准备与原件：`Cry/feedback-reader-eed81a7/` 保存固定C源、独立工具、普通/动态构建与两次分开的静态解码；完整导出为同级 `feedback-reader-eed81a7-results.tar`。root私有固件及计数原件分别为 `Cry/feedback-mapping-20261010-62ce88b02a82/`、`Cry/feedback-counter-20261010-16ec7cf0d5fb/`，可读归档为同级同名 `.tar`。均保留，不覆盖复用。
- 本次普通C源为 `eed81a7620a1c929c52e96acb203104917ec3b5d`，root封装为 `acbbd699a4e4e4606a4150ed75e448e0eb688124`；实际仅六次只读MSR，未写调频或隔离配置。结束回读仍为根CPU0—31、隔离空、目标原min/max/EPP/boost；SSH已关闭。证据在 `docs/evidence/frequency-reader-20261010`，不构成活动频率窗口、恒频或R02/R04签收。
- 2026-10-10频率请求恢复G1：固定管理源 `991f1546c7ee3a7999d6e0b7118d35211a501dfe` 的源码/软件检查在 `Cry/frequency-source-991f154/`；root私有原件在 `Cry/core-frequency-20261010-d05b4396f082/`，同级同名 `.tar` 为可读归档。仅true及normal/controller单进程SIGKILL两路径，policy2/18四个min/max曾请求4300000，随后明确重发原请求并核对全部32策略/global可见原值、六原PID不存在、根0—31/隔离空/锁释放。原件保留，不覆盖复用；不证明隐藏QoS逐位原状、work严格排空或恒频。
- 下一阶段C11窗口候选固定源 `7e93048f3af885d14f1577b3a198bd3d52b8ee8e` 的源码、普通/动态构建及软件检查在 `Cry/window-source-7e93048/`，完整导出为同级 `window-source-7e93048-software.tar`。每配置2/2已通过；普通入口/MSR/长worker尚未运行。本轮两模块的真实临时和缓存均在各树内，主SSH已关闭。证据分别在 `docs/evidence/frequency-control-20261010`、`docs/evidence/frequency-window-20261010`，R02/R04仍部分签收。
- 2026-10-10后续窗口候选补入C入口自身转储禁用与回读，固定源 `c0e5990bd4d764fbb08ff6857a2cf6cf21c9b8a2`。新树 `Cry/window-source-c0e5990/` 及同级 `window-source-c0e5990-software.tar` 保留普通/动态构建，Linux各3/3软件检查已通过，正式普通ELF摘要 `023f56460a8dc4971e8132a22c5734ca0844314d3d71b8bc3b129a424e9ee69b`。本次软件预检未执行无参入口、MSR或G2长负载；新合同见 `docs/research/aris-frequency-window-20261010/EXPERIMENT_PLAN.md`，原7e树及证据不改。
- 2026-10-10 G2管理与分析准备：管理源 `0ba4cd7c1f41c700a7fdef2b277cbf7f39e74bac`、分析源 `dd67390f1e41d76624bf3a8854feacacfb8d1f85`；源码、Linux管理自检与分析普通/动态构建在 `Cry/window-management-0ba4cd7/`，完整导出为同级 `window-management-0ba4cd7-software.tar`。三组CTest各1/1，尚无实际长窗口；新 `run-window` 仅用新 `Cry/core-window-20261010-<nonce>` 原件，不复用旧根。冻结准备见 `docs/evidence/frequency-window-20261010/g2-preparation/`。
- 2026-10-10 G2实际两路径完成：root私有原件在 `Cry/core-window-20261010-51d37af52b90/`，同级同名 `.tar` 保留87份原件。normal保存126528调用，parent-loss运行中注册取消并回收，空输出保持未知；两case仅四min/max请求后明确恢复，结束六原PID不存在、32策略/global等原基线、CPU0—31归还、隔离空、自有组删除、锁释放，主SSH已关闭。C离线分析与独立全量核对确认200个CPU2主pair通过工程规则，纯主平均窗口几何覆盖99.4948%；不是整段或逐调用恒频／物理精度／统计认证，R02/R04仍部分。实际副本见 `docs/evidence/frequency-window-20261010/run-0ba4cd7/`，不得覆盖或并入旧G1证据。

R02 与 R04 仍为部分签收：已有单进程反馈工程窗口数据，尚无整段或逐调用恒频、适用短调用精度及真实密文总体误报率或检出率的完整证据。
