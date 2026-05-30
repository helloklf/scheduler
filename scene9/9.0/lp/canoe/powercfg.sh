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

dev_mount=/dev/$(cat /dev/urandom | tr -dc 'a-z_' | head -c 8; echo)
# hide_value /sys/module/task_turbo/parameters/feats [write_value]
hide_value() {
  if [[ -e "$1" ]]; then
    umount "$1" 2>/dev/null
    c_path="$dev_mount${1}"
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

for c in 0 6; do
  lock_value 0 /sys/devices/system/cpu/cpufreq/policy$c/walt/adaptive_high_freq
  lock_value 0 /sys/devices/system/cpu/cpufreq/policy$c/walt/adaptive_low_freq
done
echo 1024 > /proc/sys/kernel/sched_util_clamp_max
# echo 1024 > /proc/sys/kernel/sched_util_clamp_min

hide_value /sys/kernel/msm_performance/parameters/cpu_max_freq '0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295'
chattr +i  /sys/kernel/msm_performance/parameters/cpu_max_freq
hide_value /sys/kernel/msm_performance/parameters/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
chattr +i  /sys/kernel/msm_performance/parameters/cpu_min_freq

t_message=/sys/class/thermal/thermal_message
if [[ -f $t_message/cpu_limits ]]; then
  chmod 664 $t_message/cpu_limits
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
echo $(pgrep -f kcompactd0) > /dev/cpuset/foreground/tasks
echo 80 80 > /sys/devices/system/cpu/cpu6/core_ctl/busy_up_thres
echo 55 55 > /sys/devices/system/cpu/cpu6/core_ctl/busy_down_thres
echo 24 > /sys/devices/system/cpu/cpu6/core_ctl/offline_delay_ms
mkdir /dev/cpuset/top-app/kswapd
echo 0 > /dev/cpuset/top-app/kswapd/mems
echo 6-7 > /dev/cpuset/top-app/kswapd/cpus
pgrep kswapd0 > /dev/cpuset/top-app/kswapd/tasks

c_min(){
  echo $(cat /sys/devices/system/cpu/cpufreq/policy*/cpuinfo_min_freq)
}
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
            lock_value "$(c_min)" $dir/$file
          ;;
          migt_ceiling_freq|migt_freq)
            lock_value '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' $dir/$file
          ;;
          glk_fbreak_enable|force_cluster_sched_enable|glk_freq_limit_start|glk_freq_limit_walt|thermal_break_enable|is_break_enable|mi_freq_enable|force_stask_to_big|freq_break_enable|enable_pkg_monitor|flt_enable_other|flt_in_frame_enable|cluaff_control|override_schedboost_in_coldstart|metis_schlat_enable|limit_bgtask_sched|choose_cpu_exclusive_enable|frame_boost_enable)
            lock_value 0 $dir/$file
          ;;
          flt_deq_ajust_enable|flt_in_frame_enable|flt_preboost_enable|flt_wakeup_enable)
            lock_value 0 $dir/$file
          ;;
          # 导致Xiaomi 15上日常会非常激进的使用大核
          mi_fboost_enable)
            set_value 1 $dir/$file
          ;;
          render_prefer_cluster|vip_prefer_cluster|stask_prefer_cluster|ip_prefer_cluster)
            lock_value -1 $dir/$file
          ;;
          glk_disable|affinity_only|force_reset_runtime|reset_clus_affinity_uidlist|reset_rebind_task|clean_user_group)
            lock_value 1 $dir/$file
          ;;
          game_minfreq_limit|game_maxfreq_limit)
            lock_value '0 0 0' $dir/$file
          ;;
          flt_preboost_cluster_enable)
            lock_value '0,0' $dir/$file
          ;;
          flt_cal_freq_enable|flt_in_frame_enable_cluster)
            lock_value '0,0,0,0' $dir/$file
          ;;
        esac
      done
    fi
  done
  chmod 444 /sys/module/metis/parameters
  chmod 444 /sys/module/migt/parameters
  am force-stop com.xiaomi.joyose
fi

# OnePlus
if [[ -d  /proc/game_opt ]]; then
  hide_value /proc/game_opt/cpu_max_freq '0:2147483647 1:2147483647 2:2147483647 3:2147483647 4:2147483647 5:2147483647 6:2147483647 7:2147483647'
  hide_value /proc/game_opt/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
  # hide_value /proc/game_opt/disable_cpufreq_limit 1
  set_value '1000' /proc/oplus-votable/GAUGE_UPDATE/force_val
  set_value '1' /proc/oplus-votable/GAUGE_UPDATE/force_active
  stop oplusHmbirdBpfManager
  echo -1 > /proc/oplus_hmbird/manager_pid
fi

echo 99 > /proc/sys/walt/walt_rtg_cfs_boost_prio # default 119
echo 1 > /proc/sys/walt/sched_pipeline_util_thres # default 400
echo 1 > /proc/sys/walt/walt_low_latency_task_threshold # default 325
echo '' > /proc/sys/walt/sched_lib_name # default libunity.so, libfb.so
echo '' > /proc/sys/walt/sched_lib_task # default UnityMain
echo 1 > /proc/sys/walt/sched_disable_mvp_thres # default 3000

echo '2361600 2496000 2745600 2745600 3033600' > /proc/sys/walt/cluster0/smart_freq/ipc_freq_levels
echo '3648000 3648000 3859200 3859200 4070400' > /proc/sys/walt/cluster1/smart_freq/ipc_freq_levels
