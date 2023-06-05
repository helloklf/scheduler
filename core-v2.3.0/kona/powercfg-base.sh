#! /vendor/bin/sh

cfg_dir=$(cd $(dirname $0); pwd)

killall scene-scheduler 2>/dev/null

# Enable conservative pl
# echo 1 > /proc/sys/kernel/sched_conservative_pl

echo N > /sys/module/lpm_levels/parameters/sleep_disabled

set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    echo $pid > /dev/stune/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuset/$2/tasks
    done
  done
}

governor_cover() {
  policy=/sys/devices/system/cpu/cpufreq/policy
  ls $policy* | while read cluster; do
    hide_value ${policy}${cluster}/scaling_governor $1
  done
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

process_opt(){
  set_cpuset surfaceflinger top-app
  set_cpuset system_server top-app
  set_cpuset vendor.qti.hardware.display.composer-service top-app

  miui_home=$(pidof com.miui.home)
  if [[ "$miui_home" != "" ]]; then
    memcg=/dev/memcg
    mem_fg=$memcg/scene_fg
    if [[ -d $memcg ]] && [[ ! -e "$mem_fg" ]]; then
      mkdir -p $mem_fg
      echo 0 > $mem_fg/memory.swappiness
      echo 1 > $mem_fg/memory.oom_control
      echo 1 > $mem_fg/memory.use_hierarchy
      echo 1 >  $mem_fg/memory.move_charge_at_immigrate
    fi
    echo $miui_home > $mem_fg/cgroup.procs
  fi
}

disable_migt() {
  migt=/sys/module/migt/parameters
  if [[ -d $migt ]]; then
    hide_value $migt/migt_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
    hide_value $migt/glk_freq_limit_start '0'
    hide_value $migt/glk_freq_limit_walt '0'
    hide_value $migt/glk_maxfreq '0 0 0'
    hide_value $migt/glk_minfreq '300000 710400 844800'
    hide_value $migt/migt_ceiling_freq '0 0 0'
    hide_value $migt/glk_disable '1'
    hide_value $migt/mi_freq_enable '0'
    hide_value $migt/force_stask_to_big '0'
    hide_value $migt/glk_fbreak_enable '0'
    hide_value $migt/force_reset_runtime '0'
    hide_value $migt/enable_pkg_monitor '0'

    settings put secure speed_mode_enable 1
    chmod 000 $migt/*
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

core_ctl_preset() {
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  echo 50 > $cpu7_core_ctl_dir/offline_delay_ms
  echo 1 > $cpu7_core_ctl_dir/not_preferred
  echo 1 > $cpu7_core_ctl_dir/max_cpus
  echo 0 > $cpu7_core_ctl_dir/min_cpus
  # echo 1 > $cpu7_core_ctl_dir/nr_prev_assist_thresh
  echo 1 > $cpu7_core_ctl_dir/task_thres
  echo 30 > $cpu7_core_ctl_dir/busy_down_thres
  echo 60 > $cpu7_core_ctl_dir/busy_up_thres
  echo 0 > $cpu7_core_ctl_dir/enable

  cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
  echo 50 > $cpu4_core_ctl_dir/offline_delay_ms
  echo 0 0 0 > $cpu4_core_ctl_dir/not_preferred
  echo 3 > $cpu4_core_ctl_dir/max_cpus
  lock_value 3 $cpu4_core_ctl_dir/min_cpus
  # echo 4294967295 > $cpu4_core_ctl_dir/nr_prev_assist_thresh
  echo 3 > $cpu4_core_ctl_dir/task_thres
  echo 15 > $cpu4_core_ctl_dir/busy_down_thres
  echo 20 > $cpu4_core_ctl_dir/busy_up_thres
  echo 0 > $cpu4_core_ctl_dir/enable
  chmod 444 $cpu4_core_ctl_dir/enable

  cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
  echo 50 > $cpu0_core_ctl_dir/offline_delay_ms
  echo 0 0 0 0 > $cpu0_core_ctl_dir/not_preferred
  echo 4 > $cpu0_core_ctl_dir/max_cpus
  lock_value 4 $cpu0_core_ctl_dir/min_cpus
  # echo 4294967295 > $cpu0_core_ctl_dir/nr_prev_assist_thresh
  # echo 3 > $cpu0_core_ctl_dir/task_thres
  echo 15 > $cpu0_core_ctl_dir/busy_down_thres
  echo 20 > $cpu0_core_ctl_dir/busy_up_thres
  echo 0 > $cpu0_core_ctl_dir/enable
  chmod 444 $cpu0_core_ctl_dir/enable
}

hide_value /sys/class/kgsl/kgsl-3d0/devfreq/governor 'msm-adreno-tz'
echo "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 0 > /sys/module/cpu_boost/parameters/input_boost_ms
echo 0 > /sys/module/cpu_boost/parameters/sched_boost_on_input
for index in 0 1 2 3 4 5 6 7; do
  hide_value /sys/devices/system/cpu/cpu$index/online 1
done

# set_value 8000000 /proc/sys/kernel/sched_latency_ns
# set_value 2000000 /proc/sys/kernel/sched_min_granularity_ns

t_message=/sys/class/thermal/thermal_message
if [[ -f $t_message/cpu_limits ]]; then
  for i in $(seq 0 7); do
    maxfreq=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq)
    echo cpu$i $maxfreq > $t_message/cpu_limits
  done
  chmod 444 $t_message/cpu_limits
fi
hide_value $t_message/market_download_limit 0
hide_value $t_message/cpu_nolimit_temp 47500
lock_value 0 /sys/module/aigov/parameters/enable

core_ctl_preset
disable_migt

process_opt &

setprop persist.sys.miui_animator_sched.bigcores 4-7

for dir in /sys/class/devfreq/*l3-lat; do
  lock_value 1612800000 $dir/max_freq
  lock_value 300000000 $dir/min_freq
done
for dir in /sys/class/devfreq/*llcc-lat; do
  lock_value 15258 $dir/max_freq
  lock_value 2288 $dir/min_freq
done
for dir in $(ls /sys/class/devfreq | grep ddr-lat | grep -v npu); do
  lock_value 10437 /sys/class/devfreq/$dir/max_freq
  lock_value 762 /sys/class/devfreq/$dir/min_freq
done
# 2288 4577 7110 9155 12298 14236 15258
lock_value 12298 /sys/class/devfreq/soc:qcom,cpu-cpu-llcc-bw/max_freq
# 762 1144 1720 2086 2597 2929 3879 5931 6881 7980 10437
lock_value 6881 /sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw/max_freq


# OnePlus
hide_value /proc/oplus_scheduler/sched_assist/sched_impt_task ''
lock_value N /sys/module/oplus_ion_boost_pool/parameters/debug_boost_pool_enable
if [[ -d  /proc/game_opt ]]; then
  hide_value /proc/game_opt/cpu_max_freq '0:2147483647 1:2147483647 2:2147483647 3:2147483647 4:2147483647 5:2147483647 6:2147483647 7:2147483647'
  hide_value /proc/game_opt/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
  hide_value /proc/game_opt/game_pid -1
fi
hide_value /proc/task_info/task_sched_info/task_sched_info_enable 0
hide_value /proc/oplus_scheduler/sched_assist/sched_assist_enabled 0
echo 0 > /proc/sys/kernel/sched_force_lb_enable
lock_value N /sys/module/sched_assist_common/parameters/boost_kill
lock_value N /sys/module/task_sched_info/parameters/sched_info_ctrl
echo "orms-hal-1-0
oiface
gameopt_hal_service-1-0
midas_hal_service
thermal_mnt_hal_servic" | while read service
do
  stop $service
done
setprop persist.sys.hans.skipframe.enable false
lock_value 0 /sys/devices/platform/soc/soc:oplus-omrg/oplus-omrg0/ruler_enable
for file in silver_core_boost splh_notif lplh_notif dplh_notif l3_boost; do
  lock_value 0 /sys/kernel/msm_performance/parameters/$file
done
echo -R 444 /sys/kernel/msm_performance/parameters

row=$(grep thermal_heat_path /odm/etc/ThermalServiceConfig/sys_thermal_config.xml)
tz=$(echo ${row#*>} | cut -f1 -d '<')
if [[ -n $tz ]]; then
  hide_value $tz 31000
fi
oplus_thermal=/odm/etc/temperature_profile/sys_thermal_control_config.xml
if [[ -n $(grep 'fps="50"' $oplus_thermal) ]]; then
  replace=$cfg_dir/sys_thermal_control_config.xml
  mount --bind $replace $oplus_thermal
  am force-stop com.oplus.battery
fi
