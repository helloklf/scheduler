cfg_dir=$(cd $(dirname $0); pwd)

# rm /data/system/mcd/*
if [[ -e /data/system/mcd ]]; then
  if [[ -f /data/system/mcd/migl ]]; then
    chmod 666 /data/system/mcd/migl
  fi
  echo -n '' > /data/system/mcd/migl
  echo 'yuanshen 1600 720 -1' >> /data/system/mcd/migl
  echo 'pubg -1 -1 -1' >> /data/system/mcd/migl
  chmod 444 /data/system/mcd/migl
  if [[ -e /data/system/mcd/df ]]; then
    chattr -i /data/system/mcd/df
    rm /data/system/mcd/df
    echo '' > /data/system/mcd/df
    chattr +i /data/system/mcd/df
  fi
fi
if [[ -e /data/system/migt/migt ]]; then
  rm -rf /data/system/migt/migt
fi
echo 0 > /sys/module/mtk_fpsgo/parameters/max_freq_limit_level
echo 0 > /sys/module/mtk_fpsgo/parameters/min_freq_limit_level
echo 10 > /sys/module/mtk_fpsgo/parameters/variance

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

core_ctl_policy() {
  if [[ "$1" == "on" || "$1" == "1" ]]; then
    to_on=1
  else
    to_on=0
  fi

  echo $to_on > /sys/module/scheduler/holders/mtk_core_ctl/parameters/policy_enable
  echo $to_on > /sys/module/thermal_interface/holders/mtk_core_ctl/parameters/policy_enable
  echo $to_on > /sys/module/mtk_core_ctl/parameters/policy_enable
  echo $to_on > /sys/module/cpufreq_sugov_ext/holders/mtk_core_ctl/parameters/policy_enable
  echo $to_on > /sys/devices/system/cpu/cpu0/core_ctl/enable
  echo $to_on > /sys/devices/system/cpu/cpu4/core_ctl/enable
  echo $to_on > /sys/devices/system/cpu/cpu7/core_ctl/enable
  echo $to_on > /sys/module/cpufreq_sugov_ext/holders/mtk_core_ctl/parameters/policy_enable
}

