#! /vendor/bin/sh

cfg_dir=$(cd $(dirname $0); pwd)

killall scene-scheduler 2>/dev/null

if [[ ! -f "$cfg_dir/powercfg-utils.sh" ]]; then
  echo "The dependent '$cfg_dir/powercfg-utils.sh' was not found !" > /cache/powercfg.sh.log
  exit 1
else
  source "$cfg_dir/powercfg-utils.sh"
fi

# echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks

for index in 0 1 2 3 4 5 6 7; do
  echo 1 > /sys/devices/system/cpu/cpu$index/online
done


if [[ ! -f /proc/sys/kernel/sched_group_upmigrate ]] || [[ $(getprop ro.product.vendor.brand) == "google" ]] || [[ $(getprop ro.build.version.sdk) -gt 29 ]] ; then
  echo 'Google Pixel4'
  # Setting b.L scheduler parameters
  hide_value /proc/sys/kernel/sched_upmigrate
  hide_value /proc/sys/kernel/sched_downmigrate
  hide_value /proc/sys/kernel/sched_group_upmigrate
  hide_value /proc/sys/kernel/sched_group_downmigrate
  hide_value /proc/sys/kernel/sched_walt_rotate_big_tasks
else
  echo '>>> sched_upmigrate/sched_downmigrate'
fi

# killall -9 vendor.qti.hardware.perf@1.0-service

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

governor_cover() {
  policy=/sys/devices/system/cpu/cpufreq/policy
  ls $policy* | while read cluster; do
    hide_value ${policy}${cluster}/scaling_governor $1
  done
}

process_opt(){
  set_cpuset surfaceflinger top-app
  set_cpuset system_server top-app
  set_cpuset vendor.qti.hardware.display.composer-service top-app

  pidof com.android.systemui | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    # echo $pid > /dev/stune/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      case $(cat /proc/$pid/task/$tid/comm) in
        "wmshell.anim"*)
          echo $tid > /dev/cpuset/top-app/tasks
          taskset -p f0 $tid > /dev/null
        ;;
      esac
      # echo $tid > /dev/cpuset/$2/tasks
    done
  done

  miui_home=$(pidof com.miui.home)
  if [[ "$miui_home" != "" ]]; then
    memcg=/dev/memcg
    mem_fg=$memcg/scene_fg
    if [[ -d $memcg ]] && [[ ! -e "$mem_fg" ]]; then
      mkdir -p $mem_fg
      echo 0 > $mem_fg/memory.swappiness
      echo 1 > $mem_fg/memory.oom_control
      echo 1 > $mem_fg/memory.use_hierarchy
      echo 1 >  $mem_fg/memory.move_charge_at_immigrate
    fi
    echo $miui_home > $mem_fg/cgroup.procs
  fi
}

# Default By Xiaomi
# set_value 10000000 /proc/sys/kernel/sched_latency_ns
# set_value 3000000 /proc/sys/kernel/sched_min_granularity_ns

set_value 8000000 /proc/sys/kernel/sched_latency_ns
set_value 2000000 /proc/sys/kernel/sched_min_granularity_ns

governor_cover schedutil
if [[ -f /sys/module/msm_performance/parameters/cpu_max_freq ]]; then
  hide_value /sys/module/msm_performance/parameters/cpu_max_freq '0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295'
  chattr +i  /sys/module/msm_performance/parameters/cpu_max_freq
  hide_value /sys/module/msm_performance/parameters/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
  chattr +i  /sys/module/msm_performance/parameters/cpu_min_freq
fi

hide_value /sys/class/kgsl/kgsl-3d0/devfreq/governor 'msm-adreno-tz'

set_value "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" /sys/module/cpu_boost/parameters/input_boost_freq
set_value 0 /sys/module/cpu_boost/parameters/input_boost_ms
set_value 0 /sys/module/cpu_boost/parameters/sched_boost_on_input
set_value "0:0 1:0 2:0 3:0 4:2323200 5:0 6:0 7:2323200" /sys/module/cpu_boost/parameters/powerkey_input_boost_freq
set_value 400 /sys/module/cpu_boost/parameters/powerkey_input_boost_ms


t_message=/sys/class/thermal/thermal_message
if [[ -f $t_message/cpu_limits ]]; then
  for i in $(seq 0 7); do
    maxfreq=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq)
    echo cpu$i $maxfreq > $t_message/cpu_limits
  done
  chmod 444 $t_message/cpu_limits
