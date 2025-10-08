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
    c_path="/dev/scene${1}"
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

move_to_cpuset() {
  pid="$1"
  cpuset="/dev/cpuset/$2/cgroup.procs"
  if [[ "$pid" != "" ]] && [[ -e "$cpuset" ]]; then
    echo $pid > "$cpuset"
  fi
}

echo N > /sys/module/lpm_levels/parameters/sleep_disabled
set_input_boost_freq() {
  c0="$1"
  c1="$2"
  c2="$3"
  ms="$4"
  echo "0:$c0 1:$c0 2:$c0 3:$c0 4:$c1 5:$c1 6:$c1 7:$c2" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
  echo $ms > /sys/devices/system/cpu/cpu_boost/input_boost_ms
  if [[ "$ms" -gt 0 ]]; then
    echo 1 > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input
  else
    echo 0 > /sys/devices/system/cpu/cpu_boost/sched_boost_on_input
  fi
}
set_input_boost_freq 0 0 0 0

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

process_opt() {
  set_cpuset vendor.oplus.hardware.gameopt-service foreground

  pidof com.android.systemui | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    # echo $pid > /dev/stune/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      case $(cat /proc/$pid/task/$tid/comm) in
        "wmshell.anim"*)
          echo $tid > /dev/cpuset/top-app/tasks
          taskset -p f0 $tid > /dev/null
        ;;
      esac
      # echo $tid > /dev/cpuset/$2/tasks
    done
  done
}

echo '' > /proc/sys/walt/sched_lib_name

