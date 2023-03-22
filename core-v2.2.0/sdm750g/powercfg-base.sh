#!/system/bin/sh

killall scene-scheduler 2>/dev/null


target=`getprop ro.board.platform`

chmod 0755 /sys/devices/system/cpu/cpu0/online
chmod 0755 /sys/devices/system/cpu/cpu1/online
chmod 0755 /sys/devices/system/cpu/cpu2/online
chmod 0755 /sys/devices/system/cpu/cpu3/online
chmod 0755 /sys/devices/system/cpu/cpu4/online
chmod 0755 /sys/devices/system/cpu/cpu5/online
chmod 0755 /sys/devices/system/cpu/cpu6/online
chmod 0755 /sys/devices/system/cpu/cpu7/online

# Core control parameters on silver
echo 0 0 1 1 1 1 > /sys/devices/system/cpu/cpu0/core_ctl/not_preferred
echo 2 > /sys/devices/system/cpu/cpu0/core_ctl/min_cpus
echo 70 > /sys/devices/system/cpu/cpu0/core_ctl/busy_up_thres
echo 50 > /sys/devices/system/cpu/cpu0/core_ctl/busy_down_thres
echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/offline_delay_ms
# echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/is_big_cluster
# echo 8 > /sys/devices/system/cpu/cpu0/core_ctl/task_thres
echo 1 > /sys/devices/system/cpu/cpu0/core_ctl/enable

# Core control parameters on gold
echo 1 1 > /sys/devices/system/cpu/cpu6/core_ctl/not_preferred
echo 0 > /sys/devices/system/cpu/cpu6/core_ctl/min_cpus
echo 85 > /sys/devices/system/cpu/cpu6/core_ctl/busy_up_thres
echo 65 > /sys/devices/system/cpu/cpu6/core_ctl/busy_down_thres
echo 20 > /sys/devices/system/cpu/cpu6/core_ctl/offline_delay_ms
echo 1 > /sys/devices/system/cpu/cpu6/core_ctl/enable


# Setting b.L scheduler parameters
# default sched up and down migrate values are 90 and 85
echo 65 > /proc/sys/kernel/sched_downmigrate
echo 71 > /proc/sys/kernel/sched_upmigrate
# default sched up and down migrate values are 100 and 95
echo 85 > /proc/sys/kernel/sched_group_downmigrate
echo 100 > /proc/sys/kernel/sched_group_upmigrate
echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks

# sched_load_boost as -6 is equivalent to target load as 85. It is per cpu tunable.
echo -6 >  /sys/devices/system/cpu/cpu6/sched_load_boost
echo -6 >  /sys/devices/system/cpu/cpu7/sched_load_boost
echo 85 > /sys/devices/system/cpu/cpu6/cpufreq/schedutil/hispeed_load

# Enable input boost configuration
echo "0:1324800" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms
echo "0:1708800 1:1708800 2:1708800 3:1708800 4:1708800 5:1708800 6:2208000 7:0" > /sys/module/cpu_boost/parameters/powerkey_input_boost_freq
echo 400 > /sys/module/cpu_boost/parameters/powerkey_input_boost_ms
echo 'Y' > /sys/module/cpu_boost/parameters/sched_boost_on_powerkey_input
#echo 'Y' > /sys/module/cpu_boost/parameters/sched_boost_on_input

echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled

set_value 10000000 /proc/sys/kernel/sched_latency_ns
set_value 2000000 /proc/sys/kernel/sched_min_granularity_ns

echo 1 > /proc/sys/kernel/sched_prefer_sync_wakee_to_waker
