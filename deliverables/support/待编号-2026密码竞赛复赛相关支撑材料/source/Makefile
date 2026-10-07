# 兼容入口；所有编译和测试规则只在 CMake 中维护。
CMAKE ?= cmake
CTEST ?= ctest
BUILD_DIR ?= build/cmake
CMAKE_ARGS ?=
.PHONY: all configure reference vulnerable test sanitize clean
all: configure
	$(CMAKE) --build "$(BUILD_DIR)" --parallel
configure:
	$(CMAKE) -S . -B "$(BUILD_DIR)" $(CMAKE_ARGS)
reference vulnerable: configure
	$(CMAKE) --build "$(BUILD_DIR)" --target $@ --parallel
test: all
	$(CTEST) --test-dir "$(BUILD_DIR)" --output-on-failure
sanitize:
	$(CMAKE) --preset sanitize
	$(CMAKE) --build --preset sanitize --parallel
	$(CTEST) --preset sanitize
clean:
	$(CMAKE) --build "$(BUILD_DIR)" --target clean
