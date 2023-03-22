governor=interactive
# if [[ -n $(grep schedutil /sys/devices/system/cpu/cpufreq/policy0/scaling_available_governors) ]]; then
#   governor=schedutil
# else
#   governor=interactive
# fi

# GPU频率表
gpu_freqs=`cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`
# GPU最大频率
gpu_max_freq='710000000'
# GPU最小频率
gpu_min_freq='180000000'
# GPU最小 power level
gpu_min_pl=7
# GPU最大 power level
gpu_max_pl=0

# MaxFrequency、MinFrequency
for freq in $gpu_freqs; do
  if [[ $freq -gt $gpu_max_freq ]]; then
    gpu_max_freq=$freq
  fi
  if [[ $freq -lt $gpu_min_freq ]]; then
    gpu_min_freq=$freq
  fi
done

# Power Levels
if [[ -f /sys/class/kgsl/kgsl-3d0/num_pwrlevels ]];then
  gpu_min_pl=`cat /sys/class/kgsl/kgsl-3d0/num_pwrlevels`
  gpu_min_pl=`expr $gpu_min_pl - 1`
fi
if [[ "$gpu_min_pl" -lt 0 ]];then
  gpu_min_pl=0
fi

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

  for cluster in 0 4; do
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

  echo $3 > ${policy}6/conservative/down_threshold
  echo $4 > ${policy}6/conservative/up_threshold
  echo $3 > ${policy}6/conservative/down_threshold
  echo $4 > ${policy}6/conservative/up_threshold
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

  if [[ ! "$governor0" = "$governor" ]]; then
    set_value $governor /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
  fi
  if [[ ! "$governor4" = "$governor" ]]; then
    set_value $governor /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
  fi

  # GPU
  gpu_governor=`cat /sys/class/kgsl/kgsl-3d0/devfreq/governor`
  if [[ ! "$gpu_governor" = "msm-adreno-tz" ]]; then
    echo 'msm-adreno-tz' > /sys/class/kgsl/kgsl-3d0/devfreq/governor
  fi
  # echo $gpu_max_freq > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
  echo $gpu_min_freq > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
  echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/def_pwrlevel
  echo $gpu_max_pl > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
}

devfreq_performance () {
  bw_max_always
}

devfreq_restore () {
  bw_min
}

bw_min() {
  local path='/sys/class/devfreq/cc00000.qcom,vidc:venus_bus_ddr'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq

  local path='/sys/class/devfreq/soc:qcom,cpubw'
  cat $path/available_frequencies | awk -F ' ' '{print $1}' > $path/min_freq
}

bw_max() {
  local path='/sys/class/devfreq/cc00000.qcom,vidc:venus_bus_ddr'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq

  local path='/sys/class/devfreq/soc:qcom,cpubw'
  cat $path/available_frequencies | awk -F ' ' '{print $NF}' > $path/max_freq
}

bw_max_always() {
  local path='/sys/class/devfreq/cc00000.qcom,vidc:venus_bus_ddr'
  local b_max=`cat $path/available_frequencies | awk -F ' ' '{print $NF}'`
  echo $b_max > $path/min_freq
  echo $b_max > $path/max_freq
  echo $b_max > $path/min_freq

  local path='/sys/class/devfreq/soc:qcom,cpubw'
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
  local ms="$3"
  set_value "0:$c0 1:$c0 2:$c0 3:$c0 4:$c1 5:$c1 6:$c1 7:$c1" /sys/module/cpu_boost/parameters/input_boost_freq
  set_value $ms /sys/module/cpu_boost/parameters/input_boost_ms
  if [[ "$ms" -gt 0 ]]; then
    echo 1 > /sys/module/cpu_boost/parameters/sched_boost_on_input
  else
    echo 0 > /sys/module/cpu_boost/parameters/sched_boost_on_input
  fi
}

set_cpu_freq() {
  set_value "0:$2 1:$2 2:$2 3:$2 4:$4 5:$4 6:$4 7:$4" /sys/module/msm_performance/parameters/cpu_max_freq
  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  set_value $2 /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
  set_value $3 /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
  set_value $4 /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
}

