manufacturer=$(getprop ro.product.manufacturer)

a12=false
if [[ $(getprop ro.product.build.version.sdk) -gt 30 ]]; then
  a12=true
fi

# GPU频率表
gpu_freqs=`cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`
# GPU最大频率
gpu_max_freq='840000000'
# GPU最小频率
gpu_min_freq='315000000'
# GPU最小 power level
gpu_min_pl=8
# GPU最大 power level
gpu_max_pl=0

# MaxFrequency, MinFrequency
for freq in $gpu_freqs; do
  if [[ $freq -gt $gpu_max_freq ]]; then
    gpu_max_freq=$freq
  fi;
  if [[ $freq -lt $gpu_min_freq ]]; then
    gpu_min_freq=$freq
  fi;
done

# Power Levels
if [[ -f /sys/class/kgsl/kgsl-3d0/num_pwrlevels ]];then
  gpu_min_pl=`cat /sys/class/kgsl/kgsl-3d0/num_pwrlevels`
  gpu_min_pl=`expr $gpu_min_pl - 1`
fi;
if [[ "$gpu_min_pl" -lt 0 ]];then
  gpu_min_pl=0
fi;

conservative_mode() {
  local policy=/sys/devices/system/cpu/cpufreq/policy
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
    echo 'conservative' > ${policy}${cluster}/scaling_governor
    # echo $down > ${policy}${cluster}/conservative/down_threshold
    # echo $up > ${policy}${cluster}/conservative/up_threshold
    echo 0 > ${policy}${cluster}/conservative/ignore_nice_load
    echo 1000 > ${policy}${cluster}/conservative/sampling_rate # 1000us = 1ms
    echo 2 > ${policy}${cluster}/conservative/freq_step
  done

  echo $1 > ${policy}0/conservative/down_threshold
  echo $2 > ${policy}0/conservative/up_threshold
  echo $1 > ${policy}0/conservative/down_threshold
  echo $2 > ${policy}0/conservative/up_threshold

  echo $3 > ${policy}4/conservative/down_threshold
  echo $4 > ${policy}4/conservative/up_threshold
  echo $3 > ${policy}4/conservative/down_threshold
  echo $4 > ${policy}4/conservative/up_threshold

  echo $5 > ${policy}7/conservative/down_threshold
  echo $6 > ${policy}7/conservative/up_threshold
  echo $5 > ${policy}7/conservative/down_threshold
  echo $6 > ${policy}7/conservative/up_threshold
}

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

core_online=(1 1 1 1 1 1 1 1)
set_core_online() {
  for index in 0 1 2 3 4 5 6 7; do
    core_online[$index]=`cat /sys/devices/system/cpu/cpu$index/online`
    echo 1 > /sys/devices/system/cpu/cpu$index/online
  done
}
restore_core_online() {
  for i in "${!core_online[@]}"; do
     echo ${core_online[i]} > /sys/devices/system/cpu/cpu$i/online
  done
}

