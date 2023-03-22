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

process_opt() {
  sleep 20

  # change_task_cpuset 'camerahalserver' camera-daemon
  # change_task_cpuset 'android:ui|lmkd' 'top-app'
  # change_task_cpuset "surfaceflinger|system_server|android.hardware.graphics.composer|toucheventcheck|vendor.xiaomi.hw.touchfeature" "foreground"
  change_task_cpuset "svendor.mediatek.hardware.pq|android.hardware.sensors|statsd|logd|scene-daemon" "foreground"
  change_task_cpuset "aal_sof|kfps|dsp_send_thread|vdec_ipi_recv|mtk_drm_disp_id|disp_feature|hif_thread|main_thread|rx_thread|ged_" "system-background"
  change_task_cpuset 'mediaserver64|android.hardware.media.c2' 'foreground'


  for name in 'kcompactd0' 'aal_sof' 'kfps' 'kworker'
    do
    taskset -p 3f $(pgrep -ef $name) > /dev/null
    done
}

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

# hide_value /sys/module/task_turbo/parameters/feats 0

# experimental
# echo 1 > /sys/class/misc/mali0/device/csg_scheduling_period
# echo 5 > /sys/class/misc/mali0/device/idle_hysteresis_time
# echo coarse_demand > /sys/class/misc/mali0/device/power_policy
#   hide_value /sys/devices/platform/1c00f000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/userspace/set_freq 0
# echo 1 > /proc/displowpower/hrt_lp
# echo 31 > /proc/displowpower/idletime
# hide_value /sys/class/devfreq/13000000.mali/min_freq 0
# hide_value /sys/class/devfreq/13000000.mali/max_freq 0
# hide_value /sys/module/ged/parameters/gpu_cust_boost_freq 0 # important, Do not block
hide_value /sys/kernel/ged/hal/dcs_mode 0
# hide_value /sys/kernel/fpsgo/fbt/switch_idleprefer 0
lock_value 0 /sys/kernel/fpsgo/fbt/switch_idleprefer

setprop persist.sys.miui_animator_sched.bigcores 4-7

# echo 0 > /proc/sys/kernel/sched_util_clamp_min
# echo 1-4 > /dev/cpuset/restricted/cpus
# echo 0 > /dev/cpuset/restricted/sched_load_balance
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

# lock_value 240 /sys/kernel/fpsgo/fstb/set_render_max_fps
# lock_value 1 /sys/kernel/fpsgo/fstb/set_render_no_ctrl
# lock_value 0 /sys/kernel/fpsgo/fstb/fstb_self_ctrl_fps_enable
# lock_value '1 240-10' /sys/kernel/fpsgo/fstb/fstb_soft_level
# echo 10 > /sys/module/mtk_fpsgo/parameters/variance # default 40

lock_value 0 /sys/module/sspm_v3/holders/ged/parameters/is_GED_KPI_enabled
hide_value /sys/kernel/fpsgo/common/fpsgo_enable 1

hide_value /sys/kernel/fpsgo/fbt/limit_cfreq 0
hide_value /sys/kernel/fpsgo/fbt/limit_rfreq 0
hide_value /sys/kernel/fpsgo/fbt/limit_cfreq_m 0
hide_value /sys/kernel/fpsgo/fbt/limit_rfreq_m 0

# FEAS dependence, But it will not work if you change the frequency, So disable it
umount /sys/module/mtk_fpsgo/parameters/perfmgr_enable
echo 0 > /sys/module/mtk_fpsgo/parameters/perfmgr_enable

mount -t debugfs none /sys/kernel/debug

dvfs_loading_mode=/sys/kernel/ged/hal/dvfs_loading_mode
if [[ $(cat $dvfs_loading_mode) != "0" ]]; then
  chmod 777 $dvfs_loading_mode
  echo 0 > $dvfs_loading_mode
fi
chmod 000 $dvfs_loading_mode
echo 0 > /sys/class/devfreq/13000000.mali/min_freq
echo 99 > /sys/kernel/ged/hal/custom_boost_gpu_freq
echo 0 > /sys/module/ged/parameters/gpu_cust_boost_freq

# /sys/kernel/cm_mgr/dbg_cm_mgr
# cm_mgr_enable [0|1]
# cm_mgr_perf_enable [0|1]
# dsu_mode_change [0|1]