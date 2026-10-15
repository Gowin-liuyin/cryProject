# jobserver 变体矩阵（Unix Makefiles 生成器，另附 Ninja 对照）。
# cur            : 修改前的写法（无 `+`，`--parallel` 不带数字）
# plus_bare      : 只加 `+`，`--parallel` 不带数字（GNU make 官方建议的修法）
# plus_jobs      : `+` + 显式 `--parallel 4`
# makeflags_clear: 仓库当前采用的修法（recipe 前清空 MAKEFLAGS + 显式 `--parallel 4`，不加 `+`）
# ninja_plus     : 改用 Ninja 生成器 + `+` + 显式 `--parallel 4`
# ninja_plain    : 改用 Ninja 生成器 + 显式 `--parallel 4`（无 `+`）
CMAKE ?= cmake
BUILD_JOBS ?= 4

cur:
	$(CMAKE) --build "build" --parallel

plus_bare:
	+$(CMAKE) --build "build" --parallel

plus_jobs:
	+$(CMAKE) --build "build" --parallel $(BUILD_JOBS)

makeflags_clear:
	MAKEFLAGS= $(CMAKE) --build "build" --parallel $(BUILD_JOBS)

ninja_plus:
	+$(CMAKE) --build "build-ninja" --parallel $(BUILD_JOBS)

ninja_plain:
	$(CMAKE) --build "build-ninja" --parallel $(BUILD_JOBS)