sched_config() {
  set_value "$1" /proc/sys/kernel/sched_downmigrate
  set_value "$2" /proc/sys/kernel/sched_upmigrate
  set_value "$1" /proc/sys/kernel/sched_downmigrate
  set_value "$2" /proc/sys/kernel/sched_upmigrate

  set_value "$3" /proc/sys/kernel/sched_group_downmigrate
  set_value "$4" /proc/sys/kernel/sched_group_upmigrate
  set_value "$3" /proc/sys/kernel/sched_group_downmigrate
  set_value "$4" /proc/sys/kernel/sched_group_upmigrate
}

sched_limit() {
  set_value $1 /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
  set_value $2 /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
  set_value $3 /sys/devices/system/cpu/cpufreq/policy4/schedutil/down_rate_limit_us
  set_value $4 /sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us
}

set_gpu_min_freq() {
  index=$1

  # GPU频率表
  gpu_freqs=`cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`

  target_freq=$(echo $gpu_freqs | awk "{print \$${index}}")
  if [[ "$target_freq" != "" ]]; then
    set_value $target_freq /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
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

set_ctl() {
  echo $2 > /sys/devices/system/cpu/$1/core_ctl/busy_up_thres
  echo $3 > /sys/devices/system/cpu/$1/core_ctl/busy_down_thres
  echo $4 > /sys/devices/system/cpu/$1/core_ctl/offline_delay_ms
}

set_hispeed_freq() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/$governor/hispeed_freq
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/$governor/hispeed_freq
}

set_hispeed_load() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/$governor/hispeed_load
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/$governor/hispeed_load
}

sched_boost() {
  set_value $1 /proc/sys/kernel/sched_boost_top_app
  set_value $2 /proc/sys/kernel/sched_boost
}

stune_top_app() {
  set_value $1 /dev/stune/top-app/schedtune.prefer_idle
  set_value $2 /dev/stune/top-app/schedtune.boost
}

cpuset() {
  set_value $1 /dev/cpuset/background/cpus
  set_value $2 /dev/cpuset/system-background/cpus
  set_value $3 /dev/cpuset/foreground/cpus
  set_value $4 /dev/cpuset/top-app/cpus
}

# [min/max/def] pl(number)
set_gpu_pl(){
  set_value $2 /sys/class/kgsl/kgsl-3d0/${1}_pwrlevel
}

set_gpu_max_freq () {
  set_value $1 /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
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
    set_value `expr $gpu_min_pl - $offset` /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  elif [[ "$offset" -gt "$gpu_min_pl" ]]; then
    set_value 0 /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  else
    set_value $gpu_min_pl /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  fi
}

# GPU MinPowerLevel To Down
gpu_pl_down() {
  local offset="$1"
  if [[ "$offset" != "" ]] && [[ ! "$offset" -gt "$gpu_min_pl" ]]; then
    set_value $offset /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  elif [[ "$offset" -gt "$gpu_min_pl" ]]; then
    set_value $gpu_min_pl /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  else
    set_value $gpu_min_pl /sys/class/kgsl/kgsl-3d0/max_pwrlevel
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

# WangZheRongYao
sgame_opt_run() {
  local game="tmgp.sgame"
  if [[ $(getprop vtools.powercfg_app | grep $game) == "" ]]; then
    return
  fi

  # top -H -p $(pgrep -ef tmgp.sgame)
  # pid=$(pgrep -ef $game)
  pid=$(pgrep -ef $game)
  # mask=`echo "obase=16;$((num=2#01111111))" | bc` # 7F (cpu 6-0)

  if [[ "$pid" != "" ]]; then
    heavy_tid=$(top -H -b -q -n 1 -m 5 -p $pid | grep 'Thread-' | egrep  -o '[0-9]{1,}' | head -n 1)
    for tid in $(ls "/proc/$pid/task/"); do
      if [[ "$heavy_tid" == "$tid" ]]; then
        taskset -p "C0" "$tid" > /dev/null 2>&1
      elif [[ -f "/proc/$pid/task/$tid/comm" ]]; then
        comm=$(cat /proc/$pid/task/$tid/comm)
        case "$comm" in
         "UnityMain"|"UnityGfx"|"CoreThread"*|"NativeThread")
           # set cpu6-7
           taskset -p "C0" "$tid" > /dev/null 2>&1
         ;;
         *)
           # set cpu0-5
           taskset -p "3F" "$tid" > /dev/null 2>&1
         ;;
        esac
      fi
    done
  fi
}

