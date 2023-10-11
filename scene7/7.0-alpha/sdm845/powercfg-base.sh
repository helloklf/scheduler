#!/system/bin/sh


target=`getprop ro.board.platform`

# Enable input boost configuration
echo "0:1324800" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms
echo "0:0 1:0 2:0 3:0 4:2208000 5:0 6:0 7:0" > /sys/module/cpu_boost/parameters/powerkey_input_boost_freq
echo 400 > /sys/module/cpu_boost/parameters/powerkey_input_boost_ms

echo N > /sys/module/lpm_levels/parameters/sleep_disabled
echo 0 > /proc/sys/kernel/sched_boost
echo 1 > /proc/sys/kernel/sched_prefer_sync_wakee_to_waker

echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/enable
chmod 444 /sys/devices/system/cpu/cpu0/core_ctl/enable
chmod 444 /sys/devices/system/cpu/cpu4/core_ctl/enable
echo 4 > /sys/devices/system/cpu/cpu0/core_ctl/min_cpus
echo 4 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus


for index in 0 1 2 3 4 5 6 7; do
  core_online[$index]=`cat /sys/devices/system/cpu/cpu$index/online`
  echo 1 > /sys/devices/system/cpu/cpu$index/online
done
