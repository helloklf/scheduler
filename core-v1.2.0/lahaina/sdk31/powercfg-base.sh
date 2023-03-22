target=`getprop ro.board.platform`

core_ctl_init(){
  # Core control parameters for gold
  echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
  echo 60 > /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
  echo 30 > /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
  echo 100 > /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms
  echo 3 > /sys/devices/system/cpu/cpu4/core_ctl/task_thres
  echo 1 1 1 > /sys/devices/system/cpu/cpu4/core_ctl/not_preferred

  # Core control parameters for gold+
  echo 0 > /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
  echo 60 > /sys/devices/system/cpu/cpu7/core_ctl/busy_up_thres
  echo 30 > /sys/devices/system/cpu/cpu7/core_ctl/busy_down_thres
  echo 100 > /sys/devices/system/cpu/cpu7/core_ctl/offline_delay_ms
  echo 1 > /sys/devices/system/cpu/cpu7/core_ctl/task_thres
  echo 1 > /sys/devices/system/cpu/cpu4/core_ctl/not_preferred

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
  # echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable

  echo 0 > /sys/devices/system/cpu/hang_detect_core/enable
  echo 0 > /sys/devices/system/cpu/hyp_core_ctl/enable
}

case "$target" in
  "lahaina"|"LAHAINA")
    # core_ctl_init

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
    echo 300000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
    echo 1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/pl

    # configure input boost settings
    echo "0:1708800" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
    echo 120 > /sys/devices/system/cpu/cpu_boost/input_boost_ms
    echo "0:0 1:0 2:0 3:0 4:2342400 5:0 6:0 7:2496000" > /sys/devices/system/cpu/cpu_boost/powerkey_input_boost_freq
    echo 400 > /sys/devices/system/cpu/cpu_boost/powerkey_input_boost_ms

    # configure governor settings for gold cluster
    echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
    echo 0 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/down_rate_limit_us
    echo 0 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us
    echo 1555200 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/hispeed_freq
    echo 1 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/pl

    # configure governor settings for gold+ cluster
    echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy7/scaling_governor
    echo 0 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/down_rate_limit_us
    echo 0 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/up_rate_limit_us
    echo 1670400 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/hispeed_freq
    echo 1 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/pl

    echo N > /sys/module/lpm_levels/parameters/sleep_disabled
    echo "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" > /sys/module/msm_performance/parameters/cpu_min_freq
  ;;
esac

set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    echo $pid > /dev/stune/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuset/$2/tasks
    done
  done
}

move_to_heavy() {
  pidof $1 | while read pid; do
    echo $pid > /dev/stune/top-app/heavy/cgroup.procs
    echo $pid > /dev/cpuctl/heavy/cgroup.procs
    ls /proc/$2/task | while read tid
    do
      echo $tid > /dev/cpuctl/heavy/tasks
    done
  done
}

governor_cover() {
  policy=/sys/devices/system/cpu/cpufreq/policy
  ls $policy | while read cluster; do
    hide_value ${policy}${cluster}/scaling_governor $1
  done
}

process_opt() {
  set_cpuset surfaceflinger top-app
  set_cpuset system_server top-app
  set_cpuset vendor.qti.hardware.display.composer-service top-app

  move_to_heavy vendor.qti.hardware.display.composer-service
  move_to_heavy com.android.systemui
  move_to_heavy com.miui.home
  move_to_heavy surfaceflinger
  move_to_heavy system_server
  move_to_heavy com.omarea.vtools
  move_to_heavy com.omarea.gesture

  # set_cpuset mediaserver background
  # set_cpuset media.hwcodec background

  # set_task_affinity `pgrep com.miui.home` 11111111
  # set_task_affinity `pgrep com.miui.home` 11110000
}

# cpuctl top-app 0 0 0 max
# cpuctl foreground 0 0 0 max
# cpuctl background 0 0 0 max
mk_cpuctl 'heavy' 1 0 1 max
mk_stune 'top-app/heavy' 0 0

# echo 0 > /dev/stune/nnapi-hal/schedtune.boost
# echo 0 > /dev/stune/nnapi-hal/schedtune.prefer_idle

set_value 8000000 /proc/sys/kernel/sched_latency_ns
set_value 2000000 /proc/sys/kernel/sched_min_granularity_ns

ctl_off cpu0
ctl_off cpu4
ctl_off cpu7
disable_migt

governor_cover schedutil
hide_value /sys/module/msm_performance/parameters/cpu_max_freq '0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295'
chattr +i  /sys/module/msm_performance/parameters/cpu_max_freq
hide_value /sys/module/msm_performance/parameters/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
chattr +i  /sys/module/msm_performance/parameters/cpu_min_freq

process_opt &

# Disable MIUI's daemon\joyose
# disable_mi_opt &

# Uninstall MIUI's daemon\joyose
version=$(getprop ro.miui.ui.version.name)
if [[ "$version" == "V130" ]]; then
  mi_joyose_opt &
  # echo 'mi_joyose_opt'
elif [[ "$version" == "V12" ]]; then
  uninstall_mi_opt &
elif [[ "$version" == "V125" ]]; then
  # uninstall_mi_opt &
  echo 'uninstall_mi_opt'
fi

t_message=/sys/class/thermal/thermal_message
if [[ -f $t_message/cpu_limits ]]; then
  for i in $(seq 0 7); do
    echo cpu$i 3300000 > $t_message/cpu_limits
  done
  chmod 444 $t_message/cpu_limits
fi
hide_value $t_message/market_download_limit 0
hide_value $t_message/cpu_nolimit_temp 47500
lock_value 0 /sys/module/aigov/parameters/enable

# Reinstall MIUI's daemon\joyose
# reinstall_mi_opt &


# Fix Scene'[Magisk]SwapController Bugs
# resetprop persist.sys.lmk.camera_minfree_levels ''
lock_value 0 /proc/sys/vm/panic_on_oom

# echo libunity.so, libfb.so > /proc/sys/kernel/sched_lib_name
# echo 240 > /proc/sys/kernel/sched_lib_mask_force
