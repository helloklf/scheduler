cfg_dir=$(cd $(dirname $0); pwd)

killall scene-scheduler 2>/dev/null

# rm /data/system/mcd/*
if [[ -e /data/system/mcd ]]; then
  if [[ -e /data/system/mcd/df ]]; then
    chattr -i /data/system/mcd/df
    rm /data/system/mcd/df
    echo '' > /data/system/mcd/df
    chattr +i /data/system/mcd/df
  fi
fi

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
  # echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
}

lock_value () {
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
    mount --bind "$c_path" "$1"
  else
    echo "$1" Not Found!
  fi
}

# Derived from uperf
ps_cache="$(ps -Ao pid,args)"
# $1:task_name $2:cgroup_name
change_task_cpuset() {
  for temp_pid in $(echo "$ps_cache" | grep -i -E "$1" | awk '{print $1}'); do
    for temp_tid in $(ls "/proc/$temp_pid/task/"); do
      echo "$temp_tid" >"/dev/cpuset/$2/tasks"
    done
  done
}

move_cpuctl() {
  # pidof $1 | while read pid; do
  for pid in $(echo "$ps_cache" | grep -i -E "$1" | awk '{print $1}'); do
    # echo $pid > /dev/stune/top-app/heavy/cgroup.procs
    echo $pid > /dev/cpuctl/heavy/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuctl/$2/tasks
    done
  done
}

move_to_heavy() {
  # pidof $1 | while read pid; do
  for pid in $(echo "$ps_cache" | grep -i -E "$1" | awk '{print $1}'); do
    # echo $pid > /dev/stune/top-app/heavy/cgroup.procs
    echo $pid > /dev/cpuctl/heavy/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuctl/heavy/tasks
    done
  done
}

process_opt() {
  sleep 20

  # change_task_cpuset 'camerahalserver' camera-daemon
  change_task_cpuset 'android:ui|lmkd' 'top-app'
  change_task_cpuset "surfaceflinger|system_server|android.hardware.graphics.composer|toucheventcheck|vendor.xiaomi.hw.touchfeature" "foreground"
  change_task_cpuset "svendor.mediatek.hardware.pq|android.hardware.sensors|statsd|logd|scene-daemon" "foreground"
  change_task_cpuset "aal_sof|kfps|dsp_send_thread|vdec_ipi_recv|mtk_drm_disp_id|disp_feature|hif_thread|main_thread|rx_thread|ged_" "system-background"
  change_task_cpuset 'mediaserver64|android.hardware.media.c2' 'foreground'

  move_to_heavy 'android.hardware.audio.service.mediatek|android.hardware.graphics.composer'
  move_to_heavy 'com.android.systemui|com.miui.home'
  move_to_heavy 'system_server|surfaceflinger|camerahalserver'
  move_to_heavy 'com.omarea.vtools|com.omarea.gesture'
  move_to_heavy 'toucheventcheck|vendor.xiaomi.hw.touchfeature'
  move_to_heavy 'android:ui'
  move_cpuctl 'aal_sof|kfps|wlan%d' 'background'

  for name in 'kcompactd0' 'aal_sof' 'kfps' 'kworker'
  do
    taskset -p 3f $(pgrep -ef $name) > /dev/null
  done
}

mk_cpuctl 'heavy' 1 0 1 max
# mk_stune 'top-app/heavy' 0 0

process_opt &



core_ctl_preset(){
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  echo 20 > $cpu7_core_ctl_dir/offline_throttle_ms
  echo 0 > $cpu7_core_ctl_dir/enable
  echo 1 > $cpu7_core_ctl_dir/max_cpus
  echo 0 > $cpu7_core_ctl_dir/min_cpus
  echo 80 > $cpu7_core_ctl_dir/up_thres
  echo 1 > $cpu7_core_ctl_dir/not_preferred

  cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
  echo 0 > $cpu4_core_ctl_dir/enable

  cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
  echo 0 > $cpu0_core_ctl_dir/enable

  # core_ctl_policy on
}

core_ctl_preset

if [[ $(cat /dev/cpuset/background/untrustedapp/cgroup.procs) == "" ]]; then
  rmdir /dev/cpuset/background/untrustedapp
fi
if [[ $(cat /dev/cpuset/foreground/boost/cgroup.procs) == "" ]]; then
  rmdir /dev/cpuset/background/boost
fi


t_message=/sys/class/thermal/thermal_message
if [[ -f $t_message/cpu_limits ]]; then
  for i in $(seq 0 7); do
    maxfreq=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq)
    echo cpu$i $maxfreq > $t_message/cpu_limits
  done
  chmod 444 $t_message/cpu_limits
fi
hide_value $t_message/market_download_limit 0
hide_value $t_message/modem_limit 0

lock_value 0 /sys/kernel/fpsgo/fbt/switch_idleprefer

setprop persist.sys.miui_animator_sched.bigcores 4-7

echo 10 > /sys/module/mtk_fpsgo/parameters/variance # default 40
# lock_value 0 /sys/module/sspm_v3/holders/ged/parameters/is_GED_KPI_enabled
lock_value 0 /sys/kernel/fpsgo/common/fpsgo_enable

hide_value /sys/kernel/fpsgo/fbt/limit_cfreq 0
hide_value /sys/kernel/fpsgo/fbt/limit_rfreq 0
hide_value /sys/kernel/fpsgo/fbt/limit_cfreq_m 0
hide_value /sys/kernel/fpsgo/fbt/limit_rfreq_m 0

# FEAS dependence, But it will not work if you change the frequency, So disable it
lock_value 0 /sys/module/mtk_fpsgo/parameters/perfmgr_enable

mount -t debugfs none /sys/kernel/debug
lock_value 0 /sys/kernel/ged/hal/custom_upbound_gpu_freq
dvfs_loading_mode=/sys/kernel/ged/hal/dvfs_loading_mode
if [[ $(cat $dvfs_loading_mode) != "0" ]]; then
  chmod 777 $dvfs_loading_mode
  echo 0 > $dvfs_loading_mode
fi
chmod 000 $dvfs_loading_mode

# echo 0 > /sys/module/millet_core/parameters/millet_freeze_switch