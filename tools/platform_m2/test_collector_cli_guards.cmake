# collector-v2 命令行准入资格：非法参数必须失败且不留输出，合法参数必须成功。
# 由 -DCOLLECTOR= -DKEYPAIR_TOOL= -DWORK_DIR= 传入，输出目录每次重建。
if(NOT DEFINED COLLECTOR OR NOT DEFINED KEYPAIR_TOOL OR NOT DEFINED WORK_DIR)
    message(FATAL_ERROR "require COLLECTOR, KEYPAIR_TOOL and WORK_DIR")
endif()
file(REMOVE_RECURSE "${WORK_DIR}")
file(MAKE_DIRECTORY "${WORK_DIR}")
execute_process(
    COMMAND "${KEYPAIR_TOOL}" --key-seed m2-collector-cli-guards --public-key
            "${WORK_DIR}/pk.bin" --secret-key "${WORK_DIR}/sk.bin"
    RESULT_VARIABLE keypair_status
    OUTPUT_VARIABLE keypair_output
    ERROR_VARIABLE keypair_error
)
if(NOT keypair_status EQUAL 0)
    message(FATAL_ERROR "fixture key generation failed: ${keypair_error}")
endif()
file(WRITE "${WORK_DIR}/bad-pk.bin" "short-public-key")
file(WRITE "${WORK_DIR}/bad-sk.bin" "short-secret-key")

macro(run_expect_status expected_status label)
    execute_process(
        COMMAND ${ARGN}
        RESULT_VARIABLE actual_status
        OUTPUT_VARIABLE actual_output
        ERROR_VARIABLE actual_error
        WORKING_DIRECTORY "${WORK_DIR}"
    )
    if(NOT actual_status EQUAL ${expected_status})
        message(
            FATAL_ERROR
                "${label}: expected exit ${expected_status}, got ${actual_status}; stderr=${actual_error}"
        )
    endif()
endmacro()

set(good_key_args --public-key "${WORK_DIR}/pk.bin" --secret-key "${WORK_DIR}/sk.bin")

run_expect_status(2 "missing arguments" "${COLLECTOR}")
run_expect_status(0 "help" "${COLLECTOR}" --help)
run_expect_status(
    2 "unknown class" "${COLLECTOR}" --class nope --samples 4 --seed 1 --raw
    "${WORK_DIR}/unknown-class.csv" ${good_key_args}
)
run_expect_status(
    2 "duplicate class" "${COLLECTOR}" --class message-zero,message-zero --samples 4 --seed 1
    --raw "${WORK_DIR}/duplicate-class.csv" ${good_key_args}
)
run_expect_status(
    2 "empty class field" "${COLLECTOR}" --class message-zero,,message-ones --samples 4 --seed 1
    --raw "${WORK_DIR}/empty-class.csv" ${good_key_args}
)
run_expect_status(
    2 "zero samples" "${COLLECTOR}" --class message-zero --samples 0 --seed 1 --raw
    "${WORK_DIR}/zero-samples.csv" ${good_key_args}
)
run_expect_status(
    2 "too many samples" "${COLLECTOR}" --class message-zero --samples 20001 --seed 1 --raw
    "${WORK_DIR}/too-many-samples.csv" ${good_key_args}
)
run_expect_status(
    2 "missing seed" "${COLLECTOR}" --class message-zero --samples 4 --raw
    "${WORK_DIR}/missing-seed.csv" ${good_key_args}
)
run_expect_status(
    2 "invalid run id" "${COLLECTOR}" --class message-zero --samples 4 --seed 1 --run-id "bad id"
    --raw "${WORK_DIR}/bad-run-id.csv" ${good_key_args}
)
run_expect_status(
    2 "non decimal seed" "${COLLECTOR}" --class message-zero --samples 4 --seed 12x --raw
    "${WORK_DIR}/bad-seed.csv" ${good_key_args}
)
run_expect_status(
    1 "short public key" "${COLLECTOR}" --class message-zero --samples 4 --seed 1 --raw
    "${WORK_DIR}/short-pk.csv" --public-key "${WORK_DIR}/bad-pk.bin" --secret-key
    "${WORK_DIR}/sk.bin"
)
run_expect_status(
    1 "short secret key" "${COLLECTOR}" --class message-zero --samples 4 --seed 1 --raw
    "${WORK_DIR}/short-sk.csv" --public-key "${WORK_DIR}/pk.bin" --secret-key
    "${WORK_DIR}/bad-sk.bin"
)
foreach(rejected_file IN ITEMS unknown-class.csv duplicate-class.csv empty-class.csv
                             zero-samples.csv too-many-samples.csv missing-seed.csv bad-run-id.csv
                             bad-seed.csv short-pk.csv short-sk.csv
)
    if(EXISTS "${WORK_DIR}/${rejected_file}")
        message(FATAL_ERROR "rejected invocation still created ${rejected_file}")
    endif()
endforeach()

run_expect_status(
    0 "first successful collection" "${COLLECTOR}" --class message-zero,message-ones --samples 4
    --seed 31337 --raw "${WORK_DIR}/kept.csv" --meta "${WORK_DIR}/kept.meta" ${good_key_args}
)
if(NOT EXISTS "${WORK_DIR}/kept.csv" OR NOT EXISTS "${WORK_DIR}/kept.meta")
    message(FATAL_ERROR "successful collection did not create raw CSV and metadata")
endif()
file(READ "${WORK_DIR}/kept.csv" kept_csv_content)
file(READ "${WORK_DIR}/kept.meta" kept_meta_content)
run_expect_status(
    1 "existing output path" "${COLLECTOR}" --class message-zero,message-ones --samples 4 --seed
    31337 --raw "${WORK_DIR}/kept.csv" --meta "${WORK_DIR}/kept.meta" ${good_key_args}
)
file(READ "${WORK_DIR}/kept.csv" kept_csv_after)
file(READ "${WORK_DIR}/kept.meta" kept_meta_after)
if(NOT kept_csv_content STREQUAL kept_csv_after OR NOT kept_meta_content STREQUAL kept_meta_after)
    message(FATAL_ERROR "rejected second run modified existing evidence files")
endif()
message(STATUS "collector CLI guards passed")
