# /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
# 300000 403200 499200 576000 672000 768000 844800 940800 1036800 1113600 1209600 1305600 1382400 1478400 1555200 1632000 1708800 1785600

# /sys/devices/system/cpu/cpu4/cpufreq/scaling_available_frequencies
# 710400 825600 940800 1056000 1171200 1286400 1401600 1497600 1612800 1708800 1804800 1920000 2016000 2131200 2227200 2323200 2419200

# /sys/devices/system/cpu/cpu7/cpufreq/scaling_available_frequencies
# 825600 940800 1056000 1171200 1286400 1401600 1497600 1612800 1708800 1804800 1920000 2016000 2131200 2227200 2323200 2419200 2534400 2649600 2745600 2841600

# GPU
# 257000000 345000000 427000000 499200000 585000000 675000000 810000000

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
  set_core_online

  # CPU
  policy=/sys/devices/system/cpu/cpufreq/
  ls $policy | while read cluster; do
    set_value schedutil ${policy}${cluster}/scaling_governor
  done

  # GPU
  gpu_governor=`cat /sys/class/kgsl/kgsl-3d0/devfreq/governor`
  if [[ ! "$gpu_governor" = "msm-adreno-tz" ]]; then
    echo 'msm-adreno-tz' > /sys/class/kgsl/kgsl-3d0/devfreq/governor
  fi
  echo $gpu_max_freq > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
  echo $gpu_min_freq > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
  echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  echo $gpu_max_pl > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
  set_input_boost_freq 0 0 0 0
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

devfreq_backup () {
  local devfreq_backup=/cache/devfreq_backup.prop
  local backup_state=`getprop vtools.dev_freq_backup`
  if [[ ! -f $devfreq_backup ]] || [[ "$backup_state" != "true" ]]; then
    echo '' > $devfreq_backup
    local dir=/sys/class/devfreq
    for file in `ls $dir | grep -v 'kgsl-3d0'`; do
      if [ -f $dir/$file/governor ]; then
        governor=`cat $dir/$file/governor`
        echo "$file#$governor" >> $devfreq_backup
      fi
    done
    setprop vtools.dev_freq_backup true
  fi
}

devfreq_performance () {
  devfreq_backup

  local dir=/sys/class/devfreq
  local devfreq_backup=/cache/devfreq_backup.prop
  local backup_state=`getprop vtools.dev_freq_backup`

  if [[ -f "$devfreq_backup" ]] && [[ "$backup_state" == "true" ]]; then
    for file in `ls $dir | grep -v 'kgsl-3d0'`; do
      if [ -f $dir/$file/governor ]; then
        # echo $dir/$file/governor
        echo performance > $dir/$file/governor
      fi
    done
  fi
  bw_max
}

devfreq_restore () {
  local devfreq_backup=/cache/devfreq_backup.prop
  local backup_state=`getprop vtools.dev_freq_backup`

  if [[ -f "$devfreq_backup" ]] && [[ "$backup_state" == "true" ]]; then
    local dir=/sys/class/devfreq
    while read line; do
      if [[ "$line" != "" ]]; then
        echo ${line#*#} > $dir/${line%#*}/governor
      fi
    done < $devfreq_backup
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

lock_value() {
  if [[ -f $2 ]];then
    chmod 644 $2
    echo $1 > $2
    chmod 444 $2
  fi
}

set_input_boost_freq() {
  local c0="$1"
  local c1="$2"
  local c2="$3"
  local ms="$4"
  echo "0:$c0 1:$c0 2:$c0 3:$c0 4:$c1 5:$c1 6:$c1 7:$c2" > /sys/module/cpu_boost/parameters/input_boost_freq
  echo $ms > /sys/module/cpu_boost/parameters/input_boost_ms
}

set_cpu_freq() {
  echo "0:$2 1:$2 2:$2 3:$2 4:$4 5:$4 6:$4 7:$6" > /sys/module/msm_performance/parameters/cpu_max_freq
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  echo $2 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  echo $3 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
  echo $4 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
  echo $3 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
  echo $5 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
  echo $6 > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq
  echo $5 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
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

cpuset() {
  echo $1 > /dev/cpuset/background/cpus
  echo $2 > /dev/cpuset/system-background/cpus
  echo $3 > /dev/cpuset/foreground/cpus
  echo $4 > /dev/cpuset/top-app/cpus
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

# set_task_affinity $pid $use_cores[cpu7~cpu0]
set_task_affinity() {
  pid=$1
  mask=`echo "obase=16;$((num=2#$2))" | bc`
  for tid in $(ls "/proc/$pid/task/"); do
    taskset -p "$mask" "$tid" 1>/dev/null
  done
  taskset -p "$mask" "$pid" 1>/dev/null
}

# HePingJingYing
pubgmhd_opt_run () {
  local current_app=$(getprop vtools.powercfg_app)
  if [[ "$current_app" != 'com.tencent.tmgp.pubgmhd' ]] && [[ "$current_app" != 'com.tencent.ig' ]]; then
    return
  fi

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
         "RenderThread"*)
           taskset -p "80" "$tid" > /dev/null 2>&1
           echo 1
         ;;
         *)
           taskset -p "7F" "$tid" > /dev/null 2>&1
         ;;
        esac
      fi
    done
  done
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
      if [[ -f "/proc/$pid/task/$tid/comm" ]]; then
        comm=$(cat /proc/$pid/task/$tid/comm)

        case "$comm" in
          "RenderThread"*|"UnityMain")
            taskset -p "80" "$tid" > /dev/null 2>&1 || taskset -p "F0" "$tid"
          ;;
          "UnityGfxDevice"*|"UnityMultiRende"*)
            taskset -p "F0" "$tid" > /dev/null 2>&1
          ;;
        esac
      fi
    done
  done
}

