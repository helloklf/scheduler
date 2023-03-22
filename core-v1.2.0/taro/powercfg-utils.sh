realme_gt() {
  gt_switch=$(settings get system scene_gt_switch)
  if [[ "$gt_switch" != "1" ]]; then
    return
  fi
  gt=$(settings get system gt_mode_state_setting)
  if [[ "$gt" == "1" || "$gt" == "0" ]] && [[ "$gt" != "$1" ]]; then
    if [[ "$1" == "1" ]]; then
      # GT ON
      action='open'
    elif [[ "$1" == "0" ]]; then
      # GT OFF
      action='close'
    else
      return
    fi
    gt_receiver='com.coloros.oppoguardelf/com.coloros.performance.GTModeBroadcastReceiver'
    # am broadcast -a gt_mode_broadcast_intent_${action}_action -n $gt_receiver -f 0x01000000
    if [[ -n $(pm query-receivers --brief -n $gt_receiver | grep $gt_receiver) ]]; then
      am broadcast -a gt_mode_broadcast_intent_${action}_action -n $gt_receiver -f 0x01000000
    else
      am broadcast -a gt_mode_broadcast_intent_${action}_action -f 0x01000000
    fi
  fi
}

use_retro_mode='0'
retro_mode() {
  if [[ "$use_retro_mode" != "1" ]]; then
    return
  fi

  policy=/sys/devices/system/cpu/cpufreq/policy
  # local down="$1"
  # local up="$2"
  #
  # if [[ "$down" == "" ]]; then
  #   local down="20"
  # fi
  # if [[ "$up" == "" ]]; then
  #   local up="60"
  # fi

  for cluster in 0 4 7; do
    echo $cluster
    echo 'retro' > /cache/cpu_scaling_governor
    umount ${policy}${cluster}/scaling_governor 2>/dev/null
    lock_value 'conservative' ${policy}${cluster}/scaling_governor
    mount /cache/cpu_scaling_governor ${policy}${cluster}/scaling_governor
    # echo $down > ${policy}${cluster}/conservative/down_threshold
    # echo $up > ${policy}${cluster}/conservative/up_threshold
    echo 0 > ${policy}${cluster}/conservative/ignore_nice_load
    echo 1000 > ${policy}${cluster}/conservative/sampling_rate # 1000us = 1ms
    # echo 2 > ${policy}${cluster}/conservative/freq_step
  done

  echo $1 > ${policy}0/conservative/down_threshold
  echo $2 > ${policy}0/conservative/up_threshold
  echo $1 > ${policy}0/conservative/down_threshold

  echo $3 > ${policy}4/conservative/down_threshold
  echo $4 > ${policy}4/conservative/up_threshold
  echo $3 > ${policy}4/conservative/down_threshold

  echo $5 > ${policy}7/conservative/down_threshold
  echo $6 > ${policy}7/conservative/up_threshold
  echo $5 > ${policy}7/conservative/down_threshold
}

conservative_step() {
  if [[ "$use_retro_mode" != "1" ]]; then
    return
  fi

  policy=/sys/devices/system/cpu/cpufreq/policy
  echo $1 > ${policy}0/conservative/freq_step
  echo $2 > ${policy}4/conservative/freq_step
  echo $3 > ${policy}7/conservative/freq_step
}

walt_mode() {
  if [[ "$use_retro_mode" == "1" || "$cpu_governor" != 'walt' ]]; then
    return
  fi
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/walt/down_rate_limit_us
  echo $2 > /sys/devices/system/cpu/cpufreq/policy0/walt/up_rate_limit_us

  echo $3 > /sys/devices/system/cpu/cpufreq/policy4/walt/down_rate_limit_us
  echo $4 > /sys/devices/system/cpu/cpufreq/policy4/walt/up_rate_limit_us

  echo $5 > /sys/devices/system/cpu/cpufreq/policy7/walt/down_rate_limit_us
  echo $6 > /sys/devices/system/cpu/cpufreq/policy7/walt/up_rate_limit_us
}

