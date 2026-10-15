origin: 本路 m2/scripts/run-m2-mona.sh 第 28 行 'java -version' 探测未加 -XX:-UsePerfData，
        JVM 在 /tmp 建立 HotSpot perf 目录；Mona 正式回放本身经 run.sh 传 -XX:-UsePerfData，不受影响。
observed_mtime=2026-10-16 02:29:13.667266440 +0800
entries_before_move=0
entries_after_move=0
handling: 按 Cry 边界约定把 Cry 外项目文件搬回自有根保留，核对后用 mv 移除 /tmp 原路径（未另删其它文件）。
time: 2026-10-16T02:29:49+08:00
