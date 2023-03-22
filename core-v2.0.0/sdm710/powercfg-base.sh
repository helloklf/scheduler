#!/system/bin/sh

killall scene-scheduler 2>/dev/null

# cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
# 300000 576000 748800 998400 1209600 1324800 1516800 1612800 1708800

# cat /sys/devices/system/cpu/cpu6/cpufreq/scaling_available_frequencies
# 300000 652800 825600 979200 1132800 1363200 1536000 1747200 1843200 1996800 2054400 2169600 2208000

target=`getprop ro.board.platform`

# Enable input boost configuration
echo "0:1324800" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms
echo "0:1708800 1:1708800 2:1708800 3:1708800 4:1708800 5:1708800 6:2208000 7:2208000" > /sys/module/cpu_boost/parameters/powerkey_input_boost_freq
echo 400 > /sys/module/cpu_boost/parameters/powerkey_input_boost_ms
echo 'Y' > /sys/module/cpu_boost/parameters/sched_boost_on_powerkey_input
#echo 'Y' > /sys/module/cpu_boost/parameters/sched_boost_on_input

echo N > /sys/module/lpm_levels/parameters/sleep_disabled

echo 1 > /proc/sys/kernel/sched_prefer_sync_wakee_to_waker
stop perfd

echo 0 > /sys/module/msm_thermal/core_control/enabled
echo 0 > /sys/module/msm_thermal/vdd_restriction/enabled
echo N > /sys/module/msm_thermal/parameters/enabled
