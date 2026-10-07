"""Cross-check generated metadata against CMake's actual compilation inputs."""

import json
import shlex
import subprocess
import sys
from pathlib import Path

source_root = Path(sys.argv[1]).resolve()
build_root = Path(sys.argv[2]).resolve()
configuration_path = build_root / "generated/RelWithDebInfo/configuration.txt"
configuration = dict(
    line.split("=", 1)
    for line in configuration_path.read_text().splitlines()
    if "=" in line
)
compile_commands = json.loads((build_root / "compile_commands.json").read_text())
kernel_entries = []
for variant in ("reference", "vulnerable", "hardened", "deployable"):
    expected_include = (
        source_root / "vendor/mlkem-native/mlkem"
        if variant == "reference"
        else build_root / f"{variant}-source/mlkem"
    )
    assert configuration[f"{variant}_kernel_include"] == str(expected_include)
    source_name = "kernel.c" if variant == "reference" else f"{variant}_kernel.c"
    kernel_entry = next(
        entry
        for entry in compile_commands
        if Path(entry["file"]).name == source_name
    )
    kernel_command = kernel_entry["command"]
    assert f"-I{expected_include}" in kernel_command
    if variant != "reference":
        assert kernel_command.index(f"-I{expected_include}") < kernel_command.index(
            f'-I{source_root / "vendor/mlkem-native/mlkem"}'
        )
    assert "flto" not in kernel_command
    kernel_entries.append(kernel_entry)
    print(f"{variant}: recorded include matches compilation path/order; no LTO flag")

command_tokens = shlex.split(kernel_entries[0]["command"])
preprocessor_arguments = []
token_index = 0
while token_index < len(command_tokens):
    command_token = command_tokens[token_index]
    if command_token == "-o":
        token_index += 2
        continue
    if command_token not in ("-c", kernel_entries[0]["file"]):
        preprocessor_arguments.append(command_token)
    token_index += 1
preprocessor_arguments.extend(
    ["-dM", "-E", str(source_root / "vendor/mlkem-native/mlkem/src/verify.h")]
)
preprocessor_result = subprocess.run(
    preprocessor_arguments,
    cwd=kernel_entries[0]["directory"],
    text=True,
    capture_output=True,
    check=True,
)
macro_names = {
    line.split()[1]
    for line in preprocessor_result.stdout.splitlines()
    if line.startswith("#define ") and len(line.split()) > 1
}
assert "MLK_HAVE_INLINE_ASM" in macro_names
assert "MLK_USE_ASM_VALUE_BARRIER" in macro_names
for absent_macro in (
    "MLK_CONFIG_USE_NATIVE_BACKEND_ARITH",
    "MLK_CONFIG_USE_NATIVE_BACKEND_FIPS202",
    "MLK_CONFIG_FIPS202_CUSTOM_HEADER",
    "MLK_CONFIG_CUSTOM_ALLOC_FREE",
    "MLK_CONFIG_NO_ASM",
    "MLK_CONFIG_NO_ASM_VALUE_BARRIER",
):
    assert absent_macro not in macro_names
output_root = Path(__file__).resolve().parent
(output_root / "kernel-compile-commands.json").write_text(
    json.dumps(kernel_entries, indent=2) + "\n"
)
(output_root / "effective-macros.txt").write_text(preprocessor_result.stdout)
(output_root / "preprocessor-command.txt").write_text(
    shlex.join(preprocessor_arguments) + "\n"
)
print("Effective macros: portable C/FIPS202, stack allocation, inline asm value barrier")
print("Check scope: CMake metadata consistency; no hardware constant-time conclusion")