# YuanShen
yuan_shen_opt_run() {
  if [[ $(getprop vtools.powercfg_app | grep miHoYo) == "" ]]; then
    return
  fi

  # top -H -p $(pgrep -ef Yuanshen)
  # pid=$(pgrep -ef Yuanshen)
  pid=$(pgrep -ef miHoYo)
  # mask=`echo "obase=16;$((num=2#11110000))" | bc` # F0 (cpu 7-4)
  # mask=`echo "obase=16;$((num=2#10000000))" | bc` # 80 (cpu 7)
  # mask=`echo "obase=16;$((num=2#01110000))" | bc` # 70 (cpu 6-4)
  # mask=`echo "obase=16;$((num=2#01111111))" | bc` # 7F (cpu 6-0)

  if [[ "$pid" != "" ]]; then
    if [[ "$taskset_effective" == "" ]]; then
      taskset_test $pid
      if [[ "$?" == '1' ]]; then
        taskset_effective=1
      else
        taskset_effective=0
        exit
      fi
    fi

    local mode=$(getprop vtools.powercfg)
    if [[ "$mode" == 'powersave' ]]; then
      for tid in $(ls "/proc/$pid/task/"); do
        if [[ "$tid" == "$pid" ]]; then
          taskset -p "FF" "$tid" > /dev/null 2>&1
          continue
        fi
        if [[ -f "/proc/$pid/task/$tid/comm" ]]; then
          comm=$(cat /proc/$pid/task/$tid/comm)

          case "$comm" in
           "UnityMain")
             taskset -p "80" "$tid" > /dev/null 2>&1 || taskset -p "F0" "$tid" > /dev/null 2>&1
           ;;
           # "UnityGfxDevice"*|"UnityMultiRende"*|"NativeThread"*|"UnityChoreograp"*)
           "UnityGfxDevice"*|"UnityMultiRende"*)
             taskset -p "70" "$tid" > /dev/null 2>&1
           ;;
           "Worker Thread"|"AudioTrack"|"Audio"*)
             taskset -p "F" "$tid" > /dev/null 2>&1
           ;;
           *)
             taskset -p "7F" "$tid" > /dev/null 2>&1
           ;;
          esac
        fi
      done
    else
      for tid in $(ls "/proc/$pid/task/"); do
        if [[ "$tid" == "$pid" ]]; then
          taskset -p "FF" "$tid" > /dev/null 2>&1
          continue
        fi
        if [[ -f "/proc/$pid/task/$tid/comm" ]]; then
          comm=$(cat /proc/$pid/task/$tid/comm)

          case "$comm" in
           "AudioTrack"|"Audio"*|"tp_schedule"*|"MIHOYO_NETWORK"|"FMOD"*|"NativeThread"|"UnityChoreograp"|"UnityPreload")
             taskset -p "F" "$tid" > /dev/null 2>&1
           ;;
           "UnityMain")
             taskset -p "F0" "$tid" > /dev/null 2>&1
             taskset -p "80" "$tid" > /dev/null 2>&1
           ;;
           # "UnityGfxDevice"*|"UnityMultiRende"*|"NativeThread"*|"UnityChoreograp"*)
           "UnityGfxDevice"*|"UnityMultiRende"*)
             taskset -p "70" "$tid" > /dev/null 2>&1
           ;;
           *)
             taskset -p "7F" "$tid" > /dev/null 2>&1
           ;;
          esac
        fi
      done
    fi
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

