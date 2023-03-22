cfg_dir=$(cd $(dirname $0); pwd)

if [[ ! -f "$cfg_dir/powercfg-utils.sh" ]]; then
  echo "The dependent '$cfg_dir/powercfg-utils.sh' was not found !" > /cache/powercfg.sh.log
  exit 1
else
  source "$cfg_dir/powercfg-utils.sh"
fi

for index in 0 1 2 3 4 5 6 7; do
  hide_value /sys/devices/system/cpu/cpu$index/online 1
done

# CPU
cpu_governor='sugov_ext' # sugov_ext is too slow, schedutil is too fast
for policy in 0 4 7
do
  cur_governor=$(cat /sys/devices/system/cpu/cpufreq/policy${policy}/scaling_governor)
  if [[ "$cur_governor" != $cpu_governor ]]; then
    echo $cpu_governor > /sys/devices/system/cpu/cpufreq/policy${policy}/scaling_governor
  fi
  echo 0 > /sys/devices/system/cpu/cpufreq/policy${policy}/$cur_governor/up_rate_limit_us
  echo 1000 > /sys/devices/system/cpu/cpufreq/policy${policy}/$cur_governor/down_rate_limit_us
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
  pgrep -ef 'aal_sof' | while read pid
  do
    taskset -p 3f $pid > /dev/null
  done
  pgrep -ef 'kfps' | while read pid
  do
    taskset -p 3f $pid > /dev/null
  done
}

# cpuctl top-app 0 0 0 max
# cpuctl foreground 0 0 0 max
# cpuctl background 0 0 0 max
mk_cpuctl 'heavy' 1 0 0 max
mkdir /dev/cpuset/heavy
echo 0-6 > /dev/cpuset/heavy/cpus
# mk_stune 'top-app/heavy' 0 0

process_opt &

# Disable MIUI's daemon\joyose
# disable_mi_opt &

# Uninstall MIUI's daemon\joyose
varsion=$(getprop ro.miui.ui.version.name)
if [[ "$varsion" == "V130" ]]; then
  mi_joyose_opt &
  # echo 'mi_joyose_opt'
  uninstall_mi_opt &
elif [[ "$varsion" == "V12" ]]; then
  uninstall_mi_opt &
elif [[ "$varsion" == "V125" ]]; then
  # uninstall_mi_opt &
  echo 'uninstall_mi_opt'
fi

# Reinstall MIUI's daemon\joyose
# reinstall_mi_opt &


core_ctl_preset(){
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  echo 10 > $cpu7_core_ctl_dir/offline_throttle_ms
  # echo 1 > $cpu7_core_ctl_dir/enable
  echo 1 > $cpu7_core_ctl_dir/max_cpus
  echo 0 > $cpu7_core_ctl_dir/min_cpus
  # echo 95 > $cpu7_core_ctl_dir/thermal_up_thres
  echo 90 > $cpu7_core_ctl_dir/up_thres
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
  echo 70 > $cpu0_core_ctl_dir/up_thres
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

if [[ -d /data/adb/modules/extreme_gt ]]; then
  rm -rf /data/adb/modules/extreme_gt
fi

for file in powercontable.xml power_app_cfg.xml powerscntbl.xml
do
  find /data/adb/modules -name $file | while read found; do
    rm -f $found
  done
done

if [[ -d $module ]]; then
  mkdir -p $module_system_etc
  mkdir -p $module_vendor_etc
  if [[ -f $module_vendor_etc/mi_thermal_break.cfg ]]; then
    rm $module_vendor_etc/mi_thermal_break.cfg
  fi
  #if [[ -f $cfg_dir/mi_thermal_break.cfg ]];then
  #  cp $cfg_dir/mi_thermal_break.cfg $module_vendor_etc/
  #fi
  if [[ -f $cfg_dir/task_profiles.json ]];then
    cp $cfg_dir/task_profiles.json $module_vendor_etc/
    cp $cfg_dir/task_profiles.json $module_system_etc/
  fi
  if [[ -f $cfg_dir/perfinit.conf ]];then
    cp $cfg_dir/perfinit.conf $module_system_etc/
  fi
  if [[ -f $cfg_dir/power_app_cfg.xml ]];then
    cp $cfg_dir/power_app_cfg.xml $module_vendor_etc/
  fi
fi

# echo 0 > /proc/sys/kernel/sched_util_clamp_min
echo 0-3 > /dev/cpuset/restricted/cpus
echo 0 > /dev/cpuset/restricted/sched_load_balance
if [[ $(cat /dev/cpuset/background/untrustedapp/cgroup.procs) == "" ]]; then
  rmdir /dev/cpuset/background/untrustedapp
fi
# hide_value /sys/module/task_turbo/parameters/feats 0

# experimental
# echo 1 > /sys/class/misc/mali0/device/csg_scheduling_period
# echo 5 > /sys/class/misc/mali0/device/idle_hysteresis_time
# echo coarse_demand > /sys/class/misc/mali0/device/power_policy
hide_value /sys/devices/platform/1c00f000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/userspace/set_freq 0
# echo 1 > /proc/displowpower/hrt_lp
# echo 31 > /proc/displowpower/idletime
# hide_value /sys/class/devfreq/13000000.mali/min_freq 0
# hide_value /sys/class/devfreq/13000000.mali/max_freq 0
hide_value /sys/module/ged/parameters/gpu_cust_boost_freq 0
# hide_value /sys/kernel/ged/hal/dcs_mode 0
# hide_value /sys/kernel/fpsgo/fbt/switch_idleprefer 0
# hide_value /proc/cpudvfs/cpufreq_debug '4 400000 2850000'
# hide_value /sys/kernel/fpsgo/fbt/limit_rfreq 0
# hide_value /sys/kernel/fpsgo/fbt/limit_cfreq_m 0
# hide_value /sys/kernel/fpsgo/fbt/limit_rfreq_m 0

echo 128 > /dev/cpuctl/background/cpu.shares
echo 384 > /dev/cpuctl/system-background/cpu.shares
echo 512 > /dev/cpuctl/foreground/cpu.shares
# rmdir /dev/cpuset/background/untrustedapp

for group in foreground top-app system system-background ui
do
  echo 1 > /dev/cpuctl/$group/cpu.uclamp.latency_sensitive
done

for group in background
do
  echo 0 > /dev/cpuctl/$group/cpu.uclamp.latency_sensitive
done

# Mi 3:powersave 2:balance 1:performance
# /sys/devices/virtual/thermal/thermal_message/balance_mode

# resetprop persist.sys.miui.adj_update_foreground_state.enable.delayMs 100

# Fix Scene'[Magisk]SwapController Bugs
# resetprop persist.sys.lmk.camera_minfree_levels ''
lock_value 0 /proc/sys/vm/panic_on_oom
