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
echo 80 80 > /sys/devices/system/cpu/cpu6/core_ctl/busy_up_thres
echo 55 55 > /sys/devices/system/cpu/cpu6/core_ctl/busy_down_thres
echo 24 > /sys/devices/system/cpu/cpu6/core_ctl/offline_delay_ms
pgrep kswapd0 > /dev/cpuset/top-app/tasks

# Xiaomi
if [[ -d /proc/mi_display ]]; then
  for dir in /sys/module/migt/parameters /sys/module/metis/parameters /proc/sys/migt /sys/class/misc/migt;do
    if [[ -d $dir ]];then
      for file in `ls $dir`; do
        case "$file" in
          'add_'*)
            chmod 444 $dir/$file
          ;;
          glk_maxfreq)
            lock_value '0 0 0' $dir/$file
          ;;
          min_cluster_freqs|user_min_freq)
            lock_value '0,0,0' $dir/$file
          ;;
          glk_minfreq)
            lock_value "$(c_min 0) $(c_min 4) $(c_min 7)" $dir/$file
          ;;
          migt_ceiling_freq|migt_freq)
            lock_value '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' $dir/$file
          ;;
          # 导致Xiaomi 15上日常会非常激进的使用大核
          mi_fboost_enable)
            set_value 1 $dir/$file
          ;;
          glk_fbreak_enable|force_cluster_sched_enable|glk_freq_limit_start|glk_freq_limit_walt|thermal_break_enable|is_break_enable|mi_freq_enable|force_stask_to_big|freq_break_enable)
            lock_value 0 $dir/$file
          ;;
          render_prefer_cluster|vip_prefer_cluster|stask_prefer_cluster|ip_prefer_cluster)
            lock_value -1 $dir/$file
          ;;
          glk_disable|affinity_only|force_reset_runtime|reset_clus_affinity_uidlist|reset_rebind_task)
            lock_value 1 $dir/$file
          ;;
          game_minfreq_limit|game_maxfreq_limit)
            lock_value '0 0 0' $dir/$file
          ;;
        esac
      done
    fi
  done
fi

# OnePlus
if [[ -d  /proc/game_opt ]]; then
  hide_value /proc/game_opt/cpu_max_freq '0:2147483647 1:2147483647 2:2147483647 3:2147483647 4:2147483647 5:2147483647 6:2147483647 7:2147483647'
  chmod 444 /proc/game_opt/rt_info
  hide_value /proc/game_opt/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
  # hide_value /proc/game_opt/disable_cpufreq_limit 1
  set_value '1000' /proc/oplus-votable/GAUGE_UPDATE/force_val
  set_value '1' /proc/oplus-votable/GAUGE_UPDATE/force_active
  stop horae
  stop thermal-engine
fi

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
fi

exit 0

# 8Elite禁用GPUBoost动画很容易卡顿
kgsl(){
  set_value $2 /sys/class/kgsl/kgsl-3d0/$1
}

pl_max=$(($(cat /sys/class/kgsl/kgsl-3d0/num_pwrlevels)-1))
kgsl thermal_pwrlevel 0
kgsl max_pwrlevel 0
kgsl max_clock_mhz 1100
kgsl max_gpuclk 1100000000
kgsl devfreq/max_freq 1100000000
if [[ ! -d  /proc/game_opt ]]; then
  kgsl min_pwrlevel $pl_max
  kgsl min_pwrlevel $pl_max
  kgsl default_pwrlevel $(($pl_max-1))
  kgsl min_clock_mhz 0
  kgsl devfreq/min_freq 0
fi