adjustment_by_top_app() {
  case "$top_app" in
    # YuanShen
    "com.miHoYo.Yuanshen" | "com.miHoYo.ys.mi" | "com.miHoYo.ys.bilibili" | "com.miHoYo.GenshinImpact")
        ctl_off cpu4
        ctl_off cpu7
        set_hispeed_freq 0 0 0
        if [[ "$action" = "powersave" ]]; then
          sched_boost 0 0
          stune_top_app 0 0
          sched_config "62 60" "70 75" "300" "400"
          gpu_pl_down 2
          set_cpu_freq 1785600 1785600 1056000 1708800 1056000 2419200
          sched_limit 0 0 0 5000 0 1000
          cpuset '0' '0' '0-7' '0-7'
        elif [[ "$action" = "balance" ]]; then
          sched_boost 0 0
          stune_top_app 0 0
          sched_config "62 58" "80 72" "300" "400"
          gpu_pl_down 1
          set_cpu_freq 1632000 1785600 1056000 1804800 1056000 2841600
          sched_limit 10000 0 0 5000 0 1000
          cpuset '0' '0-1' '0-7' '0-7'
        elif [[ "$action" = "performance" ]]; then
          sched_boost 1 0
          stune_top_app 1 10
          gpu_pl_down 0
          set_cpu_freq 1036800 1785600 1056000 2419200 1056000 3000000
          sched_limit 5000 0 1000 0 5000 0
          sched_config "40 60" "60 75" "120" "150"
          cpuset '0-1' '0-3' '0-7' '0-7'
        elif [[ "$action" = "fast" ]]; then
          sched_boost 1 0
          stune_top_app 1 50
          sched_limit 5000 0 5000 0 10000 0
          sched_config "40 60" "60 75" "120" "150"
          cpuset '0-1' '0-3' '0-7' '0-7'
          bw_max_always
        fi
        watch_app yuan_shen_opt_run &
    ;;

    # PUBG
    "com.tencent.tmgp.pubgmhd" | "com.tencent.ig")
      cpuset '0-1' '0-3' '0-7' '0-7'
      watch_app pubgmhd_opt_run &
      set_hispeed_freq 0 0 0
    ;;

    # Project SEKAI
    "com.hermes.mk.asia"|"com.sega.pjsekai")
      # watch_app unity_opt_run &
      if [[ "$action" == "powersave" ]]; then
        sched_boost 1 1
        stune_top_app 1 0
        # sched_config "50 55" "70 70" "85" "100"
      elif [[ "$action" == "balance" ]]; then
        sched_boost 1 1
        stune_top_app 1 0
        # sched_config "50 52" "65 68" "85" "100"
      elif [[ "$action" == "performance" ]]; then
        sched_boost 1 1
        stune_top_app 1 0
        # sched_config "45 52" "55 65" "85" "100"
      else
        sched_boost 1 1
        stune_top_app 1 10
        # sched_config "45 48" "55 60" "85" "100"
      fi
    ;;

    # Wang Zhe Rong Yao
    "com.tencent.tmgp.sgame")
        ctl_off cpu4
        ctl_on cpu7
        if [[ "$action" = "powersave" ]]; then
          # sched_config "55 68" "69 78" "300" "400"
          sched_config "52 55" "69 67" "300" "400"
          sched_boost 1 0
          stune_top_app 0 0
          cpuset '0-1' '0-1' '0-3' '0-7'
        elif [[ "$action" = "balance" ]]; then
          # sched_config "48 65" "63 75" "300" "400"
          sched_config "50 55" "65 65" "300" "400"
          sched_boost 1 0
          stune_top_app 0 1
          cpuset '0-1' '0-1' '0-6' '0-7'
        elif [[ "$action" = "performance" ]]; then
          sched_config "45 55" "55 65" "300" "400"
          sched_boost 1 0
          stune_top_app 1 20
          cpuset '0-1' '0-1' '0-6' '0-7'
        elif [[ "$action" = "fast" ]]; then
          sched_config "40 55" "50 63" "300" "400"
          cpuset '0-1' '0-1' '0-6' '0-7'
          sched_boost 1 1
          stune_top_app 1 20
        fi
    ;;

    # ShuangShengShiJie
    "com.bilibili.gcg2.bili")
        if [[ "$action" = "powersave" ]]; then
          gpu_pl_down 4
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

    # XianYu, TaoBao, Browser, TieBa Fast, TieBa、JingDong、TianMao、Mei Tuan、PuPuChaoShi
    "com.taobao.idlefish" | "com.taobao.taobao" | "com.android.browser" | "com.baidu.tieba_mini" | "com.baidu.tieba" | "com.jingdong.app.mall" | "com.tmall.wireless" | "com.sankuai.meituan" | "com.pupumall.customer")
      if [[ "$action" == "powersave" ]]; then
        set_input_boost_freq 1785600 0 0 2000
        sched_config "50 65" "70 80" "85" "100"
      elif [[ "$action" == "balance" ]]; then
        set_input_boost_freq 1785600 0 0 2000
        sched_config "50 62" "65 78" "85" "100"
      elif [[ "$action" == "performance" ]]; then
        set_input_boost_freq 1785600 0 0 2000
        sched_config "45 62" "55 75" "85" "100"
      else
        sched_boost 1 1
        stune_top_app 1 1
        sched_config "45 62" "55 75" "85" "100"
      fi
    ;;

    "com.speedsoftware.rootexplorer" | "com.estrongs.android.pop")
      if [[ "$action" == "powersave" ]]; then
        set_input_boost_freq 1785600 0 0 2000
        sched_config "50 65" "68 72" "85" "100"
      elif [[ "$action" == "balance" ]]; then
        set_input_boost_freq 1785600 0 0 2000
        sched_config "45 50" "60 68" "85" "100"
      elif [[ "$action" == "performance" ]]; then
        sched_boost 1 0
        stune_top_app 1 1
        sched_config "40 50" "50 65" "85" "100"
      else
        sched_boost 1 1
        stune_top_app 1 1
        sched_config "40 50" "50 65" "85" "100"
      fi
    ;;

    "com.miui.home")
      if [[ "$action" == "powersave" ]]; then
        set_input_boost_freq 1785600 1401600 1612800 2000
        sched_config "45 52" "65 65" "65" "80"
      elif [[ "$action" == "balance" ]]; then
        set_input_boost_freq 1785600 1804800 1920000 2000
        sched_config "40 52" "55 65" "65" "80"
      elif [[ "$action" == "performance" ]]; then
        sched_config "35 52" "45 65" "65" "80"
        set_input_boost_freq 1785600 1804800 1920000 2000
      else
        sched_boost 1 1
        stune_top_app 1 1
        sched_config "35 52" "45 65" "65" "80"
      fi
    ;;

    # NeteaseCloudMusic, KuGou, KuGou Lite
    "com.netease.cloudmusic" | "com.kugou.android" | "com.kugou.android.lite")
      echo 0-6 > /dev/cpuset/foreground/cpus
    ;;

    # DouYin, BiliBili
    "com.ss.android.ugc.aweme" | "tv.danmaku.bili"|"com.bilibili.app.in")
      ctl_on cpu4
      ctl_on cpu7
      set_ctl cpu4 85 45 0
      set_ctl cpu7 80 40 0

      echo 0-3 > /dev/cpuset/foreground/cpus
      if [[ "$action" = "powersave" ]]; then
        sched_boost 0 0
        stune_top_app 0 0
        sched_config "85 85" "100 100" "240" "400"
        echo 0-6 > /dev/cpuset/top-app/cpus
        if [[ "$top_app" == "com.ss.android.ugc.aweme" ]]; then
          set_cpu_freq 1305600 1785600 710400 1401600 844800 1497600
        fi
        set_input_boost_freq 1785600 0 0 2000
      elif [[ "$action" = "balance" ]]; then
        sched_boost 0 0
        stune_top_app 0 0
        sched_config "85 85" "100 100" "240" "400"
        echo 0-6 > /dev/cpuset/top-app/cpus
        if [[ "$top_app" == "com.ss.android.ugc.aweme" ]]; then
          set_cpu_freq 1305600 1785600 710400 1708800 825600 1920000
        fi
        set_input_boost_freq 1785600 0 0 2000
      elif [[ "$action" = "performance" ]]; then
        sched_boost 0 0
        stune_top_app 0 0
        sched_config "70 70" "90 90" "240" "400"
        set_input_boost_freq 1785600 0 0 2000
      elif [[ "$action" = "fast" ]]; then
        sched_boost 1 0
        stune_top_app 1 0
        sched_config "65 65" "75 80" "300" "400"
        set_input_boost_freq 1708800 0 0 2000
      fi
    ;;

    "default")
      echo '未适配的应用'
    ;;
  esac
}
