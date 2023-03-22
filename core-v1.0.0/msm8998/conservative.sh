#!/system/bin/sh

action=$1
task=$2

cfg_dir=$(cd $(dirname $0); pwd)

if [[ ! -f "$cfg_dir/powercfg-utils.sh" ]]; then
  echo "The dependent '$cfg_dir/powercfg-utils.sh' was not found !" > /cache/powercfg.sh.log
  exit 1
fi

source "$cfg_dir/powercfg-utils.sh"

init () {
  if [[ -f "$cfg_dir/powercfg-base.sh" ]]; then
    source "$cfg_dir/powercfg-base.sh"
  elif [[ -f '/data/powercfg-base.sh' ]]; then
    source /data/powercfg-base.sh
  fi
}

if [[ "$action" == "init" ]]; then
  init
  exit 0
fi

reset_basic_governor
if [[ "$action" == "fast" ]]; then
  devfreq_performance
else
  devfreq_restore
fi

governor_backup () {
  local governor_backup=/cache/governor_backup.prop
  local backup_state=`getprop vtools.dev_freq_backup`
  if [[ ! -f $governor_backup ]] || [[ "$backup_state" != "true" ]]; then
    echo '' > $governor_backup
    local dir=/sys/class/devfreq
    for file in `ls $dir | grep -v 'kgsl-3d0'`; do
      if [ -f $dir/$file/governor ]; then
        governor=`cat $dir/$file/governor`
        echo "$file#$governor" >> $governor_backup
      fi
    done
    setprop vtools.dev_freq_backup true
  fi
}

governor_performance () {
  governor_backup

  local dir=/sys/class/devfreq
  local governor_backup=/cache/governor_backup.prop
  local backup_state=`getprop vtools.dev_freq_backup`

  if [[ -f "$governor_backup" ]] && [[ "$backup_state" == "true" ]]; then
    for file in `ls $dir | grep -v 'kgsl-3d0'`; do
      if [ -f $dir/$file/governor ]; then
        # echo $dir/$file/governor
        echo performance > $dir/$file/governor
      fi
    done
  fi
}