disable_migt() {
  migt=/sys/module/migt/parameters
  if [[ -e $migt ]]; then
    echo 1 > $migt/force_reset_runtime
    echo 1 > $migt/reset_clus_affinity_uidlist
    hide_value $migt/migt_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
    chmod 444 $migt/add_bclus_affinity_uidlist
    chmod 444 $migt/add_mclus_affinity_uidlist
    chmod 444 $migt/add_lclus_affinity_uidlist
    chmod 444 $migt/add_rebind_task_big
    chmod 444 $migt/add_rebind_task_lit
    chmod 444 $migt/add_rebind_task_mid
    hide_value $migt/glk_freq_limit_start '0'
    hide_value $migt/glk_freq_limit_walt '0'
    hide_value $migt/glk_maxfreq '0 0 0'
    hide_value $migt/glk_minfreq '307200 633600 787200'
    hide_value $migt/migt_ceiling_freq '0 0 0'
    hide_value $migt/glk_disable '1'
    hide_value $migt/mi_freq_enable '0'
    hide_value $migt/force_stask_to_big '0'
    hide_value $migt/glk_fbreak_enable '0'
    echo 1 > $migt/force_reset_runtime
    echo 1 > $migt/reset_clus_affinity_uidlist
    echo 1 > $migt/reset_rebind_task

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
    for file in $metis/*enable; do
      lock_value 0 $file
    done
    set_value 0 $metis/cluaff_control
  fi
}

core_ctl_preset() {
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  lock_value 0 $cpu7_core_ctl_dir/enable

  cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
  echo 3 > $cpu4_core_ctl_dir/min_cpus
  lock_value 0 $cpu4_core_ctl_dir/enable

  cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
  echo 4 > $cpu0_core_ctl_dir/min_cpus
  lock_value 0 $cpu0_core_ctl_dir/enable
}

echo "0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0" > /sys/module/cpu_boost/parameters/input_boost_freq
echo 0 > /sys/module/cpu_boost/parameters/input_boost_ms
echo 0 > /sys/module/cpu_boost/parameters/sched_boost_on_input
for index in 0 1 2 3 4 5 6 7; do
  echo 1 > /sys/devices/system/cpu/cpu$index/online
done

hide_value /sys/module/msm_performance/parameters/cpu_max_freq '0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295'
chattr +i  /sys/module/msm_performance/parameters/cpu_max_freq
hide_value /sys/module/msm_performance/parameters/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
chattr +i  /sys/module/msm_performance/parameters/cpu_min_freq

rmdir /dev/cpuset/background/untrustedapp
rmdir /dev/cpuset/foreground/boost

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

core_ctl_preset
disable_migt

process_opt &

if [[ -d /my_heytap ]]; then
  hide_value /proc/sys/walt/sched_upmigrate '85 95'
  hide_value /proc/sys/walt/sched_downmigrate '70 80'
  hide_value /proc/sys/walt/sched_group_upmigrate 95
  hide_value /proc/sys/walt/sched_group_downmigrate 78
  stop miuibooster # CC'MIUI/HyperOS
  # echo 0 > /proc/sys/kernel/sched_energy_aware
  # echo "obase=16;120" | bc > /proc/touchpanel/game_switch_enable
  echo 0 > /proc/touchpanel/game_switch_enable
  chmod 444 /proc/touchpanel/game_switch_enable
fi

# OnePlus
lock_value 0 /proc/oplus_scheduler/sched_assist/sched_assist_enabled
lock_value 0 /proc/oplus_scheduler/sched_assist/sched_assist_scene
if [[ -d  /proc/game_opt ]]; then
  hide_value /proc/game_opt/cpu_max_freq '0:2147483647 1:2147483647 2:2147483647 3:2147483647 4:2147483647 5:2147483647 6:2147483647 7:2147483647'
  hide_value /proc/game_opt/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
  hide_value /proc/game_opt/disable_cpufreq_limit 1
  hide_value /proc/game_opt/game_pid -1
fi
for service in orms-hal-1-0 vendor.oplus.ormsHalService-aidl-default
do
  stop $service
done
lock_value 0 /sys/devices/platform/soc/soc:oplus-omrg/oplus-omrg0/ruler_enable
lock_value 0 /sys/module/oplus_bsp_sched_assist/parameters/boost_kill
for file in silver_core_boost splh_notif lplh_notif dplh_notif l3_boost; do
  lock_value 0 /sys/kernel/msm_performance/parameters/$file
done
echo -R 444 /sys/kernel/msm_performance/parameters
fbg=/proc/sys/fbg
if [[ -d $fbg ]]; then
  for file in frame_boost_enabled  input_boost_enabled  slide_boost_enabled; do
    hide_value $fbg/$file 0
  done
fi


bus_dcvs(){
  echo $2 > /sys/devices/system/cpu/bus_dcvs/$1
  chmod 444 /sys/devices/system/cpu/bus_dcvs/$1
}
bus_dcvs DDR/soc:qcom,memlat:ddr:silver/max_freq 1555000
bus_dcvs DDR/19091000.qcom,bwmon-ddr/max_freq 2736000
bus_dcvs DDR/soc:qcom,memlat:ddr:prime/max_freq 3196000
bus_dcvs DDR/soc:qcom,memlat:ddr:prime-latfloor/max_freq 3196000
bus_dcvs DDR/soc:qcom,memlat:ddr:gold-compute/max_freq 1555000
bus_dcvs DDR/soc:qcom,memlat:ddr:gold/max_freq 3196000
bus_dcvs L3/soc:qcom,memlat:l3:silver/max_freq 1708800
if [[ $(cat /sys/devices/soc0/machine | tr 'a-z' 'A-Z') != 'UKEE' ]]; then
  bus_dcvs L3/soc:qcom,memlat:l3:prime/max_freq 1804800 # default 1708800
  bus_dcvs L3/soc:qcom,memlat:l3:gold/max_freq 1804800 # default 1708800
  bus_dcvs L3/soc:qcom,memlat:l3:prime-compute/max_freq 1804800 # default 1708800
else
  bus_dcvs L3/soc:qcom,memlat:l3:prime/max_freq 1708800
  bus_dcvs L3/soc:qcom,memlat:l3:gold/max_freq 1708800
  bus_dcvs L3/soc:qcom,memlat:l3:prime-compute/max_freq 1708800
fi
bus_dcvs DDRQOS/soc:qcom,memlat:ddrqos:gold/max_freq 1
bus_dcvs DDRQOS/soc:qcom,memlat:ddrqos:prime-latfloor/max_freq 1
bus_dcvs LLCC/soc:qcom,memlat:llcc:gold-compute/max_freq 600000
bus_dcvs LLCC/190b6400.qcom,bwmon-llcc/max_freq 806000
bus_dcvs LLCC/soc:qcom,memlat:llcc:silver/max_freq 600000
bus_dcvs LLCC/soc:qcom,memlat:llcc:gold/max_freq 1066000

set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuset/$2/tasks
    done
  done
}

mkdir /dev/cpuset/top-app/7
echo 7 > /dev/cpuset/top-app/7/cpus
echo 0 > /dev/cpuset/top-app/7/mems

set_cpuset vendor.qti.hardware.display.composer-service 'foreground'
set_cpuset surfaceflinger 'foreground'
set_cpuset touch_report 'foreground'
set_cpuset system_server 'foreground'
set_cpuset update_engine 'top-app/7'
