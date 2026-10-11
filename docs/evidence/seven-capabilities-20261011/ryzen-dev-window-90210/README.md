# 开发种子窗口核对（90210）

这是开发种子上的窗口核对，不是新的确认采集。种子 `90210`。每类 200 次。主机 `nss-m`，Linux 6.17.0-35-generic，x86_64，`taskset -c 2`。没有加大已冻结的 20×5000，没有用确认种子 `20261111` 或 `8675309`，也没有把这次排名写成根因。v1 与 v2 的 Holm 未拒绝记录保持原样。R02、R04 不升级。

## before：已交付的无插桩采集和诊断

远端目录 `/home/nss-marker/yhr/Cry/seven-capabilities-20261011/run-dev-window-90210/`。

无插桩 `session_collect` 的 run_id 是 `dev-window-90210`。`before/session.meta` 记录 `resolution_counts=1`、`empty_window_max_counts=120`、`timed_window=mlkem_decapsulate_only`、`executable_sha3_256=458a978f4c22061f4bdadd89375cf0c2940710457f945c6a882025890b3ad50a`。`before/session.csv` 中 message-zero 均值 38851.170，message-ones 均值 38844.130，差 7.040 个计数。这个差落在空窗口最大值 120 之内。

同一目录里的诊断候选 `before/candidates.csv` 把整段重加密算成一个排他区间。`baseline_stage_reencrypt` 的排他差是 7，解密阶段是 8。人工分支所在的 `mlk_poly_frommsg` 没有单独的一行。

## message：只把 poly_frommsg 放进解封装样本

诊断覆盖层新增 `baseline_stage_reencrypt_message`，只调用 `mlk_poly_frommsg`。钩子只在样本活动时记录，样本活动区间包住 `mlkem_decapsulate`。密文生成在该区间之前。

远端目录 `/home/nss-marker/yhr/Cry/seven-capabilities-20261011/run-dev-window-90210-message/`。诊断二进制 SHA-256 `151ded51d15e885395c95fa4c2c636857a4a4e6f8141065d9d82d981c5519e82`。源树 `Cry/window-source-90210/`。GCC 13.3.0，RelWithDebInfo。同树 CTest `diagnostic_trace` 与 `diagnostic_trace_vulnerable` 均为通过。

`message/candidates.csv` 中 `baseline_stage_reencrypt_message` 的阶段是 `reencryption`，内联范围是 `mlk_poly_frommsg`，排他差是 -15。外层 `baseline_stage_reencrypt` 的排他差是 57。`message/summary.txt` 的外层均值：message-zero 39297.020，message-ones 39262.635。`message/detection.txt` 写 `end_to_end_detected=no`。已交付的 `localize_rank` 输出 `message/rank.txt`：`single_root_cause=not_forced`，Top-1 仍是重加密包装，Top-3 的第二名是消息多项式包装。这不是检出后的定位成功，分母仍按确认记录记为 0。

同一远端目录里的无插桩原件是 `message/session.csv` 与 `message/session.meta`。采集器是这棵源树上的 `vulnerable/session_collect`，run_id `dev-window-90210-message`，种子 `90210`，每类 200 次，`taskset -c 2`。SHA-256 与远端一致：`session.csv` 为 `6fb96a4e5af8fc46abba8fc79bccf817c213f0fa4ddee30a7d2ff3a4c5ae2667`，`session.meta` 为 `dcfb036c7fd3de2590bfc852ebff003a1701d73139a474ca4e518a069aee2e0f`。`session.meta` 写 `resolution_counts=1`、`empty_window_max_counts=50`、`timed_window=mlkem_decapsulate_only`、`executable_sha3_256=8b33e51b7eb79fabd464b81e1d96ded95699c8903c71f310527f04f101ad0118`。由 `session.csv` 相减，message-zero 均值 29833.835，message-ones 均值 29812.960，差 20.875 个计数。正文新增数字只引用这两份文件。