governor_restore () {
  local governor_backup=/cache/governor_backup.prop
  local backup_state=`getprop vtools.dev_freq_backup`

  if [[ -f "$governor_backup" ]] && [[ "$backup_state" == "true" ]]; then
    local dir=/sys/class/devfreq
    while read line; do
      if [[ "$line" != "" ]]; then
        echo ${line#*#} > $dir/${line%#*}/governor
      fi
    done < $governor_backup
  fi
}

set_value(){
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

lock_value(){
  value=$1
  path=$2
  if [[ -f $path ]]; then
    current_value="$(cat $path)"
    if [[ ! "$current_value" = "$value" ]]; then
      chmod 0664 "$path"
      echo "$value" > "$path"
      chmod 0444 "$path"
    fi;
  fi;
}

lock_value 0 /sys/devices/system/cpu/cpu0/cpufreq/interactive/boost
lock_value 0 /sys/devices/system/cpu/cpu4/cpufreq/interactive/boost

gpu_config(){
  gpu_freqs=`cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`
  max_freq='710000000'
  for freq in $gpu_freqs; do
    if [[ $freq -gt $max_freq ]]; then
      max_freq=$freq
    fi;
  done
  gpu_min_pl=6
  if [[ -f /sys/class/kgsl/kgsl-3d0/num_pwrlevels ]];then
    gpu_min_pl=`cat /sys/class/kgsl/kgsl-3d0/num_pwrlevels`
    gpu_min_pl=`expr $gpu_min_pl - 1`
  fi;

  if [[ "$gpu_min_pl" = "-1" ]];then
    $gpu_min_pl=1
  fi;

  echo "msm-adreno-tz" > /sys/class/kgsl/kgsl-3d0/devfreq/governor
  #echo 710000000 > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
  echo $max_freq > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
  #echo 257000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
  echo 100000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
  echo $gpu_min_pl > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
  echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
}

gpu_config

interactive_cfg(){
  set_value $2 /sys/devices/system/cpu/cpu$1/cpufreq/interactive/max_freq_hysteresis
  set_value $3 /sys/devices/system/cpu/cpu$1/cpufreq/interactive/min_sample_time
  set_value $4 /sys/devices/system/cpu/cpu$1/cpufreq/interactive/timer_rate
}

schedutil_cfg(){
  set_value $2 /sys/devices/system/cpu/cpu$1/cpufreq/schedutil/down_rate_limit_us
  set_value $3 /sys/devices/system/cpu/cpu$1/cpufreq/schedutil/up_rate_limit_us
  set_value $4 /sys/devices/system/cpu/cpu$1/cpufreq/schedutil/iowait_boost_enable
}

if [[ "$action" = "powersave" ]]; then
  set_cpu_freq 5000 1747200 5000 1574400
  set_input_boost_freq 0 0 0

  echo 0 > /proc/sys/kernel/sched_boost
  echo 15 > /proc/sys/kernel/sched_init_task_load

  echo 0-2 > /dev/cpuset/background/cpus
  echo 0-3 > /dev/cpuset/system-background/cpus
  echo 0-3 > /dev/cpuset/foreground/cpus

  if [[ "$governor" == 'interactive' ]]; then
    set_value "85 300000:85 595200:67 825600:75 1248000:78" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    set_value 518400 /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    set_value "99" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    set_value 576000 /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    set_value 0 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
  fi

  interactive_cfg 0 0 9000 10000
  schedutil_cfg 0 1000 10000 0

  interactive_cfg 4 0 19000 20000
  schedutil_cfg 4 1000 10000 0
  governor_restore

elif [[ "$action" = "balance" ]]; then
  set_cpu_freq 5000 1900800 5000 1958400
  set_input_boost_freq 1478400 1574400 500

  echo 0 > /proc/sys/kernel/sched_boost
  echo 20 > /proc/sys/kernel/sched_init_task_load

  echo 0-2 > /dev/cpuset/background/cpus
  echo 0-3 > /dev/cpuset/system-background/cpus
  echo 0-5 > /dev/cpuset/foreground/cpus

  if [[ "$governor" == 'interactive' ]]; then
    set_value "84 300000:85 595200:67 825600:75 1248000:78" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    set_value 960000 /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    set_value "83 300000:89 1056000:89 1344000:92" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    set_value 1056000 /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    set_value 0 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
  fi
  interactive_cfg 0 0 9000 10000
  schedutil_cfg 0 1000 5000 0

  interactive_cfg 4 0 19000 20000
  schedutil_cfg 4 1000 5000 0
  governor_restore

elif [[ "$action" = "performance" ]]; then
  set_cpu_freq 300000 1900800 300000 2035200
  set_input_boost_freq 1900800 1651200 1000

  gpu_pl_up 1
  echo 0 > /proc/sys/kernel/sched_boost
  echo 25 > /proc/sys/kernel/sched_init_task_load

  echo 0-1 > /dev/cpuset/background/cpus
  echo 0-3 > /dev/cpuset/system-background/cpus
  echo 0-7 > /dev/cpuset/foreground/cpus

  if [[ "$governor" == 'interactive' ]]; then
    set_value "73 960000:72 1478400:78 1804800:87" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    set_value 1478400 /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    set_value "78 1497600:80 2016000:87" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    set_value 1267200 /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
  fi

  interactive_cfg 0 79000 19000 10000
  schedutil_cfg 0 1000 1000 1

  interactive_cfg 4 79000 23000 12000
  schedutil_cfg 4 1000 1000 1
  governor_performance

elif [[ "$action" = "fast" ]]; then
  set_cpu_freq 1171200 2500000 300000 2750000
  set_input_boost_freq 1900800 2035200 2000

  gpu_pl_up 2
  echo 2 > /proc/sys/kernel/sched_boost
  echo 30 > /proc/sys/kernel/sched_init_task_load

  echo 0 > /dev/cpuset/background/cpus
  echo 0-3 > /dev/cpuset/system-background/cpus
  echo 0-7 > /dev/cpuset/foreground/cpus

  if [[ "$governor" == 'interactive' ]]; then
    set_value "60 960000:65 1478400:60 1804800:65" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    set_value 1036800 /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    set_value "67 1497600:65 2016000:70" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    set_value 1497600 /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
  fi

  interactive_cfg 0 79000 19000 5000
  schedutil_cfg 0 1000 1000 1

  interactive_cfg 4 79000 19000 5000
  schedutil_cfg 4 1000 1000 1
  governor_performance

elif [[ "$action" = "pedestal" ]]; then
  set_cpu_freq 1900800 2500000 2457600 2750000
  set_input_boost_freq 1900800 2457600 0

  gpu_pl_up 4
  echo 2 > /proc/sys/kernel/sched_boost
  echo 30 > /proc/sys/kernel/sched_init_task_load

  echo 0 > /dev/cpuset/background/cpus
  echo 0-3 > /dev/cpuset/system-background/cpus
  echo 0-7 > /dev/cpuset/foreground/cpus

  if [[ "$governor" == 'interactive' ]]; then
    set_value "30 960000:40 1478400:45 1804800:45" /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    set_value 1036800 /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    set_value "45 1497600:45 2016000:50" /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    set_value 2457600 /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    set_value 1 /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
  fi

  interactive_cfg 0 79000 19000 5000
  schedutil_cfg 0 1000 1000 1

  interactive_cfg 4 79000 19000 5000
  schedutil_cfg 4 1000 1000 1
  governor_performance

fi

adjustment_by_top_app
