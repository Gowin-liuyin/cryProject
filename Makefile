CC = cc
AR ?= ar
BUILD_DIR ?= build
CFLAGS ?= -O2 -g
CPPFLAGS += -Iinclude -Ivendor/mlkem-native/mlkem -DMLK_CONFIG_FILE='"baseline_config.h"'
WARNINGS = -std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror
VENDOR_FILES := $(shell find vendor/mlkem-native/mlkem -type f)
.PHONY: all reference vulnerable clean
all: reference vulnerable
reference: $(BUILD_DIR)/reference/libmlkem.a
vulnerable: $(BUILD_DIR)/vulnerable/libmlkem.a
$(BUILD_DIR)/reference/kernel.o: src/kernel.c include/baseline_config.h $(VENDOR_FILES) Makefile
	mkdir -p $(@D)
	$(CC) $(CPPFLAGS) $(WARNINGS) $(CFLAGS) -c $< -o $@
$(BUILD_DIR)/vulnerable/kernel.o: src/kernel.c include/baseline_config.h $(VENDOR_FILES) Makefile
	mkdir -p $(@D)
	$(CC) $(CPPFLAGS) $(WARNINGS) $(CFLAGS) -DBASELINE_VULNERABLE=1 -c $< -o $@
$(BUILD_DIR)/%/libmlkem.a: $(BUILD_DIR)/%/kernel.o
	$(AR) rcs $@ $<
clean:
	rm -rf $(BUILD_DIR)

APP_SOURCES = src/mlkem.c src/random.c
$(BUILD_DIR)/reference/test_mlkem: tests/test_mlkem.c $(APP_SOURCES) include/mlkem.h $(BUILD_DIR)/reference/libmlkem.a
	$(CC) $(CPPFLAGS) $(WARNINGS) $(CFLAGS) tests/test_mlkem.c $(APP_SOURCES) $(BUILD_DIR)/reference/libmlkem.a -o $@
$(BUILD_DIR)/vulnerable/test_mlkem: tests/test_mlkem.c $(APP_SOURCES) include/mlkem.h $(BUILD_DIR)/vulnerable/libmlkem.a
	$(CC) $(CPPFLAGS) $(WARNINGS) $(CFLAGS) -DBASELINE_VULNERABLE=1 tests/test_mlkem.c $(APP_SOURCES) $(BUILD_DIR)/vulnerable/libmlkem.a -o $@
.PHONY: test-reference test
 test-reference: $(BUILD_DIR)/reference/test_mlkem
	$(BUILD_DIR)/reference/test_mlkem tests/vectors/mlkem768.txt
test: test-reference $(BUILD_DIR)/vulnerable/test_mlkem
	$(BUILD_DIR)/vulnerable/test_mlkem tests/vectors/mlkem768.txt
