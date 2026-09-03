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

c_min(){
  echo $(cat /sys/devices/system/cpu/cpufreq/policy*/cpuinfo_min_freq)
}
# Xiaomi
if [[ -d /proc/mi_display ]]; then
  for dir in /sys/module/migt/parameters /sys/module/metis/parameters /proc/sys/migt /sys/class/misc/migt /sys/module/mi_game/parameters;do
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