# watch_app [on_tick] [on_change]
watch_app() {
  local interval=120
  local on_tick="$1"
  local on_change="$2"
  local app=$(getprop vtools.powercfg_app)

  if [[ "$on_tick" == "" ]]; then
    return
  fi

  if [[ "$app" == "" ]]; then
    return
  fi

  procs=$(pgrep -f com.omarea.*powercfg.sh)
  last_proc=$(echo "$procs" | tail -n 1)
  if [[ "$last_proc" != "" ]]; then
    echo "$procs" | grep -v "$last_proc" | while read pid; do
      kill -9 $pid 2> /dev/null
    done
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
      $on_tick $current
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
    "com.miHoYo.Yuanshen" | "com.miHoYo.ys.mi" | "com.miHoYo.ys.bilibili")
        ctl_off cpu0
        ctl_off cpu4
        set_hispeed_freq 0 0
        cpuset '0' '0' '0-5' '0-7'
        devfreq_performance
        sched_boost 0 0
        stune_top_app 0 100

        if [[ "$action" = "powersave" ]]; then
          set_cpu_freq 1708800 1900800 1958400 2323200
          gpu_pl_up 3
        elif [[ "$action" = "balance" ]]; then
          set_cpu_freq 1708800 1900800 2208000 2457600
          gpu_pl_up 4
        elif [[ "$action" = "performance" ]]; then
          set_cpu_freq 1900800 2500000 2323200 2750000
          gpu_pl_up 5
        elif [[ "$action" = "fast" ]]; then
          set_cpu_freq 1900800 2500000 2457600 2750000
          gpu_pl_up 6
        fi

        if [[ "$governor" == 'interactive' ]]; then
          set_value "35 1804800:40" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
          set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
          set_value "40 1728000:45 2208000:50" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
          set_value 1 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
        else
          sched_limit 5000 0 5000 0
        fi
        # scene_scheduler "$top_app" "$action"
    ;;

    # Wang Zhe Rong Yao
    "com.tencent.tmgp.sgame")
        ctl_off cpu0
        ctl_off cpu4
        set_hispeed_freq 0 0
        cpuset '0' '0' '0-5' '0-7'
        devfreq_performance
        sched_boost 0 0
        stune_top_app 0 100

        if [[ "$action" = "powersave" ]]; then
          set_cpu_freq 1708800 1900800 1420800 2323200
          gpu_pl_up 1
        elif [[ "$action" = "balance" ]]; then
          set_cpu_freq 1708800 1900800 1420800 2457600
          gpu_pl_up 2
        elif [[ "$action" = "performance" ]]; then
          set_cpu_freq 1900800 2500000 1804800 2750000
          gpu_pl_up 3
        elif [[ "$action" = "fast" ]]; then
          set_cpu_freq 1900800 2500000 2457600 2750000
          gpu_pl_up 4
        fi

        if [[ "$governor" == 'interactive' ]]; then
          set_value "35 1804800:40" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
          set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
          set_value "40 1728000:45 2208000:50" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
          set_value 1 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
        else
          sched_limit 5000 0 5000 0
        fi
        # 这个策略很好，但是会被系统(游戏)覆盖，甚至互斥产生负面作用
        # watch_app sgame_opt_run &
        # scene_scheduler "$top_app" "$action"
    ;;

    "default")
      echo '未适配的应用'
    ;;
  esac
  scene_scheduler "$top_app" "$action"
}
