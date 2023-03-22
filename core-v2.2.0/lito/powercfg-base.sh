#! /vendor/bin/sh

killall scene-scheduler 2>/dev/null

target=`getprop ro.board.platform`

case "$target" in
  "lito")

    # Controls how many more tasks should be eligible to run on gold CPUs
    # w.r.t number of gold CPUs available to trigger assist (max number of
    # tasks eligible to run on previous cluster minus number of CPUs in
    # the previous cluster).
    #
    # Setting to 1 by default which means there should be at least
    # 4 tasks eligible to run on gold cluster (tasks running on gold cores
    # plus misfit tasks on silver cores) to trigger assitance from gold+.
    echo 1 > /sys/devices/system/cpu/cpu7/core_ctl/nr_prev_assist_thresh

    # Disable Core control on silver
    echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable

    echo 1 > /sys/devices/system/cpu/cpu6/core_ctl/enable
    echo 1 > /sys/devices/system/cpu/cpu7/core_ctl/enable
    echo 0 > /sys/devices/system/cpu/cpu6/core_ctl/min_cpus
    echo 0 > /sys/devices/system/cpu/cpu7/core_ctl/min_cpus

    # Setting b.L scheduler parameters
    echo 95 95 > /proc/sys/kernel/sched_upmigrate
    echo 85 85 > /proc/sys/kernel/sched_downmigrate
    echo 100 > /proc/sys/kernel/sched_group_upmigrate
    echo 85 > /proc/sys/kernel/sched_group_downmigrate
    echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks
    echo 400000000 > /proc/sys/kernel/sched_coloc_downmigrate_ns

    # cpuset parameters
    echo 0-2 > /dev/cpuset/background/cpus
    echo 0-3 > /dev/cpuset/system-background/cpus
    echo 0-7 > /dev/cpuset/foreground/cpus
    echo 0-7 > /dev/cpuset/top-app/cpus

    # Turn off scheduler boost at the end
    echo 0 > /proc/sys/kernel/sched_boost

    # Turn on scheduler boost for top app main
    echo 1 > /proc/sys/kernel/sched_boost_top_app

    # configure governor settings for silver cluster
    echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
    echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
    echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
    echo 1516800 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_freq
    echo 300000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
    echo 1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/pl

    # configure input boost settings
    echo "0:1516800" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
    echo 120 > /sys/devices/system/cpu/cpu_boost/input_boost_ms
    echo "0:1804800 1:0 2:0 3:0 4:0 5:0 6:2208000 7:2400000" > /sys/devices/system/cpu/cpu_boost/powerkey_input_boost_freq
    echo 400 > /sys/devices/system/cpu/cpu_boost/powerkey_input_boost_ms

    # configure governor settings for gold cluster
    echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy6/scaling_governor
    echo 0 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us
    echo 0 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us
    echo 1478400 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/hispeed_freq
    echo 1 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/pl

    # configure governor settings for gold+ cluster
    echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy7/scaling_governor
    echo 0 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/down_rate_limit_us
    echo 0 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/up_rate_limit_us
    echo 1766400 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/hispeed_freq
    echo 1 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/pl

    echo N > /sys/module/lpm_levels/parameters/sleep_disabled
  ;;
esac

# Disable MIUI's daemon\joyose
# disable_mi_opt &

# Uninstall MIUI's daemon\joyose
version=$(getprop ro.miui.ui.version.name)
if [[ "$version" == "V130" ]]; then
  # mi_joyose_opt &
  echo 'mi_joyose_opt'
elif [[ "$version" == "V12" ]]; then
  uninstall_mi_opt &
elif [[ "$version" == "V125" ]]; then
  # uninstall_mi_opt &
  echo 'uninstall_mi_opt'
fi
disable_migt
# Reinstall MIUI's daemon\joyose
# reinstall_mi_opt &