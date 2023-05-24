#!/system/bin/sh

killall scene-scheduler 2>/dev/null

set_value() {
  value=$1
  path=$2
  if [[ -f $path ]]; then
    current_value="$(cat $path)"
    if [[ ! "$current_value" = "$value" ]]; then
      chmod 0664 "$path"
      echo "$value" > "$path"
    fi
  fi
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
  if [[ -d $migt ]]; then
    hide_value $migt/migt_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
    hide_value $migt/glk_freq_limit_start '0'
    hide_value $migt/glk_freq_limit_walt '0'
    hide_value $migt/glk_maxfreq '0 0 0'
    hide_value $migt/glk_minfreq '300000 652800 806400'
    hide_value $migt/migt_ceiling_freq '0 0 0'
    hide_value $migt/glk_disable '1'
    hide_value $migt/mi_freq_enable '0'
    hide_value $migt/force_stask_to_big '0'
    hide_value $migt/glk_fbreak_enable '0'
    hide_value $migt/force_reset_runtime '0'

    settings put secure speed_mode_enable 1
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
}

echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable

# Core control parameters on gold
echo 1 1 > /sys/devices/system/cpu/cpu6/core_ctl/not_preferred
echo 0 > /sys/devices/system/cpu/cpu6/core_ctl/min_cpus
echo 90 > /sys/devices/system/cpu/cpu6/core_ctl/busy_up_thres
echo 65 > /sys/devices/system/cpu/cpu6/core_ctl/busy_down_thres
echo 20 > /sys/devices/system/cpu/cpu6/core_ctl/offline_delay_ms

# Setting b.L scheduler parameters
echo 1 > /proc/sys/kernel/sched_walt_rotate_big_tasks
echo 400000000 > /proc/sys/kernel/sched_coloc_downmigrate_ns

# Enable input boost configuration
echo "0:1324800" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 40 > /sys/module/cpu_boost/parameters/input_boost_ms
echo "0:1708800 1:1708800 2:1708800 3:1708800 4:1708800 5:1708800 6:2208000 7:2208000" > /sys/module/cpu_boost/parameters/powerkey_input_boost_freq
echo 400 > /sys/module/cpu_boost/parameters/powerkey_input_boost_ms
echo 'Y' > /sys/module/cpu_boost/parameters/sched_boost_on_powerkey_input
#echo 'Y' > /sys/module/cpu_boost/parameters/sched_boost_on_input

set_value 10000000 /proc/sys/kernel/sched_latency_ns
set_value 2000000 /proc/sys/kernel/sched_min_granularity_ns

disable_migt
