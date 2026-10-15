# 兼容入口；所有编译和测试规则只在 CMake 中维护。
CMAKE ?= cmake
CTEST ?= ctest
BUILD_DIR ?= build/cmake
# 显式并行度：`--parallel` 不带数字时依赖 jobserver，而 jobserver 描述符过不了
# `cmake --build`（子 make 拿不到，退回 -j1 并打印 "jobserver unavailable" 警告）。
# 所以并行度只由这里给出，调用 make 时不必再加 -j。
BUILD_JOBS ?= 4
CMAKE_ARGS ?=
.PHONY: all configure reference vulnerable test sanitize clean
# 递归调用的 recipe 前清空 MAKEFLAGS：否则子 make 会看到父 make 的 jobserver 标记
# 却拿不到描述符，在 `make -j4` 下重新打印同一条警告。不用 `+` 前缀是因为它会让
# `make -n` 真的执行编译；这里不依赖 jobserver，不需要 `+`。
all: configure
	MAKEFLAGS= $(CMAKE) --build "$(BUILD_DIR)" --parallel $(BUILD_JOBS)
configure:
	$(CMAKE) -S . -B "$(BUILD_DIR)" $(CMAKE_ARGS)
reference vulnerable: configure
	MAKEFLAGS= $(CMAKE) --build "$(BUILD_DIR)" --target $@ --parallel $(BUILD_JOBS)
test: all
	$(CTEST) --test-dir "$(BUILD_DIR)" --output-on-failure
sanitize:
	$(CMAKE) --preset sanitize
	MAKEFLAGS= $(CMAKE) --build --preset sanitize --parallel $(BUILD_JOBS)
	$(CTEST) --preset sanitize
clean:
	MAKEFLAGS= $(CMAKE) --build "$(BUILD_DIR)" --target clean
