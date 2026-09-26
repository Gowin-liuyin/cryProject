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
$(BUILD_DIR)/vulnerable/patched.stamp: $(VENDOR_FILES) docs/patches/message-branch.patch
	mkdir -p $(@D)
	cp -R vendor/mlkem-native/mlkem $(@D)/
	patch -d $(@D) -p1 < docs/patches/message-branch.patch
	touch $@
$(BUILD_DIR)/vulnerable/kernel.o: src/kernel.c include/baseline_config.h $(BUILD_DIR)/vulnerable/patched.stamp Makefile
	mkdir -p $(@D)
	$(CC) -I$(BUILD_DIR)/vulnerable/mlkem $(CPPFLAGS) $(WARNINGS) $(CFLAGS) -DBASELINE_VULNERABLE=1 -c $< -o $@
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

$(BUILD_DIR)/reference/test_equivalence: tests/test_equivalence.c $(APP_SOURCES) include/mlkem.h $(BUILD_DIR)/reference/libmlkem.a
	$(CC) $(CPPFLAGS) $(WARNINGS) $(CFLAGS) tests/test_equivalence.c $(APP_SOURCES) $(BUILD_DIR)/reference/libmlkem.a -o $@
$(BUILD_DIR)/vulnerable/test_equivalence: tests/test_equivalence.c $(APP_SOURCES) include/mlkem.h $(BUILD_DIR)/vulnerable/libmlkem.a
	$(CC) $(CPPFLAGS) $(WARNINGS) $(CFLAGS) -DBASELINE_VULNERABLE=1 tests/test_equivalence.c $(APP_SOURCES) $(BUILD_DIR)/vulnerable/libmlkem.a -o $@
.PHONY: test-equivalence
test-equivalence: $(BUILD_DIR)/reference/test_equivalence $(BUILD_DIR)/vulnerable/test_equivalence
	$(BUILD_DIR)/reference/test_equivalence > $(BUILD_DIR)/reference/equivalence.txt
	$(BUILD_DIR)/vulnerable/test_equivalence > $(BUILD_DIR)/vulnerable/equivalence.txt
	cmp $(BUILD_DIR)/reference/equivalence.txt $(BUILD_DIR)/vulnerable/equivalence.txt
test: test-equivalence

CLI_SOURCES = src/main.c src/inputs.c $(APP_SOURCES)
$(BUILD_DIR)/reference/baseline: $(CLI_SOURCES) include/inputs.h include/mlkem.h $(BUILD_DIR)/reference/libmlkem.a
	$(CC) $(CPPFLAGS) $(WARNINGS) $(CFLAGS) $(CLI_SOURCES) $(BUILD_DIR)/reference/libmlkem.a -o $@
$(BUILD_DIR)/vulnerable/baseline: $(CLI_SOURCES) include/inputs.h include/mlkem.h $(BUILD_DIR)/vulnerable/libmlkem.a
	$(CC) $(CPPFLAGS) $(WARNINGS) $(CFLAGS) -DBASELINE_VULNERABLE=1 $(CLI_SOURCES) $(BUILD_DIR)/vulnerable/libmlkem.a -o $@
reference: $(BUILD_DIR)/reference/baseline
vulnerable: $(BUILD_DIR)/vulnerable/baseline
.PHONY: test-cli
test-cli: all
	sh tests/test_cli.sh $(BUILD_DIR)
test: test-cli

.PHONY: FORCE
FORCE:
shell_quote = '$(subst ','"'"',$(1))'
$(BUILD_DIR)/build_identity.h: FORCE
	sh tools/build_identity.sh $@ $(call shell_quote,$(CC)) $(call shell_quote,$(CPPFLAGS) $(WARNINGS) $(CFLAGS); vulnerable encoder: optnone+noinline (Clang); O0+noinline (GCC); no LTO by default)
$(BUILD_DIR)/reference/kernel.o $(BUILD_DIR)/vulnerable/kernel.o: $(BUILD_DIR)/build_identity.h
MEASURE_SOURCES = src/measure.c src/inputs.c $(APP_SOURCES)
$(BUILD_DIR)/reference/measure: $(MEASURE_SOURCES) include/inputs.h include/mlkem.h $(BUILD_DIR)/build_identity.h $(BUILD_DIR)/reference/libmlkem.a
	$(CC) -I$(BUILD_DIR) $(CPPFLAGS) $(WARNINGS) $(CFLAGS) $(MEASURE_SOURCES) $(BUILD_DIR)/reference/libmlkem.a -o $@
$(BUILD_DIR)/vulnerable/measure: $(MEASURE_SOURCES) include/inputs.h include/mlkem.h $(BUILD_DIR)/build_identity.h $(BUILD_DIR)/vulnerable/libmlkem.a
	$(CC) -I$(BUILD_DIR) $(CPPFLAGS) $(WARNINGS) $(CFLAGS) -DBASELINE_VULNERABLE=1 $(MEASURE_SOURCES) $(BUILD_DIR)/vulnerable/libmlkem.a -o $@
reference: $(BUILD_DIR)/reference/measure
vulnerable: $(BUILD_DIR)/vulnerable/measure

$(BUILD_DIR)/test_measurement: tests/test_measurement.c src/inputs.c $(APP_SOURCES) include/inputs.h $(BUILD_DIR)/reference/libmlkem.a
	$(CC) $(CPPFLAGS) $(WARNINGS) $(CFLAGS) tests/test_measurement.c src/inputs.c $(APP_SOURCES) $(BUILD_DIR)/reference/libmlkem.a -o $@
.PHONY: test-measurement
test-measurement: all $(BUILD_DIR)/test_measurement
	sh tests/test_measurement.sh $(BUILD_DIR)
test: test-measurement