reset_basic_governor() {
  stop_scene_scheduler
  set_core_online

  # CPU
  governor0=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`
  governor4=`cat /sys/devices/system/cpu/cpufreq/policy4/scaling_governor`
  governor7=`cat /sys/devices/system/cpu/cpufreq/policy7/scaling_governor`

  if [[ ! "$governor0" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
  fi
  if [[ ! "$governor4" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
  fi
  if [[ ! "$governor7" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy7/scaling_governor
  fi

  # GPU
  gpu_governor=`cat /sys/class/kgsl/kgsl-3d0/devfreq/governor`
  if [[ ! "$gpu_governor" = "msm-adreno-tz" ]]; then
    echo 'msm-adreno-tz' > /sys/class/kgsl/kgsl-3d0/devfreq/governor
  fi
  echo $gpu_max_freq > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
  echo $gpu_min_freq > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
  echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  echo $gpu_max_pl > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  echo 100 > /sys/class/kgsl/kgsl-3d0/devfreq/mod_percent
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
      joyose_opt_ok=4
  fi
  # echo $joyose_opt_ok > /cache/joyose_opt_ok.log
  if [[ "$joyose_opt_ok" == 1 ]];then
    joyose_dfps_clear
  fi
}

bw_down() {
  local path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  local down1="$1"
  local down2="$2"
  cat $path/available_frequencies | awk -F ' ' "{print \$(NF-$down1)}" > $path/max_freq

  local path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  cat $path/available_frequencies | awk -F ' ' "{print \$(NF-$down2)}" > $path/max_freq
}

bw_min() {
  local path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq

  local path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq

  local path='/sys/class/devfreq/1d84000.ufshc'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq
}

bw_max() {
  local path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq

  local path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq

  local path='/sys/class/devfreq/1d84000.ufshc'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq
}

bw_lock() {
  local path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  local down1="$1"
  local down2="$2"
  bw_1=$(cat $path/available_frequencies | awk -F ' ' "{print \$(NF-$down1)}")
  echo $bw_1 > $path/min_freq
  echo $bw_1 > $path/max_freq
  echo $bw_1 > $path/min_freq

  local path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  bw_2=$(cat $path/available_frequencies | awk -F ' ' "{print \$(NF-$down2)}")
  echo $bw_2 > $path/min_freq
  echo $bw_2 > $path/max_freq
  echo $bw_2 > $path/min_freq
}

bw_max_always() {
  local path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  local b_max=`cat $path/available_frequencies | awk -F ' ' '{print $NF}'`
  echo $b_max > $path/min_freq
  echo $b_max > $path/max_freq
  echo $b_max > $path/min_freq

  local path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  local b_max=`cat $path/available_frequencies | awk -F ' ' '{print $NF}'`
  echo $b_max > $path/min_freq
  echo $b_max > $path/max_freq
  echo $b_max > $path/min_freq

  local path='/sys/class/devfreq/1d84000.ufshc'
  local b_max=`cat $path/available_frequencies | awk -F ' ' '{print $NF}'`
  echo $b_max > $path/min_freq
  echo $b_max > $path/max_freq
  echo $b_max > $path/min_freq
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
  # echo "0:$1 1:$1 2:$1 3:$1 4:$3 5:$3 6:$3 7:$5" > /sys/module/msm_performance/parameters/cpu_min_freq
  echo "0:$2 1:$2 2:$2 3:$2 4:$4 5:$4 6:$4 7:$6" > /sys/module/msm_performance/parameters/cpu_max_freq
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  echo $2 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
  echo $3 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
  echo $4 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
  echo $5 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
  echo $6 > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq
}

sched_config() {
  echo "$1" > /proc/sys/kernel/sched_downmigrate
  echo "$2" > /proc/sys/kernel/sched_upmigrate
  echo "$1" > /proc/sys/kernel/sched_downmigrate
  echo "$2" > /proc/sys/kernel/sched_upmigrate

  echo "$3" > /proc/sys/kernel/sched_group_downmigrate
  echo "$4" > /proc/sys/kernel/sched_group_upmigrate
  echo "$3" > /proc/sys/kernel/sched_group_downmigrate
  echo "$4" > /proc/sys/kernel/sched_group_upmigrate
}

sched_limit() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
  echo $2 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
  echo $3 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/down_rate_limit_us
  echo $4 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us
  echo $5 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/down_rate_limit_us
  echo $6 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/up_rate_limit_us
}

set_cpu_pl() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/pl
  echo $1 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/pl
  echo $1 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/pl
}

set_gpu_max_freq () {
  echo $1 > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
  local pl=-1

  for freq in $gpu_freqs; do
    local pl=$((pl + 1))
    if [[ $freq -lt $1 ]] || [[ $freq == $1 ]]; then
      break
    fi;
  done
  if [[ $pl -gt -1 ]]; then
    echo $pl > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  fi
}

set_gpu_min_freq() {
  index=$1

  # GPU频率表
  gpu_freqs=`cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`

  target_freq=$(echo $gpu_freqs | awk "{print \$${index}}")
  if [[ "$target_freq" != "" ]]; then
    echo $target_freq > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
  fi

  # gpu_max_freq=`cat /sys/class/kgsl/kgsl-3d0/devfreq/max_freq`
  # gpu_min_freq=`cat /sys/class/kgsl/kgsl-3d0/devfreq/min_freq`
  # echo "Frequency: ${gpu_min_freq} ~ ${gpu_max_freq}"
}

ctl_on() {
  echo 1 > /sys/devices/system/cpu/$1/core_ctl/enable
  if [[ "$2" != "" ]]; then
    echo $2 > /sys/devices/system/cpu/$1/core_ctl/min_cpus
  else
    echo 0 > /sys/devices/system/cpu/$1/core_ctl/min_cpus
  fi
}

ctl_off() {
  echo 0 > /sys/devices/system/cpu/$1/core_ctl/enable
}

cpu7_core_ctl(){
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  if [[ "$1" == "on" ]];then
    echo 10 > $cpu7_core_ctl_dir/offline_delay_ms
    echo 1 > $cpu7_core_ctl_dir/not_preferred
    echo 1 > $cpu7_core_ctl_dir/enable
    echo 1 > $cpu7_core_ctl_dir/max_cpus
    echo 0 > $cpu7_core_ctl_dir/min_cpus
    # echo 1 > $cpu7_core_ctl_dir/nr_prev_assist_thresh
    echo 1 > $cpu7_core_ctl_dir/task_thres
    echo 27 > $cpu7_core_ctl_dir/busy_down_thres
    echo 50 > $cpu7_core_ctl_dir/busy_up_thres
  else
    echo 0 > $cpu7_core_ctl_dir/enable
  fi
}
cpu4_core_ctl(){
  cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
  if [[ "$1" == "on" ]];then
    echo 20 > $cpu4_core_ctl_dir/offline_delay_ms
    echo 1 > $cpu4_core_ctl_dir/not_preferred
    echo 1 > $cpu4_core_ctl_dir/enable
    echo 3 > $cpu4_core_ctl_dir/max_cpus
    echo 0 > $cpu4_core_ctl_dir/min_cpus
    # echo 4294967295 > $cpu4_core_ctl_dir/nr_prev_assist_thresh
    echo 3 > $cpu4_core_ctl_dir/task_thres
    echo 20 > $cpu4_core_ctl_dir/busy_down_thres
    echo 35 > $cpu4_core_ctl_dir/busy_up_thres
  else
    echo 0 > $cpu4_core_ctl_dir/enable
  fi
}
cpu0_core_ctl(){
  cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
  if [[ "$1" == "on" ]];then
    echo 100 > $cpu0_core_ctl_dir/offline_delay_ms
    echo 0 1 1 1 > $cpu0_core_ctl_dir/not_preferred
    echo 1 > $cpu0_core_ctl_dir/enable
    echo 4 > $cpu0_core_ctl_dir/max_cpus
    echo 1 > $cpu0_core_ctl_dir/min_cpus
    # echo 4294967295 > $cpu0_core_ctl_dir/nr_prev_assist_thresh
    # echo 3 > $cpu0_core_ctl_dir/task_thres
    echo 10 > $cpu0_core_ctl_dir/busy_down_thres
    echo 20 > $cpu0_core_ctl_dir/busy_up_thres
  else
    echo 0 > $cpu0_core_ctl_dir/enable
  fi
}

set_ctl() {
  echo $2 > /sys/devices/system/cpu/$1/core_ctl/busy_up_thres
  echo $3 > /sys/devices/system/cpu/$1/core_ctl/busy_down_thres
  echo $4 > /sys/devices/system/cpu/$1/core_ctl/offline_delay_ms
}

set_hispeed_freq() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_freq
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/hispeed_freq
  echo $3 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/hispeed_freq
}

set_hispeed_load() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_load
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/hispeed_load
  echo $3 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/hispeed_load
}

sched_boost() {
  echo $1 > /proc/sys/kernel/sched_boost_top_app
  echo $2 > /proc/sys/kernel/sched_boost
}

stune_top_app() {
  echo $1 > /dev/stune/top-app/schedtune.prefer_idle
  echo $2 > /dev/stune/top-app/schedtune.boost
}

cpuctl () {
  echo $2 > /dev/cpuctl/$1/cpu.uclamp.sched_boost_no_override
  echo $3 > /dev/cpuctl/$1/cpu.uclamp.latency_sensitive
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
}
mk_stune () {
  mkdir -p "/dev/stune/$1"
  echo $2 > "/dev/stune/$1/schedtune.prefer_idle"
  echo $3 > "/dev/stune/$1/schedtune.boost"
}
mk_cpuctl () {
  mkdir -p "/dev/cpuctl/$1"
  echo $2 > /dev/cpuctl/$1/cpu.uclamp.sched_boost_no_override
  echo $3 > /dev/cpuctl/$1/cpu.uclamp.latency_sensitive
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
}

cpuset() {
  echo $1 > /dev/cpuset/background/cpus
  echo $2 > /dev/cpuset/system-background/cpus
  echo $3 > /dev/cpuset/foreground/cpus
  echo $4 > /dev/cpuset/top-app/cpus
  # Mi
  set_value 0-7 /dev/cpuset/game/cpus
  set_value 0-7 /dev/cpuset/gamelite/cpus
}

# [min/max/def] pl(number)
set_gpu_pl(){
  echo $2 > /sys/class/kgsl/kgsl-3d0/${1}_pwrlevel
}

# GPU MinPowerLevel To Up
gpu_pl_up() {
  local offset="$1"
  if [[ "$offset" != "" ]] && [[ ! "$offset" -gt "$gpu_min_pl" ]]; then
    echo `expr $gpu_min_pl - $offset` > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  elif [[ "$offset" -gt "$gpu_min_pl" ]]; then
    echo 0 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  else
    echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  fi
}

# GPU MinPowerLevel To Down
gpu_pl_down() {
  local offset="$1"
  if [[ "$offset" != "" ]] && [[ ! "$offset" -gt "$gpu_min_pl" ]]; then
    echo $offset > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  elif [[ "$offset" -gt "$gpu_min_pl" ]]; then
    echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  else
    echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  fi
}

lock_value () {
  chmod 644 $2
  echo $1 > $2
  chmod 444 $2
}

disable_migt() {
  migt=/sys/module/migt/parameters
  if [[ -d $migt ]]; then
    lock_value '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' $migt/migt_freq
    lock_value 0 $migt/glk_freq_limit_start
    lock_value 0 $migt/glk_freq_limit_walt
    lock_value '0 0 0' $migt/glk_maxfreq
    lock_value '300000 710400 844800' $migt/glk_minfreq
    lock_value '0 0 0' $migt/migt_ceiling_freq
    lock_value 1 $migt/glk_disable

    settings put secure speed_mode_enable 1
  fi
}

clear_app_data() {
  if [[ "$1" != "" ]];then
    # pm clear $1
    rm -f /data/data/$1/databases/*
    rm -rf /data/data/$1/files/*
    rm -rf /data/data/$1/shared_prefs/*
    killall $1 2>/dev/null
    am force-stop $1
  fi
}

uninstall_mi_opt() {
  # if [[ $(pm list packages --user 0 com.miui.daemon) != "" ]] || [[ $(pm list packages --user 0 com.xiaomi.joyose) != "" ]]; then
  #   clear_app_data com.miui.powerkeeper
  #   clear_app_data com.xiaomi.powerchecker
  # fi
  # pm uninstall --user 0 -k com.miui.daemon >/dev/null 2>&1
  # pm uninstall --user 0 -k com.xiaomi.joyose >/dev/null 2>&1
  pm uninstall --user 0 com.miui.daemon >/dev/null 2>&1
  pm uninstall --user 0 com.xiaomi.joyose >/dev/null 2>&1
}

reinstall_mi_opt() {
  uninstall_mi_opt
  pm install-existing --user 0 com.miui.daemon >/dev/null 2>&1
  pm install-existing --user 0 com.xiaomi.joyose >/dev/null 2>&1
}

# set_task_affinity $pid $use_cores[cpu7~cpu0]
set_task_affinity() {
  pid=$1
  if [[ "$pid" != "" ]]; then
    mask=`echo "obase=16;$((num=2#$2))" | bc`
    for tid in $(ls "/proc/$pid/task/"); do
      taskset -p "$mask" "$tid" 1>/dev/null
    done
    taskset -p "$mask" "$pid" 1>/dev/null
  fi
}

tcp_low_latency() {
  if [[ "$1" == '1' ]]; then
    echo 1 > /proc/sys/net/ipv4/tcp_low_latency
    echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle
  else
    echo 0 > /proc/sys/net/ipv4/tcp_low_latency
    echo 1 > /proc/sys/net/ipv4/tcp_slow_start_after_idle
  fi
}

# Unity'Games
unity_opt_run () {
  local current_app=$top_app

  # mask=`echo "obase=16;$((num=2#11110000))" | bc` # F0 (cpu 7-4)
  # mask=`echo "obase=16;$((num=2#10000000))" | bc` # 80 (cpu 7)
  # mask=`echo "obase=16;$((num=2#01110000))" | bc` # 70 (cpu 6-4)
  # mask=`echo "obase=16;$((num=2#01111111))" | bc` # 7F (cpu 6-0)

  ps -ef -o PID,NAME | grep -e "$current_app$" | egrep -o '[0-9]{1,}' | while read pid; do
    for tid in $(ls "/proc/$pid/task/"); do
      if [[ "$tid" == "$pid" ]]; then
        taskset -p "FF" "$tid" > /dev/null 2>&1
        continue
      fi
      if [[ -f "/proc/$pid/task/$tid/comm" ]]; then
        comm=$(cat /proc/$pid/task/$tid/comm)

        case "$comm" in
          "RenderThread"*|"UnityMain")
            taskset -p "80" "$tid" > /dev/null 2>&1
          ;;
          "UnityGfxDevice"*|"UnityMultiRende"*)
            taskset -p "F0" "$tid" > /dev/null 2>&1
          ;;
        esac
      fi
    done
  done
}

move_to_cpuset() {
  local pid="$1"
  local cpuset="/dev/cpuset/$2/cgroup.procs"
  if [[ "$pid" != "" ]] && [[ -e "$cpuset" ]]; then
    echo $pid > "$cpuset"
  fi
}

# Check whether the taskset command is useful
taskset_test() {
  local pid="$1"
  if [[ "$pid" == "" ]]; then
    return 2
  fi

  # Compatibility Test
  any_tid=$(ls /proc/$pid/task | head -n 1)
  if [[ "$any_tid" != "" ]]; then
    test_fail=$(taskset -p ff $any_tid 2>&1 | grep 'Operation not permitted')
    if [[ "$test_fail" != "" ]]; then
      echo 'taskset Cannot run on your device!' 1>&2
      return 0
    fi
  fi
  return 1
}

# watch_app [on_tick] [on_change]
watch_app() {
  local interval=120
  local on_tick="$1"
  local on_change="$2"
  local app=$top_app
  local current_pid=$$

  if [[ "$on_tick" == "" ]] || [[ "$app" == "" ]]; then
    return
  fi

  if [[ "$task" != "" ]]; then
    pgrep -f com.omarea.*powercfg.sh | grep -v $current_pid | while read pid; do
      local cmdline=$(cat /proc/$pid/cmdline | grep -a task)
      if [[ "$cmdline" != '' ]] && [[ $(echo $cmdline | grep $task) == '' ]];then
        kill -9 $pid 2> /dev/null
      fi
    done
  fi

  if [[ $(getprop vtools.powercfg_app) == "$app" ]]; then
    $on_tick
  fi

  ticks=0
  while true
  do
    if [[ $ticks -gt 3 ]]; then
      sleep $interval
    elif [[ $ticks -gt 0 ]]; then
      sleep 30
    else
      sleep 10
    fi
    ticks=$((ticks + 1))

    current=$(getprop vtools.powercfg_app)
    if [[ "$current" == "$app" ]]; then
      $on_tick
    else
      if [[ "$on_change" ]]; then
        $on_change $current
      fi
      return
    fi
  done
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
       # ctl_off cpu4
       # ctl_off cpu7
       set_hispeed_freq 0 0 0
       cpuctl background 1 0 0 0
       if [[ "$action" = "powersave" ]]; then
         # if [[ "$manufacturer" == "Xiaomi" ]]; then
         #   # conservative_mode 47 59 69 85 69 85
         #   bw_min
         #   bw_down 3 3
         # else
         #   sched_limit 10000 0 0 5000 0 0
         # fi
         bw_lock 3 3
         sched_limit 0 0 0 3000 0 3000
         sched_boost 0 0
         stune_top_app 0 0
         sched_config "70 53" "98 68" "300" "400"
         set_cpu_freq 1804800 1804800 710400 1670400 844800 1670400
         # set_gpu_max_freq 443000000
         set_gpu_max_freq 491000000
       elif [[ "$action" = "balance" ]]; then
         # if [[ "$manufacturer" == "Xiaomi" ]]; then
         #   # conservative_mode 42 57 68 84 69 83
         #   bw_min
         #   bw_down 2 2
         # else
         #   sched_limit 10000 0 0 5000 0 0
         # fi
         sched_limit 0 0 0 3000 0 3000
         bw_lock 2 2
         sched_boost 0 0
         stune_top_app 0 0
         sched_config "55 49" "72 65" "300" "400"
         set_cpu_freq 1036800 1804800 960000 1766400 844800 2265600
         # set_gpu_max_freq 676000000
         set_gpu_max_freq 540000000
       elif [[ "$action" = "performance" ]]; then
         # bw_max_always
         # if [[ "$manufacturer" == "Xiaomi" ]]; then
         #   # conservative_mode 45 60 70 89 71 89
         #   bw_max
         # fi
         bw_lock 1 1
         sched_boost 0 0
         stune_top_app 0 0
         cpuctl top-app 1 0 0.05 max
         set_cpu_freq 806400 1804800 710400 2419200 844800 2841600
         sched_limit 5000 0 0 2000 0 500
         sched_config "65 55" "75 68" "200" "400"
         # set_gpu_max_freq 738000000
         set_gpu_max_freq 608000000
       elif [[ "$action" = "fast" ]]; then
         bw_max_always
         if [[ "$manufacturer" == "Xiaomi" ]]; then
           # conservative_mode 45 55 54 70 59 72
           bw_max
         fi
         sched_boost 0 0
         stune_top_app 0 55
         sched_config "62 40" "70 52" "300" "400"
         # set_gpu_max_freq 778000000
         set_gpu_max_freq 738000000
       fi
       cpuset '0' '0' '0-7' '0-7'
       # scene_scheduler "$top_app" "$action"
    ;;

    # Benchmark
    "com.primatelabs.geekbench" | "com.primatelabs.geekbench5")
      sched_limit 50000 0 50000 0 50000 0
      sched_config "50 52" "65 68" "70" "90"
      sched_boost 0 0
      stune_top_app 0 100
    ;;

    # Project SEKAI
    "com.hermes.mk.asia"|"com.sega.pjsekai")
      realme_gt_on=1
      if [[ "$action" == "powersave" ]]; then
        sched_boost 1 2
        stune_top_app 1 0
        sched_config "50 55" "70 70" "85" "100"
      elif [[ "$action" == "balance" ]]; then
        sched_boost 1 2
        stune_top_app 1 0
        sched_config "50 52" "65 68" "85" "100"
      elif [[ "$action" == "performance" ]]; then
        sched_boost 1 2
        stune_top_app 1 0
        sched_config "45 52" "55 65" "85" "100"
      else
        sched_boost 1 2
        stune_top_app 1 10
        sched_config "45 48" "55 60" "85" "100"
      fi
    ;;

    # LOL | Wang Zhe Rong Yao
    "com.tencent.lolm"|"com.tencent.tmgp.sgame")
      # ctl_off cpu4
      # ctl_off cpu7
      set_cpu_pl 0
      tcp_low_latency 1
      if [[ "$action" = "powersave" ]]; then
        # conservative_mode 58 70 75 90 69 82
        sched_limit 10000 0 0 5000 0 0
        sched_boost 0 0
        stune_top_app 0 0
        set_cpu_freq 806400 1708800 844800 1766400 844800 1785600
        # set_gpu_max_freq 540000000
        set_gpu_max_freq 491000000
        cpuset '0-1' '0-1' '0-7' '0-7'
        sched_config "60 55" "78 70" "300" "400"
        realme_gt_on=0
      elif [[ "$action" = "balance" ]]; then
        # conservative_mode 53 68 70 85 69 82
        sched_limit 10000 0 0 2000 0 0
        sched_boost 0 0
        stune_top_app 0 0
        set_cpu_freq 1036800 1708800 960000 1996800 844800 2035200
        set_gpu_max_freq 676000000
        cpuset '0-1' '0-1' '0-7' '0-7'
        sched_config "60 52" "72 68" "300" "400"
        realme_gt_on=1
      elif [[ "$action" = "performance" ]]; then
        # conservative_mode 50 65 69 80 67 80
        sched_limit 10000 0 1000 0 0 0
        sched_boost 1 0
        stune_top_app 0 0
        set_cpu_freq 1036800 1708800 960000 2419200 844800 2841600
        set_gpu_max_freq 738000000
        cpuset '0-1' '0-1' '0-7' '0-7'
        sched_config "62 49" "72 60" "200" "400"
        realme_gt_on=1
      elif [[ "$action" = "fast" ]]; then
        # conservative_mode 40 58 54 70 60 72
        sched_limit 10000 0 2000 0 0 0
        sched_boost 1 2
        stune_top_app 1 55
        set_gpu_max_freq 778000000
        cpuset '0-1' '0-1' '0-7' '0-7'
        sched_config "62 35" "70 50" "300" "400"
        realme_gt_on=1
      fi
    ;;

    # ShuangShengShiJie
    "com.bilibili.gcg2.bili")
        if [[ "$action" = "powersave" ]]; then
          gpu_pl_down 5
        elif [[ "$action" = "balance" ]]; then
          gpu_pl_down 3
        elif [[ "$action" = "performance" ]]; then
          gpu_pl_down 1
        elif [[ "$action" = "fast" ]]; then
          gpu_pl_down 0
        fi
        sched_config "60 68" "68 72" "140" "200"
        stune_top_app 0 0
        sched_boost 1 0
        cpuset '0-1' '0-3' '0-7' '0-7'
    ;;

    "com.tencent.tmgp.speedmobile")
      realme_gt_on=1
      cpuset '0' '0' '0-7' '0-7'
      # scene_scheduler "$top_app" "$action"
    ;;

    "com.dw.h5yvzr.yt"|"com.pwrd.hotta.laohu"|"com.hottagames.hotta.bilibili"|"com.hottagames.hotta.mi")
      realme_gt_on=1
      cpuset '0' '0' '0-7' '0-7'
      # scene_scheduler "$top_app" "$action"
    ;;

    "com.android.packageinstaller")
      realme_gt_on=2
    ;;

    "default")
      echo '未适配的应用'
    ;;
  esac
  scene_scheduler "$top_app" "$action"
}