#!/usr/bin/env python3
"""T22 每格判定器：对每个格的采集件做反汇编判定 + Memcheck 秘密标记，输出可核对的表格。

判定规则是**预注册**的（与 r09-optlevel-20261016/PLAN.md §4 逐字一致），不按结果改：

  clangover_bt_jae   : 函数体内存在 `bt`，且其后 4 条指令内紧跟条件跳转
                       （`ja/jae/jb/jbe/jc/jnc`）。这是 Clang 15–18 在
                       `-Os/-O1` 下把 `-((msg>>j)&1) & 0x681` 选成
                       "测试位 + 条件跳转" 的具体形态。
  per_bit_test_jcc   : 函数体内存在 `testb $imm,(<内存操作数>)`，且其后 2 条指令内
                       紧跟条件跳转。这是同一段源代码在 `-O2/-O3` 下被展开成
                       "每个比特一次条件跳转" 的形态。
  secret_division    : 出现 `div`/`idiv`（数据相关除法，Kyberslash 形态）。
  setcc / cmov       : 掩码物化指令计数（`set*` / `cmov*`）。
  conditional_jumps  : 函数体内条件跳转总数（含循环计数跳转，仅作对照）。

Memcheck 一列报**两类数字**：唯一错误上下文条数（contexts）与动态报错次数（errors），
口径来自 valgrind 的 `ERROR SUMMARY: N errors from M contexts`。
只统计 "Conditional jump or move depends on uninitialised value(s)" 与
"Use of uninitialised value" 两类。
"""

import argparse
import os
import re
import subprocess
import sys

JCC = {
    "ja", "jae", "jb", "jbe", "jc", "je", "jg", "jge", "jl", "jle", "jna", "jnae",
    "jnb", "jnbe", "jnc", "jne", "jng", "jnge", "jnl", "jnle", "jno", "jnp", "jns",
    "jnz", "jo", "jp", "jpe", "jpo", "js", "jz",
}
BIT_TEST_JCC = {"ja", "jae", "jb", "jbe", "jc", "jnc"}


