cfg_dir=$(cd $(dirname $0); pwd)

killall scene-scheduler 2>/dev/null

# rm /data/system/mcd/*
if [[ -e /data/system/mcd ]]; then
qt='[CUSTOMIZE_FILTER]
com.tencent.tmgp.speedmobile="1 2 2.0 6.0"
com.miHoYo.Yuanshen="1 1 0.0 4.0"
com.netease.jddsaef="2 1 -2.0 2.0"
com.tencent.tmgp.sgame="1 2 0.0 4.0"
'
glt='[com.tencent.tmgp.speedmobile]
glt=disable
[com.netease.jddsaef]
glt=disable
[com.tencent.tmgp.sgame]
glt=disable
[com.miHoYo.Yuanshen]
glt=disable
'

migl='yuanshen 1600 720 -1
pubg -1 -1 -1
'
  if [[ -f /data/system/mcd/migl ]]; then
    chmod 666 /data/system/mcd/migl
  fi
  chmod 664 /data/system/mcd/migl
  echo -n "$migl" > /data/system/mcd/migl
  chmod 444 /data/system/mcd/migl

  chmod 664 /data/system/mcd/qt.cfg
  echo -n "$qt" > /data/system/mcd/qt.cfg
  chmod 444 /data/system/mcd/qt.cfg

  chmod 664 /data/system/mcd/glt.cfg
  echo -n "$glt" > /data/system/mcd/glt.cfg
  chmod 444 /data/system/mcd/glt.cfg

  if [[ -e /data/system/mcd/df ]]; then
    chattr -i /data/system/mcd/df
    rm /data/system/mcd/df
    echo '' > /data/system/mcd/df
    chattr +i /data/system/mcd/df
  fi
  # echo "$qt" > /data/system/mcd/qt.cfg
fi
if [[ -e /data/system/migt/migt ]]; then
  rm -rf /data/system/migt/migt
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

tcp_low_latency() {
  if [[ "$1" == '1' ]]; then
    echo 1 > /proc/sys/net/ipv4/tcp_low_latency
    echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle
  else
    echo 0 > /proc/sys/net/ipv4/tcp_low_latency
    echo 1 > /proc/sys/net/ipv4/tcp_slow_start_after_idle
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

process_renice() {
  # pidof $1 | while read pid; do
  for pid in $(echo "$ps_cache" | grep -i -E "$1" | awk '{print $1}'); do
    renice -n $2 $pid
  done
}

for index in 0 1 2 3 4 5 6 7; do
  hide_value /sys/devices/system/cpu/cpu$index/online 1
done

# CPU
cpu_governor='schedutil' # sugov_ext is too slow, schedutil is too fast
for policy in 0 4 7
do
  cur_governor=$(cat /sys/devices/system/cpu/cpufreq/policy${policy}/scaling_governor)
  if [[ "$cur_governor" != $cpu_governor ]]; then
    echo $cpu_governor > /sys/devices/system/cpu/cpufreq/policy${policy}/scaling_governor
  fi
  echo 1000 > /sys/devices/system/cpu/cpufreq/policy${policy}/$cur_governor/up_rate_limit_us
  echo 1000 > /sys/devices/system/cpu/cpufreq/policy${policy}/$cur_governor/down_rate_limit_us
done

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
  move_cpuctl 'adbd|kworker' 'foreground'

  process_renice android.hardware.media.c2 -15
  process_renice android.hardware.graphics.composer -15
  process_renice android.hardware.audio.service.mediatek -15
  process_renice audioserver -15
  process_renice toucheventcheck -20
  process_renice vendor.xiaomi.hw.touchfeature -20

  # pm disable com.miui.guardprovider/com.miui.guardprovider.manager.SecurityService

  # set_cpuset mediaserver background
  # set_cpuset media.hwcodec background

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
  pgrep -ef kworker | while read pid
  do
    taskset -p 3f $pid > /dev/null
  done
}

mk_cpuctl 'heavy' 1 0 0 max
mk_cpuctl 'top-app/limited' 1 0 0 0
mkdir /dev/cpuset/heavy
echo 0-6 > /dev/cpuset/heavy/cpus
# mk_stune 'top-app/heavy' 0 0

process_opt &

core_ctl_preset(){
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  echo 20 > $cpu7_core_ctl_dir/offline_throttle_ms
  echo 0 > $cpu7_core_ctl_dir/enable
  echo 1 > $cpu7_core_ctl_dir/max_cpus
  echo 0 > $cpu7_core_ctl_dir/min_cpus
  # echo 95 > $cpu7_core_ctl_dir/thermal_up_thres
  echo 80 > $cpu7_core_ctl_dir/up_thres
  echo 1 > $cpu7_core_ctl_dir/not_preferred

  cpu4_core_ctl_dir=/sys/devices/system/cpu/cpu4/core_ctl
  echo 20 > $cpu4_core_ctl_dir/offline_throttle_ms
  echo 0 > $cpu4_core_ctl_dir/enable
  echo 3 > $cpu4_core_ctl_dir/max_cpus
  echo 1 > $cpu4_core_ctl_dir/min_cpus
  # echo 95 > $cpu4_core_ctl_dir/thermal_up_thres
  echo 80 > $cpu4_core_ctl_dir/up_thres
  echo 0 1 1 > $cpu4_core_ctl_dir/not_preferred

  cpu0_core_ctl_dir=/sys/devices/system/cpu/cpu0/core_ctl
  echo 10 > $cpu0_core_ctl_dir/offline_throttle_ms
  echo 0 > $cpu0_core_ctl_dir/enable
  echo 4 > $cpu0_core_ctl_dir/max_cpus
  echo 0 > $cpu0_core_ctl_dir/min_cpus
  # echo 95 > $cpu0_core_ctl_dir/thermal_up_thres
  echo 90 > $cpu0_core_ctl_dir/up_thres
  echo 1 1 1 1 > $cpu0_core_ctl_dir/not_preferred

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
# hide_value /sys/kernel/ged/hal/dcs_mode 0
# hide_value /proc/cpudvfs/cpufreq_debug '4 400000 2850000'
# hide_value /sys/kernel/fpsgo/fbt/switch_idleprefer 0
lock_value 0 /sys/kernel/fpsgo/fbt/switch_idleprefer

echo 128 > /dev/cpuctl/background/cpu.shares
echo 384 > /dev/cpuctl/system-background/cpu.shares
echo 512 > /dev/cpuctl/foreground/cpu.shares

for group in foreground top-app system system-background ui
do
  echo 1 > /dev/cpuctl/$group/cpu.uclamp.latency_sensitive
done

for group in background
do
  echo 0 > /dev/cpuctl/$group/cpu.uclamp.latency_sensitive
done

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
echo 41 > /sys/module/mtk_fpsgo/parameters/max_freq_limit_level # default 42
echo 2 > /sys/module/mtk_fpsgo/parameters/min_freq_limit_level # default 2
echo 10 > /sys/module/mtk_fpsgo/parameters/variance # default 40

# lock_value 0 /sys/module/sspm_v3/holders/ged/parameters/is_GED_KPI_enabled
# lock_value 0 /sys/kernel/fpsgo/common/fpsgo_enable

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

module=/data/adb/modules/scene_systemless
module_system_etc=$module/system/etc
module_vendor_etc=$module/system/vendor/etc

if [[ -d /data/adb/modules/extreme_gt ]]; then
  rm -rf /data/adb/modules/extreme_gt
fi

for file in powercontable.xml power_app_cfg.xml powerscntbl.xml
do
  find /data/adb/modules -name $file | grep -v pandora | while read found; do
    rm -f $found
  done
done
