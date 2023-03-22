# GPU频率表
gpu_freqs=`cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`
# GPU最大频率
gpu_max_freq='585000000'
# GPU最小频率
gpu_min_freq='257000000'
# GPU最小 power level
gpu_min_pl=5
# GPU最大 power level
gpu_max_pl=0

# MaxFrequency、MinFrequency
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
fi

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

reset_basic_governor() {
  stop_scene_scheduler

  # echo $gpu_max_freq > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
  set_value $gpu_min_freq /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
  set_value $gpu_min_pl /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  set_value $gpu_min_pl /sys/class/kgsl/kgsl-3d0/def_pwrlevel
  set_value $gpu_max_pl /sys/class/kgsl/kgsl-3d0/max_pwrlevel
}

bw_min() {
  local path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq

  local path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq
}

bw_max() {
  local path='/sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq

  local path='/sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq
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

set_cpu_freq() {
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

ufshc_perf(){
  if [[ "$1" == "on" ]];then
    echo 0 > /sys/devices/platform/soc/1d84000.ufshc/clkscale_enable
    echo 0 > /sys/devices/platform/soc/1d84000.ufshc/clkgate_enable
    # echo 0 > /sys/devices/platform/soc/1d84000.ufshc/hibern8_on_idle_enable
    echo 300000000 > /sys/class/devfreq/1d84000.ufshc/min_freq
  else
    echo 1 > /sys/devices/platform/soc/1d84000.ufshc/clkscale_enable
    echo 1 > /sys/devices/platform/soc/1d84000.ufshc/clkgate_enable
    # echo 1 > /sys/devices/platform/soc/1d84000.ufshc/hibern8_on_idle_enable
    echo 37500000 > /sys/class/devfreq/1d84000.ufshc/min_freq
  fi
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

cpu7_core_ctl(){
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  if [[ "$1" == "on" ]];then
    echo 50 > $cpu7_core_ctl_dir/offline_delay_ms
    echo 1 > $cpu7_core_ctl_dir/not_preferred
    echo 1 > $cpu7_core_ctl_dir/enable
    echo 1 > $cpu7_core_ctl_dir/max_cpus
    echo 0 > $cpu7_core_ctl_dir/min_cpus
    # echo 1 > $cpu7_core_ctl_dir/nr_prev_assist_thresh
    echo 1 > $cpu7_core_ctl_dir/task_thres
    echo 20 > $cpu7_core_ctl_dir/busy_down_thres
    echo 40 > $cpu7_core_ctl_dir/busy_up_thres
  else
    echo 0 > $cpu7_core_ctl_dir/enable
  fi
}
cpu4_core_ctl(){
  cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
  if [[ "$1" == "on" ]];then
    echo 50 > $cpu4_core_ctl_dir/offline_delay_ms
    echo 1 1 1 > $cpu4_core_ctl_dir/not_preferred
    echo 1 > $cpu4_core_ctl_dir/enable
    echo 3 > $cpu4_core_ctl_dir/max_cpus
    echo 0 > $cpu4_core_ctl_dir/min_cpus
    # echo 4294967295 > $cpu4_core_ctl_dir/nr_prev_assist_thresh
    echo 3 > $cpu4_core_ctl_dir/task_thres
    echo 15 > $cpu4_core_ctl_dir/busy_down_thres
    echo 20 > $cpu4_core_ctl_dir/busy_up_thres
  else
    echo 0 > $cpu4_core_ctl_dir/enable
  fi
}
cpu0_core_ctl(){
  cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
  if [[ "$1" == "on" ]];then
    echo 50 > $cpu0_core_ctl_dir/offline_delay_ms
    echo 0 1 1 1 > $cpu0_core_ctl_dir/not_preferred
    echo 1 > $cpu0_core_ctl_dir/enable
    echo 4 > $cpu0_core_ctl_dir/max_cpus
    echo 1 > $cpu0_core_ctl_dir/min_cpus
    # echo 4294967295 > $cpu0_core_ctl_dir/nr_prev_assist_thresh
    # echo 3 > $cpu0_core_ctl_dir/task_thres
    echo 15 > $cpu0_core_ctl_dir/busy_down_thres
    echo 20 > $cpu0_core_ctl_dir/busy_up_thres
  else
    echo 0 > $cpu0_core_ctl_dir/enable
  fi
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

# set_task_affinity $pid $use_cores[cpu7~cpu0]
set_task_affinity() {
  pid=$1
  mask=`echo "obase=16;$((num=2#$2))" | bc`
  for tid in $(ls "/proc/$pid/task/"); do
    taskset -p "$mask" "$tid" 1>/dev/null
  done
  taskset -p "$mask" "$pid" 1>/dev/null
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
    # GenshinImpact
    "com.miHoYo.Yuanshen" | "com.miHoYo.ys.mi" | "com.miHoYo.ys.bilibili" | "com.miHoYo.GenshinImpact")
      # ctl_off cpu4
      # ctl_off cpu7
      set_hispeed_freq 0 0 0
      realme_gt_on=1
      if [[ "$action" = "powersave" ]]; then
        sched_boost 0 0
        stune_top_app 0 0
        sched_config "70 53" "98 68" "300" "400"
        gpu_pl_down 4
        set_cpu_freq 1612800 1804800 825600 1766400 1075200 2457600
        sched_limit 10000 0 0 5000 0 1000
        cpuset '0' '0' '0-7' '0-7'
      elif [[ "$action" = "balance" ]]; then
        sched_boost 0 0
        stune_top_app 0 0
        sched_config "60 57" "87 72" "300" "400"
        gpu_pl_down 2
        set_cpu_freq 1075200 1804800 1056000 2054400 1075200 2841600
        sched_limit 10000 0 0 5000 0 1000
        cpuset '0' '0-1' '0-7' '0-7'
      elif [[ "$action" = "performance" ]]; then
        sched_boost 0 0
        stune_top_app 0 10
        gpu_pl_down 0
        set_cpu_freq 1075200 1804800 1056000 2419200 1075200 3200000
        sched_limit 5000 0 5000 0 5000 0
        cpuset '0-1' '0-3' '0-7' '0-7'
      elif [[ "$action" = "fast" ]]; then
        sched_boost 0 0
        stune_top_app 0 50
        sched_limit 5000 0 10000 0 5000 0
        # sched_config "40 60" "50 75" "120" "150"
        cpuset '0-1' '0-3' '0-7' '0-7'
      fi
      # scene_scheduler "$top_app" "$action"
    ;;

    # Benchmark
    "com.primatelabs.geekbench" | "com.primatelabs.geekbench5")
      sched_limit 50000 0 50000 0 50000 0
      sched_config "50 52" "65 68" "70" "90"
      sched_boost 0 0
      stune_top_app 0 100
    ;;

    # pubg
    "com.tencent.tmgp.pubgmhd" | "com.tencent.ig")
      cpuset '0-1' '0-3' '0-7' '0-7'
      set_hispeed_freq 0 0 0
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

    # Wang Zhe Rong Yao
    "com.tencent.tmgp.sgame")
      # ctl_off cpu4
      # ctl_on cpu7
      if [[ "$action" = "powersave" ]]; then
        sched_config "52 55" "69 67" "300" "400"
        sched_boost 1 0
        stune_top_app 0 0
        cpuset '0-1' '0-1' '0-3' '0-7'
        set_hispeed_freq 0 1382400 1305600
        realme_gt_on=0
      elif [[ "$action" = "balance" ]]; then
        sched_config "50 55" "65 65" "300" "400"
        sched_boost 1 0
        stune_top_app 0 1
        cpuset '0-1' '0-1' '0-6' '0-7'
        set_hispeed_freq 0 1670400 1305600
        realme_gt_on=1
      elif [[ "$action" = "performance" ]]; then
        sched_config "45 55" "55 65" "300" "400"
        sched_boost 1 0
        stune_top_app 1 10
        cpuset '0-1' '0-1' '0-6' '0-7'
        realme_gt_on=1
      elif [[ "$action" = "fast" ]]; then
        sched_config "40 55" "50 63" "300" "400"
        cpuset '0-1' '0-1' '0-6' '0-7'
        sched_boost 1 0
        stune_top_app 1 20
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
      cpuset '0-1' '0-3' '0-3' '0-7'
    ;;

    # NeteaseCloudMusic, KuGou, KuGou Lite
    "com.netease.cloudmusic" | "com.kugou.android" | "com.kugou.android.lite")
      echo 0-6 > /dev/cpuset/foreground/cpus
    ;;

    "com.pwrd.hotta.laohu"|"com.hottagames.hotta.bilibili"|"com.hottagames.hotta.mi")
      realme_gt_on=1
      cpuset '0' '0' '0-7' '0-7'
      # scene_scheduler "$top_app" "$action"
    ;;

    "com.tencent.tmgp.speedmobile")
      realme_gt_on=1
      cpuset '0' '0' '0-7' '0-7'
      # scene_scheduler "$top_app" "$action"
    ;;

    "com.android.packageinstaller")
      realme_gt_on=2
    ;;

    # BaiDuDiTu, TenXunDiTu, GaoDeDiTu
    "com.baidu.BaiduMap" | "com.tencent.map" | "com.autonavi.minimap")
      if [[ "$action" != "fast" && "$action" != "pedestal" ]]; then
        core_online[7]=0
        cpuset '0' '0-3' '0-3' '0-7'
        gpu_pl_up 0
        sched_boost 0 0
        stune_top_app 0 0
        set_cpu_pl 0
        if [[ "$action" = "powersave" ]]; then
          gpu_pl_down 5
          sched_limit 0 1000 0 10000 0 2000
          set_cpu_freq 300000 1708800 710400 1574400 844800 1632000
        elif [[ "$action" = "balance" ]]; then
          gpu_pl_down 4
          sched_limit 0 500 0 10000 0 2000
          set_cpu_freq 300000 1708800 710400 1670400 844800 1862400
        elif [[ "$action" = "performance" ]]; then
          gpu_pl_down 2
          sched_limit 0 500 0 5000 0 1000
          set_cpu_freq 300000 1804800 710400 1766400 825600 2073600
        fi
      fi
    ;;

    "default")
      echo '未适配的应用'
    ;;
  esac
  scene_scheduler "$top_app" "$action"
}
