target=`getprop ro.board.platform`

killall scene-scheduler 2>/dev/null


echo "0:1708800 1:0 2:0 3:0 4:2342400 5:0 6:0 7:2496000" > /sys/devices/system/cpu/cpu_boost/powerkey_input_boost_freq
echo 400 > /sys/devices/system/cpu/cpu_boost/powerkey_input_boost_ms

echo N > /sys/module/lpm_levels/parameters/sleep_disabled

disable_migt() {
  migt=/sys/module/migt/parameters
  if [[ -d $migt ]]; then
    hide_value $migt/migt_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
    hide_value $migt/glk_freq_limit_start '0'
    hide_value $migt/glk_freq_limit_walt '0'
    hide_value $migt/glk_maxfreq '0 0 0'
    hide_value $migt/glk_minfreq '300000 710400 844800'
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
    hide_value $migt/glk_disable '1'
    hide_value $migt/freq_break_enable '0'
    hide_value $migt/game_minfreq_limit '0 0 0'
    hide_value $migt/game_maxfreq_limit '0 0 0'
    hide_value $migt/game_lowspeed_load '30 30 30'
    hide_value $migt/game_hispeed_load '80 80 80'
  fi

  metis=/sys/module/metis/parameters
  for file in $metis/*enable*; do
    echo 0 > $file
  done
  if [[ -d $metis ]]; then
    chmod -R 444 $metis
  fi

  migt=/proc/sys/migt
  if [[ -d $migt ]]; then
    hide_value $migt/force_stask_tob '0'
    hide_value $migt/enable_pkg_monitor '0'
    hide_value $migt/boost_pid '0'
  fi

  killall mi_thermald
}
core_ctl_preset(){
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  echo 10 > $cpu7_core_ctl_dir/offline_delay_ms
  echo 1 > $cpu7_core_ctl_dir/not_preferred
  echo 0 > $cpu7_core_ctl_dir/enable
  echo 1 > $cpu7_core_ctl_dir/max_cpus
  echo 0 > $cpu7_core_ctl_dir/min_cpus
  # echo 1 > $cpu7_core_ctl_dir/nr_prev_assist_thresh
  echo 1 > $cpu7_core_ctl_dir/task_thres
  echo 27 > $cpu7_core_ctl_dir/busy_down_thres
  echo 50 > $cpu7_core_ctl_dir/busy_up_thres

  cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
  echo 20 > $cpu4_core_ctl_dir/offline_delay_ms
  echo 1 > $cpu4_core_ctl_dir/not_preferred
  echo 0 > $cpu4_core_ctl_dir/enable
  echo 3 > $cpu4_core_ctl_dir/max_cpus
  echo 0 > $cpu4_core_ctl_dir/min_cpus
  # echo 4294967295 > $cpu4_core_ctl_dir/nr_prev_assist_thresh
  echo 3 > $cpu4_core_ctl_dir/task_thres
  echo 20 > $cpu4_core_ctl_dir/busy_down_thres
  echo 35 > $cpu4_core_ctl_dir/busy_up_thres

  cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
  echo 100 > $cpu0_core_ctl_dir/offline_delay_ms
  echo 0 1 1 1 > $cpu0_core_ctl_dir/not_preferred
  echo 0 > $cpu0_core_ctl_dir/enable
  echo 4 > $cpu0_core_ctl_dir/max_cpus
  echo 1 > $cpu0_core_ctl_dir/min_cpus
  # echo 4294967295 > $cpu0_core_ctl_dir/nr_prev_assist_thresh
  # echo 3 > $cpu0_core_ctl_dir/task_thres
  echo 10 > $cpu0_core_ctl_dir/busy_down_thres
  echo 20 > $cpu0_core_ctl_dir/busy_up_thres

  echo 0 > /sys/devices/system/cpu/hang_detect_core/enable
  echo 0 > /sys/devices/system/cpu/hyp_core_ctl/enable
}

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
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuctl/heavy/tasks
    done
  done
}

governor_cover() {
  policy=/sys/devices/system/cpu/cpufreq/policy
  ls $policy* | while read cluster; do
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

# stop before updating cfg
perfhal_stop() {
  for i in 0 1 2 3 4; do
    for j in 0 1 2 3 4; do
      stop "perf-hal-$i-$j" 2>/dev/null
      stop "power-hal-$i-$j" 2>/dev/null
    done
  done
  usleep 500
}

# start after updating cfg
perfhal_start() {
  for i in 0 1 2 3 4; do
    for j in 0 1 2 3 4; do
      start "perf-hal-$i-$j" 2>/dev/null
      start "power-hal-$i-$j" 2>/dev/null
    done
  done
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

disable_migt
core_ctl_preset

if [[ -d /sys/module/cpu_boost/parameters ]]; then
  echo "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" > /sys/module/cpu_boost/parameters/input_boost_freq
  echo 0 > /sys/module/cpu_boost/parameters/input_boost_ms
  echo 0 > /sys/module/cpu_boost/parameters/sched_boost_on_input
fi
for index in 0 1 2 3 4 5 6; do
  hide_value /sys/devices/system/cpu/cpu$index/online 1
done

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
lock_value 0 /sys/module/aigov/parameters/enable

echo 128 > /dev/cpuctl/background/cpu.shares
echo 128 > /dev/cpuctl/system-background/cpu.shares
echo 512 > /dev/cpuctl/foreground/cpu.shares

for group in top-app
do
  echo 0 > /dev/cpuctl/$group/cpu.uclamp.latency_sensitive
  echo 1 > /dev/cpuctl/$group/cpu.uclamp.sched_boost_no_override
done

for group in system ui foreground background system-background
do
  echo 0 > /dev/cpuctl/$group/cpu.uclamp.latency_sensitive
  echo 0 > /dev/cpuctl/$group/cpu.uclamp.sched_boost_no_override
done

# echo libunity.so, libfb.so > /proc/sys/kernel/sched_lib_name
# echo 240 > /proc/sys/kernel/sched_lib_mask_force

process_opt &
perfhal_stop
perfhal_start

setprop persist.sys.miui_animator_sched.bigcores 4-7
