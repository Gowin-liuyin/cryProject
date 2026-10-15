cmake_minimum_required(VERSION 3.21)
project(jobserver_matrix C)

# 4 个互不依赖的目标，各耗时 1s：串行约 4.2s，4 路并行约 1.1s。
foreach(target_index 1 2 3 4)
    add_custom_target(
        slow_${target_index} ALL COMMAND ${CMAKE_COMMAND} -E sleep 1
    )
endforeach()
