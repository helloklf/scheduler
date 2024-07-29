cfg_dir=$(cd $(dirname $0); pwd)

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

lock_value () {
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
    else
      chattr -i "$c_path"
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
    hide_value $migt/glk_minfreq '307200 499200 595200'
    hide_value $migt/migt_ceiling_freq '0 0 0'
    hide_value $migt/glk_disable '1'
    hide_value $migt/mi_freq_enable '0'
    hide_value $migt/force_stask_to_big '0'
    hide_value $migt/glk_fbreak_enable '0'
    hide_value $migt/force_reset_runtime '0'
    lock_value 0 $migt/force_cluster_sched_enable
    lock_value 1 $migt/affinity_only

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
    echo 1 > $metis/reset_clus_affinity_uidlist
    for file in $metis/*enable; do
      hide_value $file 0
    done
    for file in $metis/reset*; do
      hide_value $file 0
    done
    hide_value $metis/cluaff_control 0
    hide_value $metis/in_perf_mod 0
    hide_value $metis/limit_bgtask_sched 0
    echo 0,0,0 > $metis/min_cluster_freqs
    echo 0,0,0 > $metis/user_min_freq
  fi
}

disable_migt

rmdir /dev/cpuset/background/untrustedapp
rmdir /dev/cpuset/foreground/boost

t_message=/sys/class/thermal/thermal_message
if [[ -f $t_message/cpu_limits ]]; then
  for i in $(seq 0 7); do
    maxfreq=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq)
    echo cpu$i $maxfreq > $t_message/cpu_limits
  done
  chmod 444 $t_message/cpu_limits
fi
hide_value $t_message/market_download_limit 0
hide_value $t_message/modem_limit 0
lock_value 0 0 0 0 /sys/class/thermal/thermal_message/boost

lock_value 0 /sys/kernel/fpsgo/fbt/enable_ceiling
if [[ $(cat /proc/version | grep Pandora) == '' ]]; then
  hide_value /sys/kernel/fpsgo/fbt/limit_cfreq 0
  hide_value /sys/kernel/fpsgo/fbt/limit_rfreq 0
  hide_value /sys/kernel/fpsgo/fbt/limit_cfreq_m 0
  hide_value /sys/kernel/fpsgo/fbt/limit_rfreq_m 0
fi
ls /sys/devices/system/cpu/cpu*/online | xargs lock_value 0
echo 0 300000 2000000 > /proc/cpudvfs/cpufreq_debug
echo 4 550000 2850000 > /proc/cpudvfs/cpufreq_debug
echo 7 600000 3250000 > /proc/cpudvfs/cpufreq_debug
lock_value '300000 2000000 550000 2850000 600000 3250000' /proc/powerhal_cpu_ctrl/perfserv_freq
echo 0 > /proc/powerhal_cpu_ctrl/adpf_enable
lock_value 1 /sys/module/mtk_fpsgo/parameters/better_perf

metis=/sys/module/metis/parameters
for file in $metis/*enable*; do
  lock_value 0 $file
done
if [[ -d $metis ]]; then
  chmod -R 444 $metis
fi
