target=`getprop ro.board.platform`

manufacturer=$(getprop ro.product.manufacturer)

set_value() {
  value=$1
  path=$2
  if [[ -f $path ]]; then
    current_value="$(cat $path)"
    if [[ ! "$current_value" = "$value" ]]; then
      chmod 0664 "$path"
      echo "$value" > "$path"
    fi;
  fi;
}

verify_or_set() {
  if [[ $(cat "$2") != "$1"  ]]; then
    chmod 0664 "$2"
    echo $1 > "$2"
  fi
}

lock_value() {
  if [[ -f $2 ]];then
    chmod 644 $2
    echo $1 > $2
    chmod 444 $2
  fi
}

# hide_value /sys/module/task_turbo/parameters/feats [write_value]
hide_value() {
  if [[ -e "$1" ]]; then
    umount "$1" 2>/dev/null
    c_path="/cache${1}"
    if [[ ! -f "$c_path" ]]; then
      mkdir -p "$c_path"
      rm -r "$c_path"
    fi
    chattr -i "$c_path"
    cp -f "$1" "$c_path"
    if [[ "$2" != "" ]]; then
      lock_value "$2" "$1"
    fi
    mount --bind "$c_path" "$1"
  else
    echo "$1" Not Found!
  fi
}

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

  # killall mi_thermald
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
hide_value $t_message/temp_state 0
hide_value $t_message/market_download_limit 0
hide_value $t_message/cpu_nolimit_temp 47500
lock_value 0 /sys/module/aigov/parameters/enable

lock_value 128 /dev/cpuctl/background/cpu.shares
lock_value 128 /dev/cpuctl/system-background/cpu.shares
lock_value 512 /dev/cpuctl/foreground/cpu.shares

for group in top-app
do
  lock_value 0 /dev/cpuctl/$group/cpu.uclamp.latency_sensitive
  lock_value 1 /dev/cpuctl/$group/cpu.uclamp.sched_boost_no_override
done

for group in system ui foreground background system-background
do
  lock_value 0 /dev/cpuctl/$group/cpu.uclamp.latency_sensitive
  lock_value 0 /dev/cpuctl/$group/cpu.uclamp.sched_boost_no_override
done

# echo libunity.so, libfb.so > /proc/sys/kernel/sched_lib_name
# echo 240 > /proc/sys/kernel/sched_lib_mask_force

for i in 4 5 6 7; do
  verify_or_set 1593600000 /sys/class/devfreq/18590100.qcom,cpu$i-cpu-l3-lat/max_freq
done

setprop persist.sys.miui_animator_sched.bigcores 4-7
killall cnss_diag


# OnePlus
hide_value /proc/oplus_scheduler/sched_assist/sched_impt_task ''
lock_value N /sys/module/oplus_ion_boost_pool/parameters/debug_boost_pool_enable
if [[ -d  /proc/game_opt ]]; then
  hide_value /proc/game_opt/cpu_max_freq '0:2147483647 1:2147483647 2:2147483647 3:2147483647 4:2147483647 5:2147483647 6:2147483647 7:2147483647'
  hide_value /proc/game_opt/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
  hide_value /proc/game_opt/game_pid -1
fi
hide_value /proc/task_info/task_sched_info/task_sched_info_enable 0
hide_value /proc/oplus_scheduler/sched_assist/sched_assist_enabled 0
echo 0 > /proc/sys/kernel/sched_force_lb_enable
lock_value N /sys/module/sched_assist_common/parameters/boost_kill
lock_value N /sys/module/task_sched_info/parameters/sched_info_ctrl
for service in orms-hal-1-0 # gameopt_hal_service-1-0 midas_hal_service thermal_mnt_hal_servic
do
  stop $service
done
setprop persist.sys.hans.skipframe.enable false

kgsl(){
  lock_value $2 /sys/class/kgsl/kgsl-3d0/$1
}
pl_max=$(($(cat /sys/class/kgsl/kgsl-3d0/num_pwrlevels)-1))
kgsl thermal_pwrlevel 0
kgsl min_pwrlevel $pl_max
kgsl max_pwrlevel 0
kgsl min_pwrlevel $pl_max
kgsl default_pwrlevel $pl_max
kgsl max_clock_mhz 999
kgsl max_gpuclk 999000000
kgsl min_clock_mhz 0
kgsl devfreq/min_freq 0
kgsl devfreq/max_freq 999000000
