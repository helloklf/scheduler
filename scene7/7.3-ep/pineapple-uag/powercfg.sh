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

# OnePlus
if [[ -d  /proc/game_opt ]]; then
  hide_value /proc/game_opt/cpu_max_freq '0:2147483647 1:2147483647 2:2147483647 3:2147483647 4:2147483647 5:2147483647 6:2147483647 7:2147483647'
  chmod 444 /proc/game_opt/rt_info
  hide_value /proc/game_opt/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
  # hide_value /proc/game_opt/disable_cpufreq_limit 1
fi
set_value '2000' /proc/oplus-votable/GAUGE_UPDATE/force_val
set_value '1' /proc/oplus-votable/GAUGE_UPDATE/force_active

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
