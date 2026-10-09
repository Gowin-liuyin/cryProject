set -eu
date -u '+utc=%Y-%m-%dT%H:%M:%SZ'
hostname
uname -srm
systemd-detect-virt || test "$?" -eq 1
id -un
getconf _NPROCESSORS_ONLN
awk '/^(MemTotal|MemAvailable):/ {print}' /proc/meminfo
awk -F ': ' '/model name/ {print; exit}' /proc/cpuinfo
lscpu --parse=CPU,CORE,SOCKET,NODE,ONLINE
awk '/^Cpus_allowed_list:/ {print}' /proc/self/status
cat /proc/loadavg
cat /proc/stat
cat /proc/pressure/cpu
gcc --version
clang --version
cmake --version
df -Pk /home/nss-marker/yhr/Cry
test -d /home/nss-marker/yhr/Cry
test -w /home/nss-marker/yhr/Cry
for policy_directory in /sys/devices/system/cpu/cpufreq/policy*; do
    test -d "$policy_directory" || continue
    printf 'policy=%s\n' "$policy_directory"
    for field_name in scaling_driver scaling_governor related_cpus affected_cpus scaling_min_freq scaling_max_freq scaling_cur_freq cpuinfo_min_freq cpuinfo_max_freq energy_performance_preference; do
        if test -r "$policy_directory/$field_name"; then
            printf '%s=' "$field_name"
            cat "$policy_directory/$field_name"
        fi
    done
done
for scalar_path in /sys/devices/system/cpu/cpufreq/boost /sys/devices/system/cpu/amd_pstate/status /sys/devices/system/cpu/smt/active /sys/devices/system/clocksource/clocksource0/current_clocksource /sys/devices/system/clocksource/clocksource0/available_clocksource /proc/sys/kernel/perf_event_paranoid; do
    if test -r "$scalar_path"; then
        printf '%s=' "$scalar_path"
        cat "$scalar_path"
    fi
done
for sensor_directory in /sys/class/hwmon/hwmon*; do
    test -r "$sensor_directory/name" || continue
    if test "$(cat "$sensor_directory/name")" = k10temp; then
        printf 'temperature_sensor=%s\n' "$sensor_directory"
        for sensor_path in "$sensor_directory"/temp*_label "$sensor_directory"/temp*_input; do
            if test -r "$sensor_path"; then
                printf '%s=' "$sensor_path"
                cat "$sensor_path"
            fi
        done
    fi
done
cat /proc/loadavg
cat /proc/stat
cat /proc/pressure/cpu
date -u '+utc_finish=%Y-%m-%dT%H:%M:%SZ'