def disassemble(elf_path, symbol):
    completed = subprocess.run(
        ["/usr/bin/objdump", "-d", "--no-show-raw-insn", "--disassemble=" + symbol, elf_path],
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        return None, completed.stderr
    instructions = []
    for line in completed.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        address_field = parts[0].strip()
        if not address_field.endswith(":"):
            continue
        if not re.fullmatch(r"[0-9a-f]+:", address_field):
            continue
        text = parts[1].strip()
        if not text:
            continue
        tokens = text.split(None, 1)
        mnemonic = tokens[0]
        operands = tokens[1] if len(tokens) > 1 else ""
        instructions.append((address_field[:-1], mnemonic, operands))
    if not instructions:
        return None, "no instructions for %s" % symbol
    return instructions, None


def classify(instructions):
    facts = {
        "instructions": len(instructions),
        "clangover_bt_jae": "no",
        "per_bit_test_jcc": "no",
        "secret_division": 0,
        "setcc": 0,
        "cmov": 0,
        "conditional_jumps": 0,
        "bt": 0,
        "mask_neg_and": 0,
        "evidence_bt_jae": "",
        "evidence_per_bit_test_jcc": "",
        "evidence_division": "",
    }
    for index, (address, mnemonic, operands) in enumerate(instructions):
        if mnemonic == "bt":
            facts["bt"] += 1
            for look_ahead in range(1, 5):
                if index + look_ahead >= len(instructions):
                    break
                candidate = instructions[index + look_ahead][1]
                if candidate in BIT_TEST_JCC:
                    facts["clangover_bt_jae"] = "yes"
                    facts["evidence_bt_jae"] = "%s: %s %s -> %s: %s" % (
                        address,
                        mnemonic,
                        operands,
                        instructions[index + look_ahead][0],
                        candidate,
                    )
                    break
        if mnemonic in ("div", "idiv") or mnemonic.startswith("div") or mnemonic.startswith("idiv"):
            facts["secret_division"] += 1
            facts["evidence_division"] += "%s: %s %s; " % (address, mnemonic, operands)
        if mnemonic.startswith("set"):
            facts["setcc"] += 1
        if mnemonic.startswith("cmov"):
            facts["cmov"] += 1
        if mnemonic in JCC:
            facts["conditional_jumps"] += 1
        # 掩码惯用法：先做"取负"再做 and。
        # -O2/-O3 生成 `neg`；-O0 生成等价的 `xor %r,%r; sub`，这里两种都算。
        is_negation = mnemonic == "neg"
        if mnemonic == "xor":
            xor_operands = [operand.strip() for operand in operands.split(",")]
            is_negation = len(xor_operands) == 2 and xor_operands[0] == xor_operands[1]
        if is_negation:
            for look_ahead in range(1, 5):
                if index + look_ahead >= len(instructions):
                    break
                candidate = instructions[index + look_ahead][1]
                if candidate.startswith("and"):
                    facts["mask_neg_and"] += 1
                    break
                if candidate.startswith("sub"):
                    continue
        if mnemonic.startswith("test") and operands.startswith("$") and "(" in operands:
            for look_ahead in range(1, 3):
                if index + look_ahead >= len(instructions):
                    break
                candidate = instructions[index + look_ahead][1]
                if candidate in JCC:
                    facts["per_bit_test_jcc"] = "yes"
                    if not facts["evidence_per_bit_test_jcc"]:
                        facts["evidence_per_bit_test_jcc"] = "%s: %s %s -> %s: %s" % (
                            address,
                            mnemonic,
                            operands,
                            instructions[index + look_ahead][0],
                            candidate,
                        )
                    break
    return facts


def memcheck(probe_path, probe_arguments, raw_path):
    command = [
        "/usr/bin/valgrind",
        "--tool=memcheck",
        "--error-exitcode=0",
        "--num-callers=24",
        "--track-origins=no",
    ] + probe_path.split() + probe_arguments
    completed = subprocess.run(command, capture_output=True, text=True)
    output = completed.stdout + completed.stderr
    with open(raw_path, "w") as raw_file:
        raw_file.write(output)
    contexts = 0
    errors = 0
    summary = re.search(r"ERROR SUMMARY: (\d+) errors from (\d+) contexts", output)
    if summary:
        errors = int(summary.group(1))
        contexts = int(summary.group(2))
    conditional_contexts = len(
        re.findall(r"Conditional jump or move depends on uninitialised value", output)
    )
    uninitialised_contexts = len(
        re.findall(r"^==\d+== Use of uninitialised value", output, re.MULTILINE)
    )
    functions = sorted(
        set(re.findall(r"^\S+\s+at 0x[0-9A-Fa-f]+: ([A-Za-z_][A-Za-z0-9_]*)", output, re.MULTILINE))
    )
    return {
        "exit": completed.returncode,
        "contexts": contexts,
        "errors": errors,
        "conditional_contexts": conditional_contexts,
        "uninitialised_contexts": uninitialised_contexts,
        "functions": functions,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--report", required=True)
    arguments = parser.parse_args()

    cells = []
    for arm in ("m1unfixed", "m1fixed", "m5ref"):
        for level in ("O0", "O2", "O3", "Os"):
            cells.append(("%s-%s" % (arm, level), arm, level))

    disassembly_directory = os.path.join(arguments.root, "disasm")
    memcheck_directory = os.path.join(arguments.root, "memcheck")
    os.makedirs(disassembly_directory, exist_ok=True)
    os.makedirs(memcheck_directory, exist_ok=True)

    rows = []
    details = []
    for cell, arm, level in cells:
        cell_root = os.path.join(arguments.root, "build", cell)
        elf = os.path.join(cell_root, "measure")
        if arm == "m5ref":
            primary_symbol = "baseline_native_poly_frommsg"
            helper_symbol = None
            probe_elf = os.path.join(cell_root, "platform_m5_poison_cell")
            probe_arguments = ["--poison"]
        else:
            primary_symbol = "pqcrystals_ml_kem_768_ipd_ref_poly_frommsg"
            helper_symbol = "pqcrystals_ml_kem_768_ipd_ref_cmov_int16"
            probe_elf = os.path.join(cell_root, "historical_poison_cell")
            probe_arguments = []

        primary_instructions, error = disassemble(elf, primary_symbol)
        if primary_instructions is None:
            sys.stderr.write("%s: %s\n" % (cell, error))
            return 1
        for label, symbol, instructions in (("", primary_symbol, primary_instructions),):
            raw_path = os.path.join(disassembly_directory, "%s-%s.txt" % (cell, symbol))
            with open(raw_path, "w") as raw_file:
                subprocess.run(
                    [
                        "/usr/bin/objdump",
                        "-d",
                        "--no-show-raw-insn",
                        "--disassemble=" + symbol,
                        elf,
                    ],
                    stdout=raw_file,
                )
        facts = classify(primary_instructions)
        # 同时保留带机器码的原始转储，便于逐字节复核。
        with open(
            os.path.join(disassembly_directory, "%s-%s.raw.txt" % (cell, primary_symbol)), "w"
        ) as raw_file:
            subprocess.run(
                ["/usr/bin/objdump", "-d", "--disassemble=" + primary_symbol, elf], stdout=raw_file
            )

        helper_facts = None
        if helper_symbol is not None:
            helper_instructions, _ = disassemble(elf, helper_symbol)
            if helper_instructions is not None:
                helper_facts = classify(helper_instructions)
                with open(
                    os.path.join(
                        disassembly_directory, "%s-%s.txt" % (cell, helper_symbol)
                    ),
                    "w",
                ) as raw_file:
                    subprocess.run(
                        [
                            "/usr/bin/objdump",
                            "-d",
                            "--no-show-raw-insn",
                            "--disassemble=" + helper_symbol,
                            elf,
                        ],
                        stdout=raw_file,
                    )

        address = subprocess.run(
            ["/usr/bin/nm", elf], capture_output=True, text=True
        ).stdout
        symbol_address = ""
        for line in address.splitlines():
            fields = line.split()
            if len(fields) == 3 and fields[2] == primary_symbol:
                symbol_address = fields[0]
                break

        memcheck_facts = memcheck(
            probe_elf, probe_arguments, os.path.join(memcheck_directory, "%s.valgrind.txt" % cell)
        )

        rows.append(
            {
                "cell": cell,
                "arm": arm,
                "level": "-" + level,
                "symbol": primary_symbol,
                "symbol_address": symbol_address,
                "instructions": facts["instructions"],
                "bt": facts["bt"],
                "bt_jae": facts["clangover_bt_jae"],
                "per_bit_test_jcc": facts["per_bit_test_jcc"],
                "setcc": facts["setcc"],
                "cmov": facts["cmov"],
                "division": facts["secret_division"],
                "conditional_jumps": facts["conditional_jumps"],
                "mask_neg_and": facts["mask_neg_and"],
                "helper_cmov": helper_facts["cmov"] if helper_facts else "-",
                "helper_mask_neg_and": helper_facts["mask_neg_and"] if helper_facts else "-",
                "helper_setcc": helper_facts["setcc"] if helper_facts else "-",
                "helper_bt_jae": helper_facts["clangover_bt_jae"] if helper_facts else "-",
                "memcheck_contexts": memcheck_facts["contexts"],
                "memcheck_errors": memcheck_facts["errors"],
                "memcheck_exit": memcheck_facts["exit"],
            }
        )
        details.append(
            "cell=%s\nprimary_symbol=%s\nprimary_address=%s\n"
            "clangover_bt_jae=%s\nevidence_bt_jae=%s\n"
            "per_bit_test_jcc=%s\nevidence_per_bit_test_jcc=%s\n"
            "secret_division=%d\nevidence_division=%s\n"
            "setcc=%d\ncmov=%d\nconditional_jumps=%d\nmask_neg_and=%d\n"
            "instructions=%d\n"
            "helper_symbol=%s\nhelper_cmov=%s\nhelper_setcc=%s\nhelper_bt_jae=%s\n"
            "helper_mask_neg_and=%s\n"
            "memcheck_contexts=%d\nmemcheck_errors=%d\nmemcheck_exit=%d\n"
            "memcheck_functions=%s\n"
            % (
                cell,
                primary_symbol,
                symbol_address,
                facts["clangover_bt_jae"],
                facts["evidence_bt_jae"] or "-",
                facts["per_bit_test_jcc"],
                facts["evidence_per_bit_test_jcc"] or "-",
                facts["secret_division"],
                facts["evidence_division"] or "-",
                facts["setcc"],
                facts["cmov"],
                facts["conditional_jumps"],
                facts["mask_neg_and"],
                facts["instructions"],
                helper_symbol or "-",
                helper_facts["cmov"] if helper_facts else "-",
                helper_facts["setcc"] if helper_facts else "-",
                helper_facts["clangover_bt_jae"] if helper_facts else "-",
                helper_facts["mask_neg_and"] if helper_facts else "-",
                memcheck_facts["contexts"],
                memcheck_facts["errors"],
                memcheck_facts["exit"],
                ",".join(memcheck_facts["functions"]) or "-",
            )
        )

    columns = [
        "cell", "arm", "level", "symbol", "symbol_address", "instructions", "bt", "bt_jae",
        "per_bit_test_jcc", "setcc", "cmov", "division", "conditional_jumps",
        "mask_neg_and", "helper_cmov", "helper_setcc", "helper_bt_jae", "helper_mask_neg_and",
        "memcheck_contexts", "memcheck_errors", "memcheck_exit",
    ]
    with open(arguments.report, "w") as report_file:
        report_file.write("\t".join(columns) + "\n")
        for row in rows:
            report_file.write("\t".join(str(row[column]) for column in columns) + "\n")
    with open(arguments.report + ".details.txt", "w") as detail_file:
        detail_file.write("\n".join(details) + "\n")
    for row in rows:
        print(
            "%-16s bt_jae=%-3s per_bit_test_jcc=%-3s setcc=%-3s cmov=%-3s "
            "mask_neg_and=%-3s helper_mask=%-3s div=%s memcheck=%s/%s"
            % (
                row["cell"], row["bt_jae"], row["per_bit_test_jcc"],
                row["setcc"], row["cmov"], row["mask_neg_and"],
                row["helper_mask_neg_and"], row["division"],
                row["memcheck_contexts"], row["memcheck_errors"],
            )
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
