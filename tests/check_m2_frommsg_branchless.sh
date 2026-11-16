#!/bin/sh
# 判定 M2 已修臂 poly_frommsg 是否仍含“以 bt/test/testb 判据驱动的条件跳转”。
# 黑名单式判据（写死）：只有紧邻 bt/test/testb 的条件跳转计为秘密条件跳转；
# 立即数计数循环退出（cmp $imm 后的 je/jne）与无条件 jmp 不计。
# 用法：check_m2_frommsg_branchless.sh --elf <path>
# 退出码：0 无秘密条件跳转；1 存在秘密条件跳转或无法判定；2 用法错误。
set -eu

symbol_name="pqcrystals_kyber768_ref_poly_frommsg"
elf_path=""

if [ "$#" -eq 2 ] && [ "$1" = "--elf" ]; then
    elf_path=$2
elif [ "$#" -eq 0 ]; then
    printf 'usage: check_m2_frommsg_branchless.sh --elf <path>\n' >&2
    exit 2
else
    printf 'usage: check_m2_frommsg_branchless.sh --elf <path>\n' >&2
    exit 2
fi
if [ ! -f "$elf_path" ]; then
    printf 'error: missing ELF: %s\n' "$elf_path" >&2
    exit 1
fi

disassembly=$(objdump -d --no-show-raw-insn --disassemble="$symbol_name" "$elf_path") || {
    printf 'error: objdump failed for %s\n' "$elf_path" >&2
    exit 1
}

printf '%s\n' "$disassembly" | awk -v elf_path="$elf_path" -v symbol_name="$symbol_name" '
    BEGIN {
        in_symbol = 0
        symbol_found = 0
        last_flag_setter = ""
        bt_count = 0
        test_count = 0
        conditional_jump_count = 0
        secret_conditional_jump_count = 0
    }
    /^[0-9a-f]+ <.*>:/ {
        if (in_symbol) {
            in_symbol = 0
        }
        if (index($0, "<" symbol_name ">:")) {
            in_symbol = 1
            symbol_found = 1
        }
        next
    }
    in_symbol {
        instruction = $0
        sub(/^[[:space:]]*[0-9a-f]+:[[:space:]]*/, "", instruction)
        split(instruction, tokens, /[ \t]+/)
        mnemonic = tokens[1]
        if (mnemonic == "") {
            next
        }
        if (mnemonic == "bt" || mnemonic == "btl" || mnemonic == "btq") {
            ++bt_count
            last_flag_setter = "bt"
        } else if (mnemonic == "test" || mnemonic == "testb" || mnemonic == "testl" ||
                   mnemonic == "testq" || mnemonic == "testw") {
            ++test_count
            last_flag_setter = "test"
        } else if (mnemonic ~ /^j/) {
            if (mnemonic != "jmp") {
                ++conditional_jump_count
                if (last_flag_setter == "bt" || last_flag_setter == "test") {
                    ++secret_conditional_jump_count
                }
            }
            last_flag_setter = ""
        } else if (mnemonic ~ /^(cmp|cmpb|cmpw|cmpl|cmpq|sub|add|and|or|xor|inc|dec|shl|shr|sar|sal|neg|not|imul|mul|adc|sbb)$/) {
            last_flag_setter = "other"
        } else {
            last_flag_setter = ""
        }
    }
    END {
        printf "platform_m2_poly_frommsg_branchless: elf=%s\n", elf_path
        printf "  symbol=%s found=%d bt_count=%d test_count=%d conditional_jumps=%d\n",
            symbol_name, symbol_found, bt_count, test_count, conditional_jump_count
        printf "  secret_conditional_jumps=%d\n", secret_conditional_jump_count
        if (!symbol_found) {
            printf "verdict=symbol_not_found\n"
            exit 1
        }
        if (secret_conditional_jump_count != 0) {
            printf "verdict=secret_branch_present\n"
            exit 1
        }
        printf "verdict=branchless\n"
        exit 0
    }
'