fi
hide_value $t_message/market_download_limit 0
hide_value $t_message/cpu_nolimit_temp 47500
echo N > /sys/kernel/debug/debug_enabled
echo 0 > /sys/kernel/tracing/tracing_on

disable_migt() {
  migt=/sys/module/migt/parameters
  if [[ -d $migt ]]; then
    hide_value $migt/migt_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
    hide_value $migt/glk_freq_limit_start '0'
    hide_value $migt/glk_freq_limit_walt '0'
    hide_value $migt/glk_maxfreq '0 0 0'
    hide_value $migt/glk_minfreq '300000 710400 825600'
    hide_value $migt/migt_ceiling_freq '0 0 0'
    hide_value $migt/glk_disable '1'
    hide_value $migt/mi_freq_enable '0'
    hide_value $migt/force_stask_to_big '0'
    hide_value $migt/glk_fbreak_enable '0'
    hide_value $migt/force_reset_runtime '0'

    settings put secure speed_mode_enable 1
    chmod 000 $migt/*
  fi

  glk=/proc/sys/glk
  if [[ -d $glk ]]; then
    hide_value $glk/glk_disable '1'
    hide_value $glk/freq_break_enable '0'
    hide_value $glk/game_minfreq_limit '0 0 0'
    hide_value $glk/game_maxfreq_limit '0 0 0'
    hide_value $glk/game_lowspeed_load '30 30 30'
    hide_value $glk/game_hispeed_load '80 80 80'
  fi

  migt=/proc/sys/migt
  if [[ -d $migt ]]; then
    hide_value $migt/force_stask_tob '0'
    hide_value $migt/enable_pkg_monitor '0'
    hide_value $migt/boost_pid '0'
  fi
}

disable_migt

core_ctl_preset() {
  if [[ ! -e /sys/devices/system/cpu/cpu7/core_ctl ]]; then
    return
  fi

  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  echo 50 > $cpu7_core_ctl_dir/offline_delay_ms
  echo 1 > $cpu7_core_ctl_dir/not_preferred
  echo 1 > $cpu7_core_ctl_dir/max_cpus
  echo 0 > $cpu7_core_ctl_dir/min_cpus
  # echo 1 > $cpu7_core_ctl_dir/nr_prev_assist_thresh
  echo 1 > $cpu7_core_ctl_dir/task_thres
  echo 30 > $cpu7_core_ctl_dir/busy_down_thres
  echo 60 > $cpu7_core_ctl_dir/busy_up_thres
  # echo 1 > $cpu7_core_ctl_dir/enable

  cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
  echo 50 > $cpu4_core_ctl_dir/offline_delay_ms
  echo 1 1 1 > $cpu4_core_ctl_dir/not_preferred
  echo 3 > $cpu4_core_ctl_dir/max_cpus
  echo 0 > $cpu4_core_ctl_dir/min_cpus
  # echo 4294967295 > $cpu4_core_ctl_dir/nr_prev_assist_thresh
  echo 3 > $cpu4_core_ctl_dir/task_thres
  echo 15 > $cpu4_core_ctl_dir/busy_down_thres
  echo 20 > $cpu4_core_ctl_dir/busy_up_thres
  # echo 1 > $cpu4_core_ctl_dir/enable

  cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
  echo 50 > $cpu0_core_ctl_dir/offline_delay_ms
  echo 0 1 1 1 > $cpu0_core_ctl_dir/not_preferred
  echo 4 > $cpu0_core_ctl_dir/max_cpus
  echo 1 > $cpu0_core_ctl_dir/min_cpus
  # echo 4294967295 > $cpu0_core_ctl_dir/nr_prev_assist_thresh
  # echo 3 > $cpu0_core_ctl_dir/task_thres
  echo 15 > $cpu0_core_ctl_dir/busy_down_thres
  echo 20 > $cpu0_core_ctl_dir/busy_up_thres
  # echo 1 > $cpu0_core_ctl_dir/enable
}

core_ctl_preset
set_hispeed_freq 0 0 0

uninstall_mi_opt() {
  pm uninstall --user 0 com.miui.daemon >/dev/null 2>&1
  pm uninstall --user 0 com.xiaomi.joyose >/dev/null 2>&1
}

reinstall_mi_opt() {
  uninstall_mi_opt
  pm install-existing --user 0 com.miui.daemon >/dev/null 2>&1
  pm install-existing --user 0 com.xiaomi.joyose >/dev/null 2>&1
}

version=$(getprop ro.miui.ui.version.name)
if [[ "$varsion" == "V125" ]] || [[ "$varsion" == "V130" ]]; then
  uninstall_mi_opt &
fi

process_opt &
