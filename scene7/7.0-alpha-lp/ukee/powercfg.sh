# target=`getprop ro.board.platform`
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

move_to_heavy() {
  pidof $1 | while read pid; do
    # echo $pid > /dev/stune/top-app/heavy/cgroup.procs
    echo $pid > /dev/cpuctl/heavy/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuctl/heavy/tasks
    done
  done
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

process_opt() {
  move_to_heavy vendor.qti.hardware.display.composer-service
  move_to_heavy camerahalserver
  move_to_heavy surfaceflinger
  move_to_heavy system_server
  move_to_heavy com.omarea.vtools
  move_to_heavy com.omarea.gesture
  move_to_heavy android.hardware.audio.service_64
  move_to_heavy audioserver
  move_to_heavy media.audio.qc.codec .qti.media.c2audio@1.0-service
  move_to_heavy vendor.xiaomi.hw.touchfeature@1.0-service
  move_to_heavy 'android:ui'

  kernel_thread_set

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

kernel_thread_set(){
  pgrep -ef 'kcompactd0' | while read pid
  do
    taskset -p 3f $pid > /dev/null
  done
}

mk_cpuctl 'heavy' 1 0 0 max
mkdir /dev/cpuset/heavy
echo 0-6 > /dev/cpuset/heavy/cpus
# mk_stune 'top-app/heavy' 0 0
echo 128 > /dev/cpuctl/background/cpu.shares
echo 128 > /dev/cpuctl/l-background/cpu.shares
echo 384 > /dev/cpuctl/system-background/cpu.shares
# echo 512 > /dev/cpuctl/foreground/cpu.shares
# rmdir /dev/cpuset/background/untrustedapp

disable_migt() {
  migt=/sys/module/migt/parameters
  if [[ -e $migt ]]; then
    hide_value $migt/migt_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
    hide_value $migt/glk_freq_limit_start '0'
    hide_value $migt/glk_freq_limit_walt '0'
    hide_value $migt/glk_maxfreq '0 0 0'
    hide_value $migt/glk_minfreq '307200 633600 787200'
    hide_value $migt/migt_ceiling_freq '0 0 0'
    hide_value $migt/glk_disable '1'
    hide_value $migt/mi_freq_enable '0'
    hide_value $migt/force_stask_to_big '0'
    hide_value $migt/glk_fbreak_enable '0'
    hide_value $migt/force_reset_runtime '0'

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

t_message=/sys/class/thermal/thermal_message
if [[ -f $t_message/cpu_limits ]]; then
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

# OnePlus
hide_value /proc/oplus_scheduler/sched_assist/sched_impt_task ''
lock_value N /sys/module/oplus_ion_boost_pool/parameters/debug_boost_pool_enable
if [[ -d  /proc/game_opt ]]; then
  hide_value /proc/game_opt/cpu_max_freq '0:2147483647 1:2147483647 2:2147483647 3:2147483647 4:2147483647 5:2147483647 6:2147483647 7:2147483647'
  hide_value /proc/game_opt/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
  hide_value /proc/game_opt/game_pid -1
  hide_value /proc/game_opt/disable_cpufreq_limit 1
fi
hide_value /proc/task_info/task_sched_info/task_sched_info_enable 0
hide_value /proc/oplus_scheduler/sched_assist/sched_assist_enabled 0
echo 0 > /proc/sys/kernel/sched_force_lb_enable
lock_value N /sys/module/sched_assist_common/parameters/boost_kill
lock_value N /sys/module/task_sched_info/parameters/sched_info_ctrl
for service in orms-hal-1-0 # gameopt_hal_service-1-0 midas_hal_service thermal_mnt_hal_servic
do
  stop $service
done
setprop persist.sys.hans.skipframe.enable false
lock_value 0 /sys/devices/platform/soc/soc:oplus-omrg/oplus-omrg0/ruler_enable
echo 0 0 0 0 0 0 0 0 0 0 0 0 0 > /proc/oplus_frame_boost/stune_boost
lock_value 0 /sys/module/oplus_bsp_sched_assist/parameters/boost_kill
for file in silver_core_boost splh_notif lplh_notif dplh_notif l3_boost; do
  lock_value 0 /sys/kernel/msm_performance/parameters/$file
done
echo -R 444 /sys/kernel/msm_performance/parameters

kgsl(){
  lock_value $2 /sys/class/kgsl/kgsl-3d0/$1
}
pl_max=$(($(cat /sys/class/kgsl/kgsl-3d0/num_pwrlevels)-1))
kgsl thermal_pwrlevel 0
kgsl min_pwrlevel $pl_max
kgsl max_pwrlevel 0
kgsl min_pwrlevel $pl_max
kgsl default_pwrlevel $pl_max
kgsl max_clock_mhz 999
kgsl max_gpuclk 999000000
kgsl min_clock_mhz 0
kgsl devfreq/min_freq 0
kgsl devfreq/max_freq 999000000

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
bus_dcvs L3/soc:qcom,memlat:l3:prime/max_freq 1708800
bus_dcvs L3/soc:qcom,memlat:l3:gold/max_freq 1708800
bus_dcvs L3/soc:qcom,memlat:l3:prime-compute/max_freq 1708800
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

mkdir /dev/cpuset/top-app/sf
echo 0-5 > /dev/cpuset/top-app/sf/cpus
echo 0 > /dev/cpuset/top-app/sf/mems
set_cpuset surfaceflinger "top-app/sf"
set_cpuset vendor.qti.hardware.display.composer-service 'top-app/sf'

set_cpuset touch_report 'foreground'
set_cpuset system_server 'foreground'
set_cpuset update_engine 'top-app/7'