mk_cpuctl () {
  mkdir -p "/dev/cpuctl/$1"
  # echo $2 > /dev/cpuctl/$1/cpu.uclamp.sched_boost_no_override
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

move_to_cpuset() {
  local pid="$1"
  local cpuset="/dev/cpuset/$2/cgroup.procs"
  if [[ "$pid" != "" ]] && [[ -e "$cpuset" ]]; then
    echo $pid > "$cpuset"
  fi
}

set_cpuset(){
  pidof $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    # echo $pid > /dev/stune/$2/cgroup.procs
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

process_renice() {
  pidof $1 | while read pid; do
    renice -n $2 $pid
  done
}

for index in 0 1 2 3 4 5 6 7; do
  hide_value /sys/devices/system/cpu/cpu$index/online 1
done

# CPU
cpu_governor='schedutil' # sugov_ext is too slow
for policy in 0 4 7
do
  cur_governor=$(cat /sys/devices/system/cpu/cpufreq/policy${policy}/scaling_governor)
  if [[ "$cur_governor" != $cpu_governor ]]; then
    echo $cpu_governor > /sys/devices/system/cpu/cpufreq/policy${policy}/scaling_governor
  fi
done

process_opt() {
  sleep 20
  set_cpuset surfaceflinger foreground
  set_cpuset system_server foreground
  set_cpuset android.hardware.graphics.composer@2.3-service foreground
  set_cpuset toucheventcheck foreground
  set_cpuset vendor.xiaomi.hw.touchfeature@1.0-service foreground
  set_cpuset vendor.mediatek.hardware.pq@2.2-service foreground
  set_cpuset android.hardware.sensors@2.0-service.multihal-mediatek foreground
  set_cpuset lmkd foreground
  set_cpuset statsd foreground
  set_cpuset logd foreground
  set_cpuset scene-daemon foreground
  # set_cpuset camerahalserver camera-daemon
  set_cpuset 'android:ui' top-app

  set_cpuset mediaserver64 heavy
  set_cpuset android.hardware.media.c2@1.2-mediatek-64b heavy

  move_to_heavy android.hardware.graphics.composer@2.3-service
  move_to_heavy com.android.systemui
  move_to_heavy com.miui.home
  move_to_heavy camerahalserver
  move_to_heavy surfaceflinger
  move_to_heavy system_server
  move_to_heavy com.omarea.vtools
  move_to_heavy com.omarea.gesture
  move_to_heavy android.hardware.audio.service.mediatek
  move_to_heavy toucheventcheck
  move_to_heavy vendor.xiaomi.hw.touchfeature@1.0-service
  move_to_heavy 'android:ui'

  process_renice android.hardware.media.c2@1.2-mediatek-64b -15
  process_renice android.hardware.graphics.composer@2.3-service -15
  process_renice android.hardware.audio.service.mediatek -15
  process_renice audioserver -15
  process_renice toucheventcheck -20
  process_renice vendor.xiaomi.hw.touchfeature@1.0-service -20

  # pm disable com.miui.guardprovider/com.miui.guardprovider.manager.SecurityService

  # set_cpuset mediaserver background
  # set_cpuset media.hwcodec background

  # set_task_affinity `pgrep com.miui.home` 11111111
  # set_task_affinity `pgrep com.miui.home` 11110000

  kernel_thread_set

  pidof system_server | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    # echo $pid > /dev/stune/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      case $(cat /proc/$pid/task/$tid/comm) in
        "android.anim"*)
          echo $tid > /dev/cpuset/top-app/tasks
          taskset -p f0 $tid > /dev/null
        ;;
        "HeapTaskDaemon"*)
          taskset -p f $tid > /dev/null
        ;;
      esac
      # echo $tid > /dev/cpuset/$2/tasks
    done
  done

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

kernel_thread_set(){
  pgrep -ef 'kcompactd0' | while read pid
  do
    taskset -p 3f $pid > /dev/null
  done
  pgrep -ef 'aal_sof' | while read pid
  do
    taskset -p 3f $pid > /dev/null
  done
  pgrep -ef 'kfps' | while read pid
  do
    taskset -p 3f $pid > /dev/null
  done
}

mk_cpuctl 'heavy' 1 0 1 max
# mk_stune 'top-app/heavy' 0 0

process_opt &



core_ctl_preset(){
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  echo 10 > $cpu7_core_ctl_dir/offline_throttle_ms
  # echo 1 > $cpu7_core_ctl_dir/enable
  echo 1 > $cpu7_core_ctl_dir/max_cpus
  echo 0 > $cpu7_core_ctl_dir/min_cpus
  # echo 95 > $cpu7_core_ctl_dir/thermal_up_thres
  echo 70 > $cpu7_core_ctl_dir/up_thres
  echo 1 > $cpu7_core_ctl_dir/not_preferred

  cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
  echo 20 > $cpu4_core_ctl_dir/offline_throttle_ms
  # echo 1 > $cpu4_core_ctl_dir/enable
  echo 3 > $cpu4_core_ctl_dir/max_cpus
  echo 0 > $cpu4_core_ctl_dir/min_cpus
  # echo 95 > $cpu4_core_ctl_dir/thermal_up_thres
  echo 85 > $cpu4_core_ctl_dir/up_thres
  echo 1 1 1 > $cpu4_core_ctl_dir/not_preferred

  cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
  echo 100 > $cpu0_core_ctl_dir/offline_throttle_ms
  # echo 1 > $cpu0_core_ctl_dir/enable
  echo 4 > $cpu0_core_ctl_dir/max_cpus
  echo 1 > $cpu0_core_ctl_dir/min_cpus
  # echo 95 > $cpu0_core_ctl_dir/thermal_up_thres
  echo 75 > $cpu0_core_ctl_dir/up_thres
  echo 0 1 1 1 > $cpu0_core_ctl_dir/not_preferred

  core_ctl_policy on
}

core_ctl_preset

# stop miuibooster

module=/data/adb/modules/scene_systemless
module_system_etc=$module/system/etc
module_vendor_etc=$module/system/vendor/etc

task_profiles_modify() {
  json='/system/vendor/etc/task_profiles.json'
  kw='"Name": "ProcessCapacityLow"'
  ri=$(sed -n "/$kw/=" $json)
  if [[ "$ri" != '' ]]; then
    tr=$((ri+7))
    is_normal=$(sed -n -e ${tr}p $json | grep "background")
    if [[ "$is_normal" != "" ]]; then
      replace='\ \ \ \ \ \ \ \ \ \ \ \ "Path": "restricted"'
      sed "${tr}c${replace}" $json > $module_system_etc/task_profiles.json
      cp -f $module_system_etc/task_profiles.json $module_vendor_etc/task_profiles.json
    fi
  fi
}

if [[ -d $module ]]; then
  mkdir -p $module_system_etc
  mkdir -p $module_vendor_etc
  if [[ -f $module_vendor_etc/mi_thermal_break.cfg ]]; then
    rm $module_vendor_etc/mi_thermal_break.cfg
  fi
  #if [[ -f $cfg_dir/mi_thermal_break.cfg ]];then
  #  cp $cfg_dir/mi_thermal_break.cfg $module_vendor_etc/
  #fi
  manufacturer=$(getprop ro.product.manufacturer)
  if [[ "$manufacturer" == "Xiaomi" ]]; then
    if [[ -f $cfg_dir/task_profiles.json ]];then
      cp $cfg_dir/task_profiles.json $module_vendor_etc/
      cp $cfg_dir/task_profiles.json $module_system_etc/
    fi
    if [[ -f $cfg_dir/perfinit.conf ]];then
      cp $cfg_dir/perfinit.conf $module_system_etc/
    fi
  else
    if [[ -f $module_vendor_etc/task_profiles.json ]]; then
      rm -f $module_vendor_etc/task_profiles.json
    fi
    if [[ -f $module_system_etc/task_profiles.json ]]; then
      rm -f $module_system_etc/task_profiles.json
    fi
  fi
fi

echo 0 > /proc/sys/kernel/sched_util_clamp_min
echo 1-4 > /dev/cpuset/restricted/cpus
echo 0 > /dev/cpuset/restricted/sched_load_balance
if [[ $(cat /dev/cpuset/background/untrustedapp/cgroup.procs) == "" ]]; then
  rmdir /dev/cpuset/background/untrustedapp
fi

t_message=/sys/class/thermal/thermal_message
if [[ -f $t_message/cpu_limits ]]; then
  chmod 644 $t_message/cpu_limits
  for i in $(seq 0 7); do
    echo cpu$i 3300000 > $t_message/cpu_limits
  done
  chmod 444 $t_message/cpu_limits
fi
hide_value $t_message/market_download_limit 0
hide_value $t_message/modem_limit 0

# experimental
echo 1 > /sys/class/misc/mali0/device/csg_scheduling_period
echo 5 > /sys/class/misc/mali0/device/idle_hysteresis_time
echo coarse_demand > /sys/class/misc/mali0/device/power_policy
hide_value /sys/devices/platform/soc/1c00f000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/userspace/set_freq 0
# echo 1 > /proc/displowpower/hrt_lp
# echo 31 > /proc/displowpower/idletime
# hide_value /sys/class/devfreq/13000000.mali/min_freq 0
# hide_value /sys/class/devfreq/13000000.mali/max_freq 0
hide_value /sys/module/ged/parameters/gpu_cust_boost_freq 0
hide_value /sys/kernel/ged/hal/dcs_mode 0
# hide_value /sys/kernel/fpsgo/fbt/switch_idleprefer 0
hide_value /sys/kernel/fpsgo/minitop/enable 0
hide_value /proc/cpudvfs/cpufreq_debug '4 400000 2850000'

echo 128 > /dev/cpuctl/background/cpu.shares
echo 384 > /dev/cpuctl/system-background/cpu.shares
echo 512 > /dev/cpuctl/foreground/cpu.shares
# rmdir /dev/cpuset/background/untrustedapp

for group in background foreground top-app system system-background ui
do
  echo 0 > /dev/cpuctl/$group/cpu.uclamp.latency_sensitive
done

# resetprop persist.sys.miui.adj_update_foreground_state.enable.delayMs 100

if [[ -d /data/adb/modules/extreme_gt ]]; then
  rm -rf /data/adb/modules/extreme_gt
fi

for file in powercontable.xml power_app_cfg.xml powerscntbl.xml
do
  find /data/adb/modules -name $file | while read found; do
    rm -f $found
  done
done

# Mi 3:powersave 2:balance 1:performance
# /sys/devices/virtual/thermal/thermal_message/balance_mode

# resetprop persist.sys.miui.adj_update_foreground_state.enable.delayMs 100

# Fix Scene'[Magisk]SwapController Bugs
# resetprop persist.sys.lmk.camera_minfree_levels ''
lock_value 0 /proc/sys/vm/panic_on_oom

