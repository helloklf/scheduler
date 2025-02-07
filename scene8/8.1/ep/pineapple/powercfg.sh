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
    c_path="/dev/scene${1}"
    if [[ ! -f "$c_path" ]]; then
      mkdir -p "$c_path"
      rm -r "$c_path"
    fi
    cp -f "$1" "$c_path"
    if [[ "$2" != "" ]]; then
      set_value "$2" "$1"
    fi
    mount --bind "$c_path" "$1"
  else
    echo "$1" Not Found!
  fi
}

echo 2265600 3148800 2956800 3302400 > /proc/sys/walt/sched_fmax_cap
for c in 0 2 5 7; do
  lock_value 0 /sys/devices/system/cpu/cpufreq/policy$c/walt/adaptive_high_freq
  lock_value 0 /sys/devices/system/cpu/cpufreq/policy$c/walt/adaptive_low_freq
done
echo 1024 > /proc/sys/kernel/sched_util_clamp_max
echo 1024 > /proc/sys/kernel/sched_util_clamp_min

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

rmdir /dev/cpuset/background/untrustedapp
rmdir /dev/cpuset/foreground/boost
echo $(pgrep -ef kcompactd0) > /dev/cpuset/foreground/tasks

# Xiaomi
if [[ -d /sys/module/migt ]]; then
  echo 1 > /sys/module/migt/parameters/force_reset_runtime
  # lock_value 0 /sys/module/migt/parameters/enable_pkg_monitor
  lock_value 1 /sys/module/migt/parameters/glk_disable
  lock_value 0 /sys/module/migt/parameters/glk_fbreak_enable
  lock_value 0 /sys/module/migt/parameters/force_cluster_sched_enable
  lock_value -1 /sys/module/migt/parameters/render_prefer_cluster
  lock_value -1 /sys/module/migt/parameters/vip_prefer_cluster
  lock_value -1 /sys/module/migt/parameters/stask_prefer_cluster
  lock_value -1 /sys/module/migt/parameters/ip_prefer_cluster
  lock_value 1 /sys/module/migt/parameters/affinity_only
  lock_value 0 /sys/module/migt/parameters/glk_freq_limit_start
  lock_value 0 /sys/module/migt/parameters/glk_freq_limit_walt
  echo '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' > /sys/module/migt/parameters/migt_ceiling_freq
  echo '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' > /sys/module/migt/parameters/migt_freq
fi
if [[ -d /sys/module/metis ]]; then
  echo 1 > /sys/module/metis/parameters/reset_clus_affinity_uidlist
  echo 1 > /sys/module/metis/parameters/reset_rebind_task
  lock_value 0 /sys/module/metis/parameters/thermal_break_enable
  lock_value 0 /sys/module/metis/parameters/is_break_enable
  lock_value 0 /sys/module/metis/parameters/mi_freq_enable
  lock_value '0,0,0' /sys/module/metis/parameters/user_min_freq
  for file in /sys/module/metis/parameters/add*
  do
    chmod 444 $file
  done
fi

# OnePlus
if [[ -d  /proc/game_opt ]]; then
  hide_value /proc/game_opt/cpu_max_freq '0:2147483647 1:2147483647 2:2147483647 3:2147483647 4:2147483647 5:2147483647 6:2147483647 7:2147483647'
  chmod 444 /proc/game_opt/rt_info
  hide_value /proc/game_opt/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
  # hide_value /proc/game_opt/disable_cpufreq_limit 1
fi
set_value '2000' /proc/oplus-votable/GAUGE_UPDATE/force_val
set_value '1' /proc/oplus-votable/GAUGE_UPDATE/force_active


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
  stop traced_probes
  # lock_value 0 /sys/devices/platform/main_touch.0/screen_mode_node

  bus_dcvs DDR/soc:qcom,memlat:ddr:silver 1555000 547000
  bus_dcvs DDR/24091000.qcom,bwmon-ddr 2736000 547000
  bus_dcvs DDR/24091000.qcom,bwmon-ddr/sample_ms 10
  bus_dcvs DDR/soc:qcom,memlat:ddr:prime 4224000 547000
  bus_dcvs DDR/soc:qcom,memlat:ddr:prime-latfloor 4224000 547000
  bus_dcvs DDR/soc:qcom,memlat:ddr:gold-compute 1555000 547000
  bus_dcvs DDR/soc:qcom,memlat:ddr:gold 4224000 547000
  bus_dcvs_value DDR/soc:qcom,memlat:ddr:silver/ipm_ceil 100 # default 400
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
fi

if [[ "$gpu_lock" != "0" ]]; then
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
fi
