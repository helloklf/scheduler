cfg_dir=$(cd $(dirname $0); pwd)

killall scene-scheduler 2>/dev/null

# rm /data/system/mcd/*
if [[ -e /data/system/mcd ]]; then

migl='yuanshen 1600 720 -1
pubg -1 -1 -1
'
  if [[ -f /data/system/mcd/migl ]]; then
    chmod 666 /data/system/mcd/migl
  fi
  chmod 664 /data/system/mcd/migl
  echo -n "$migl" > /data/system/mcd/migl
  chmod 444 /data/system/mcd/migl

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
  echo $1 > /sys/module/scheduler/holders/mtk_core_ctl/parameters/policy_enable
  echo $1 > /sys/module/thermal_interface/holders/mtk_core_ctl/parameters/policy_enable
  echo $1 > /sys/module/mtk_core_ctl/parameters/policy_enable
  echo $1 > /sys/module/cpufreq_sugov_ext/holders/mtk_core_ctl/parameters/policy_enable
  echo $1 > /sys/devices/system/cpu/cpu0/core_ctl/enable
  echo $1 > /sys/devices/system/cpu/cpu4/core_ctl/enable
  echo $1 > /sys/devices/system/cpu/cpu7/core_ctl/enable
  echo $1 > /sys/module/cpufreq_sugov_ext/holders/mtk_core_ctl/parameters/policy_enable
}
core_ctl_policy 0
cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
lock_value 0 $cpu7_core_ctl_dir/enable
lock_value 1 $cpu7_core_ctl_dir/max_cpus
lock_value 1 $cpu7_core_ctl_dir/min_cpus

cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
lock_value 3 $cpu4_core_ctl_dir/max_cpus
lock_value 3 $cpu4_core_ctl_dir/min_cpus
lock_value 0 $cpu4_core_ctl_dir/enable

cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
lock_value 4 $cpu0_core_ctl_dir/max_cpus
lock_value 4 $cpu0_core_ctl_dir/min_cpus
lock_value 0 $cpu0_core_ctl_dir/enable

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

echo 41 > /sys/module/mtk_fpsgo/parameters/max_freq_limit_level # default 42
echo 2 > /sys/module/mtk_fpsgo/parameters/min_freq_limit_level # default 2
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
# lock_value 0 /sys/kernel/ged/hal/custom_upbound_gpu_freq
dvfs_loading_mode=/sys/kernel/ged/hal/dvfs_loading_mode
if [[ $(cat $dvfs_loading_mode) != "0" ]]; then
  chmod 777 $dvfs_loading_mode
  echo 0 > $dvfs_loading_mode
fi
chmod 000 $dvfs_loading_mode

# echo 0 > /sys/module/millet_core/parameters/millet_freeze_switch

module=/data/adb/modules/scene_systemless
module_system_etc=$module/system/etc
module_vendor_etc=$module/system/vendor/etc

for file in powercontable.xml power_app_cfg.xml powerscntbl.xml
do
  find /data/adb/modules -name $file | grep -v pandora | grep -v scene | while read found; do
    rm -f $found
  done
done

if [[ -d $module ]]; then
  mkdir -p $module_system_etc
  mkdir -p $module_vendor_etc
  if [[ -f $cfg_dir/powerscntbl.xml ]];then
    cp $cfg_dir/powerscntbl.xml $module_vendor_etc/
  fi
fi


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
