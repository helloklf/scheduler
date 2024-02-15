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

hide_value /sys/module/msm_performance/parameters/cpu_max_freq '0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295'
chattr +i  /sys/module/msm_performance/parameters/cpu_max_freq
hide_value /sys/module/msm_performance/parameters/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
chattr +i  /sys/module/msm_performance/parameters/cpu_min_freq
lock_value 2-6 /dev/cpuset/display/cpus
lock_value 2-6 /dev/cpuset/sf/cpus


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


# OnePlus
# hide_value /proc/oplus_scheduler/sched_assist/sched_impt_task ''
# lock_value N /sys/module/oplus_ion_boost_pool/parameters/debug_boost_pool_enable
if [[ -d  /proc/game_opt ]]; then
  hide_value /proc/game_opt/cpu_max_freq '0:2147483647 1:2147483647 2:2147483647 3:2147483647 4:2147483647 5:2147483647 6:2147483647 7:2147483647'
  # hide_value /proc/game_opt/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
  # hide_value /proc/game_opt/disable_cpufreq_limit 1
fi
# hide_value /proc/task_info/task_sched_info/task_sched_info_enable 0
# hide_value /proc/oplus_scheduler/sched_assist/sched_assist_enabled 0


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