reset_basic_governor() {
  stop_scene_scheduler

  if [[ "$use_retro_mode" != "1" ]]; then
    # CPU
    governor0=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`
    governor4=`cat /sys/devices/system/cpu/cpufreq/policy4/scaling_governor`
    governor7=`cat /sys/devices/system/cpu/cpufreq/policy7/scaling_governor`

    if [[ ! "$governor0" = $cpu_governor ]]; then
      set_value $cpu_governor /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
    fi
    if [[ ! "$governor4" = $cpu_governor ]]; then
      set_value $cpu_governor /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
    fi
    if [[ ! "$governor7" = $cpu_governor ]]; then
      set_value $cpu_governor /sys/devices/system/cpu/cpufreq/policy7/scaling_governor
    fi
  fi

  set_input_boost_freq 0 0 0 0
}

joyose_db='/data/data/com.xiaomi.joyose/databases/SmartP.db'
joyose_dfps_clear() {
    params='{"header":{"version":"2022121231","network_improve":true,"index_enable":true,"mqs_enable":true},"game_booster":{"booster_enable":true,"cpuset_enable":true,"tuner_enable":true,"monitor":{"monitor_enable":false,"analytics_enable":false,"default_interval":2},"support_motor_app":[],"support_display_refresh_rates":[60,90,120],"support_dynamic_refresh_rate_games":[],"support_highfps_app":[],"scale_app_enable":false,"support_scale_app_list":[],"support_gdpvo_app":[],"support_gt_app":[],"dynamic_fps_global":{"dynamic_fps":"10:120,30:120,35:120,38:120,50:90,52:60","dynamic_fps_M":"10:120,35:120,50:90,52:60"},"migt":[],"booster_config":{"default_config":[],"scene_config":[],"ovrride_config":[]}}}'
    sqlite3 $joyose_db "update cloud_config set params = '$params' where config_name = 'booster_config'"
}
mi_joyose_opt() {
  joyose_opt_ok=0
  if [[ ! -f $joyose_db ]]; then
    # echo 'Joyose Uninstalled!' 1>&2
    joyose_opt_ok=0
  elif [[ $(type sqlite3 | grep  "/sqlite3") == "" ]];then
    if [[ -d "$TOOLKIT" ]];then
      wget -O "$TOOLKIT/sqlite3" https://vtools.oss-cn-beijing.aliyuncs.com/addin/sqlite3 2>/dev/null
      s=`du -k "$TOOLKIT/sqlite3"|awk '{print $1}'`
      if [[ "$s" -gt 256 ]]; then
        chmod 777 "$TOOLKIT/sqlite3" 2>/dev/null
        joyose_opt_ok=1
      else
        rm "$TOOLKIT/sqlite3" 2>/dev/null
        # echo 'Download failed!' 1>&2
        joyose_opt_ok=2
      fi
    else
      # echo 'Sqlite3 binary is required!' 1>&2
      joyose_opt_ok=3
    fi
  else
    joyose_opt_ok=1
  fi
  # echo $joyose_opt_ok > /cache/joyose_opt_ok.log
  if [[ "$joyose_opt_ok" == 1 ]];then
    joyose_dfps_clear
  else
    echo 'Skip ...' $joyose_opt_ok
  fi
}

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

set_input_boost_freq() {
  local c0="$1"
  local c1="$2"
  local c2="$3"
  local ms="$4"
  echo "0:$c0 1:$c0 2:$c0 3:$c0 4:$c1 5:$c1 6:$c1 7:$c2" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
  echo $ms > /sys/devices/system/cpu/cpu_boost/input_boost_ms
  if [[ "$ms" -gt 0 ]]; then
    echo 1 > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input
  else
    echo 0 > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input
  fi
}

set_cpu_freq() {
  echo "0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295" > /sys/module/msm_performance/parameters/cpu_max_freq
  echo "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" > /sys/module/msm_performance/parameters/cpu_min_freq

  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  set_value $2 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq

  set_value $3 /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
  set_value $4 /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
  set_value $3 /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq

  set_value $5 /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
  set_value $6 /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq
  set_value $5 /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
}

set_cpu_pl() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/$cpu_governor/pl
  echo $1 > /sys/devices/system/cpu/cpufreq/policy4/$cpu_governor/pl
  echo $1 > /sys/devices/system/cpu/cpufreq/policy7/$cpu_governor/pl
}

set_hispeed_freq() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/$cpu_governor/hispeed_freq
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/$cpu_governor/hispeed_freq
  echo $3 > /sys/devices/system/cpu/cpufreq/policy7/$cpu_governor/hispeed_freq
}

set_hispeed_load() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/$cpu_governor/hispeed_load
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/$cpu_governor/hispeed_load
  echo $3 > /sys/devices/system/cpu/cpufreq/policy7/$cpu_governor/hispeed_load
}

cpuctl () {
  echo $2 > /dev/cpuctl/$1/cpu.uclamp.sched_boost_no_override
  echo $3 > /dev/cpuctl/$1/cpu.uclamp.latency_sensitive
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
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
    else
      chattr -i "$c_path"
    fi
    chattr -i "$c_path"
    cp -f "$1" "$c_path"
    if [[ "$2" != "" ]]; then
      lock_value "$2" "$1"
    fi
    mount "$c_path" "$1"
  else
    echo "$1" Not Found!
  fi
}

move_to_cpuset() {
  local pid="$1"
  local cpuset="/dev/cpuset/$2/cgroup.procs"
  if [[ "$pid" != "" ]] && [[ -e "$cpuset" ]]; then
    echo $pid > "$cpuset"
  fi
}

stop_scene_scheduler(){
  killall 'scene-scheduler' 2>/dev/null
}
scene_scheduler() {
  SCDIR=${0%/*}
  killall 'scene-scheduler' 2>/dev/null
  # echo $SCDIR/scene-scheduler -c="$SCDIR/profile.json" -p="$1" -m="$2" > /cache/scene-scheduler.log
  $SCDIR/scene-scheduler -p="$1" -m="$2" -c="$SCDIR/profile.json" >/dev/null 2>&1 &
}

adjustment_by_top_app() {
  case "$top_app" in
    # YuanShen
    "com.miHoYo.Yuanshen" | "com.miHoYo.ys.mi" | "com.miHoYo.ys.bilibili" | "com.miHoYo.GenshinImpact")
      realme_gt_on=1
      # set_hispeed_freq 0 0 0
      if [[ "$action" = "powersave" ]]; then
        set_cpu_freq 1075200 1785600 633600 1651200 806400 1958400
      elif [[ "$action" = "balance" ]]; then
        set_cpu_freq 1075200 1785600 633600 1766400 806400 2284800
      elif [[ "$action" = "performance" ]]; then
        cpuctl top-app 0 1 0.00 max
        set_cpu_freq 844800 1785600 633600 2112000 1056000 2400000
      elif [[ "$action" = "fast" ]]; then
        set_cpu_freq 844800 1785600 1113600 2227200 1056000 2822400
        cpuctl top-app 0 1 0.00 max
      fi
    ;;

    # Wang Zhe Rong Yao\LOL
    "com.tencent.lolm"|"com.tencent.tmgp.sgame")
      set_cpu_pl 0
      if [[ "$action" = "powersave" ]]; then
        realme_gt_on=0
      else
        realme_gt_on=1
      fi
    ;;

    "com.dw.h5yvzr.yt"|"com.pwrd.hotta.laohu"|"com.hottagames.hotta.bilibili"|"com.hottagames.hotta.mi")
      realme_gt_on=1
    ;;

    "com.tencent.tmgp.speedmobile")
      realme_gt_on=1
    ;;

    "default")
      echo '未适配的应用'
    ;;
  esac
  scene_scheduler "$top_app" "$action"
}
