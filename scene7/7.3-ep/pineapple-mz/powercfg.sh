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

disable_migt() {
  migt=/sys/module/migt/parameters
  if [[ -e $migt ]]; then
    hide_value $migt/migt_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
    hide_value $migt/glk_freq_limit_start '0'
    hide_value $migt/glk_freq_limit_walt '0'
    hide_value $migt/glk_maxfreq '0 0 0'
    hide_value $migt/glk_minfreq '307200  480000 595200'
    hide_value $migt/migt_ceiling_freq '0 0 0'
    hide_value $migt/glk_disable '1'
    hide_value $migt/mi_freq_enable '0'
    hide_value $migt/force_stask_to_big '0'
    hide_value $migt/glk_fbreak_enable '0'
    hide_value $migt/force_reset_runtime '0'

    settings put secure speed_mode_enable 1
    chmod 000 $migt/*
    chmod 000 /sys/module/migt
    chmod 000 /sys/module/sched_walt/holders/migt/parameters
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

  chmod 000 /sys/class/misc/migt
  chmod 000 /sys/module/sched_walt/holders/migt

  metis=/sys/module/metis/parameters
  if [[ -d $metis ]]; then
    for file in $metis/*enable; do
      lock_value 0 $file
    done
  fi
  mkdir -p /cache/data/system/mcd
  echo '0' > /cache/data/system/mcd/policy
  mount --bind /cache/data/system/mcd/policy /data/system/mcd/policy
}


core_ctl_preset() {
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  echo 50 > $cpu7_core_ctl_dir/offline_delay_ms
  echo 1 > $cpu7_core_ctl_dir/min_cpus

  cpu2_core_ctl_dir=/sys/devices/system/cpu/cpu2/core_ctl
  lock_value 3 $cpu2_core_ctl_dir/min_cpus
  lock_value 0 $cpu2_core_ctl_dir/enable

  cpu5_core_ctl_dir=/sys/devices/system/cpu/cpu5/core_ctl
  lock_value 1 $cpu5_core_ctl_dir/enable
  lock_value 2 $cpu5_core_ctl_dir/max_cpus
  lock_value 2 $cpu5_core_ctl_dir/min_cpus
  lock_value 0 $cpu5_core_ctl_dir/min_partial_cpus
  lock_value 0 $cpu5_core_ctl_dir/enable
}

hide_value /sys/module/msm_performance/parameters/cpu_max_freq '0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295'
chattr +i  /sys/module/msm_performance/parameters/cpu_max_freq
hide_value /sys/module/msm_performance/parameters/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
chattr +i  /sys/module/msm_performance/parameters/cpu_min_freq

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
hide_value $t_message/cpu_nolimit_temp 49500

lock_value 1 /sys/module/perfmgr/parameters/load_scaling_y

core_ctl_preset

rmdir /dev/cpuset/background/untrustedapp
rmdir /dev/cpuset/foreground/boost

# OnePlus
hide_value /proc/oplus_scheduler/sched_assist/sched_impt_task ''
lock_value N /sys/module/oplus_ion_boost_pool/parameters/debug_boost_pool_enable
if [[ -d  /proc/game_opt ]]; then
  hide_value /proc/game_opt/cpu_max_freq '0:2147483647 1:2147483647 2:2147483647 3:2147483647 4:2147483647 5:2147483647 6:2147483647 7:2147483647'
  chmod 444 /proc/game_opt/rt_info
  hide_value /proc/game_opt/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
  # hide_value /proc/game_opt/disable_cpufreq_limit 1
fi
hide_value /proc/task_info/task_sched_info/task_sched_info_enable 0
hide_value /proc/oplus_scheduler/sched_assist/lb_enable 0
hide_value /proc/oplus_scheduler/sched_assist/sched_assist_enabled 0
hide_value /proc/oplus_scheduler/sched_assist/sched_assist_scene 0
lock_value 0 /proc/jank_info/cpu_jank_info/task_track_enable
lock_value 0 /proc/jank_info/cpu_jank_info/clm_enable
set_value '2000' /proc/oplus-votable/GAUGE_UPDATE/force_val
set_value '1' /proc/oplus-votable/GAUGE_UPDATE/force_active
lock_value 2-6 /dev/cpuset/display/cpus
lock_value 2-6 /dev/cpuset/sf/cpus
lock_value 2-6 /dev/cpuset/oiface_bg/cpus
lock_value 2-6 /dev/cpuset/oiface_fg/cpus
lock_value 2-6 /dev/cpuset/oiface_fg+/cpus
lock_value 2-6 /dev/cpuset/h-background/cpus


# MeiZu
if [[ -d /proc/mz_info ]]; then
  echo 4 > /proc/mz_scheduler/vip_task/enabled
  echo 0 > /proc/mz_thermal_dcvs/dcvs_enabled
  echo 0 > /proc/mz_mm_vip/vip_enable
  echo 0 > /proc/mz_frame_sync/enable
  echo 0 > /proc/mz_frame_sync/freq_enable
  # chmod 444 > /proc/mz_frame_sync/ctrl # Boom!
  echo 1 > /proc/mz_lock/enabled
  echo 0 > /proc/mz_freq/adapt_sched_boost/enabled_one
  echo 0 > /proc/mz_freq/adapt_sched_boost/enabled_two
  echo 0 > /proc/mz_freq/adapt_sched_boost/enabled_three
  # echo 0 > /proc/mz_thermal_boost/boost_enabled
  # echo 0 > /proc/mz_thermal_boost/sched_boost_enabled
fi


bus_dcvs(){
  chmod 664 /sys/devices/system/cpu/bus_dcvs/$1/min_freq
  chmod 664 /sys/devices/system/cpu/bus_dcvs/$1/max_freq
  if [[ "$3" != "" ]]; then
    echo $3 > /sys/devices/system/cpu/bus_dcvs/$1/min_freq
  fi
  echo $2 > /sys/devices/system/cpu/bus_dcvs/$1/max_freq
  chmod 444 /sys/devices/system/cpu/bus_dcvs/$1/min_freq
  chmod 444 /sys/devices/system/cpu/bus_dcvs/$1/max_freq
}
bus_dcvs_value() {
  echo $2 > /sys/devices/system/cpu/bus_dcvs/$1
}
bus_dcvs DDR/soc:qcom,memlat:ddr:silver 1555000 547000
bus_dcvs DDR/24091000.qcom,bwmon-ddr 2736000 547000
bus_dcvs DDR/24091000.qcom,bwmon-ddr/sample_ms 10
bus_dcvs DDR/soc:qcom,memlat:ddr:prime 4224000 547000
bus_dcvs DDR/soc:qcom,memlat:ddr:prime-latfloor 4224000 547000
bus_dcvs DDR/soc:qcom,memlat:ddr:gold-compute 1555000 547000
bus_dcvs DDR/soc:qcom,memlat:ddr:gold 4224000 547000
bus_dcvs_value DDR/soc:qcom,memlat:ddr:silver/ipm_ceil 100
bus_dcvs L3/soc:qcom,memlat:l3:silver 2035200 364800
bus_dcvs L3/soc:qcom,memlat:l3:prime 2035200 364800
bus_dcvs L3/soc:qcom,memlat:l3:gold 2035200 364800
bus_dcvs L3/soc:qcom,memlat:l3:prime-compute 2035200 364800
bus_dcvs DDRQOS/soc:qcom,memlat:ddrqos:gold 1 0
bus_dcvs DDRQOS/soc:qcom,memlat:ddrqos:prime 1 0
bus_dcvs DDRQOS/soc:qcom,memlat:ddrqos:prime-latfloor 1 0
bus_dcvs LLCC/soc:qcom,memlat:llcc:gold-compute 600000 300000
bus_dcvs LLCC/240b7400.qcom,bwmon-llcc 806000 300000
bus_dcvs LLCC/soc:qcom,memlat:llcc:silver 600000 300000
bus_dcvs LLCC/soc:qcom,memlat:llcc:gold 1066000 300000


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
