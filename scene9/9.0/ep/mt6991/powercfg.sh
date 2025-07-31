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
lock_value 0 $t_message/market_download_limit
lock_value 0 $t_message/modem_limit
lock_value 0 0 0 0 /sys/class/thermal/thermal_message/boost

lock_value 0 /sys/kernel/fpsgo/fbt/enable_ceiling
lock_value 0 /sys/module/mtk_fpsgo/parameters/perfmgr_enable

# hide_value /proc/perfmgr/perf_ioctl
# mount --bind /proc/perfmgr/fpsgo_lr_ioctl /proc/perfmgr/perf_ioctl
if [[ $(grep /proc/perfmgr/perf_ioctl /proc/mounts) == '' ]]; then
mount --bind /proc/perfmgr_touch_boost/ioctl_touch_boost /proc/perfmgr/perf_ioctl
fi

umount /proc/powerhal_cpu_ctrl/perfserv_freq
echo '339000 2400000 622000 3300000 798000 3600000' > /proc/powerhal_cpu_ctrl/perfserv_freq
mount --bind /proc/powerhal_cpu_ctrl/adpf_enable /proc/powerhal_cpu_ctrl/perfserv_freq
lock_value '3300000 3600000' /sys/module/mtk_fpsgo/parameters/cpus_limit
# lock_value 1 /sys/module/mtk_fpsgo/parameters/better_perf

chmod 444 /sys/kernel/fpsgo/fbt/fbt_attr_by_pid
chmod 444 /sys/kernel/fpsgo/fbt/fbt_attr_by_tid
lock_value 0 /sys/module/mtk_fpsgo/parameters/boost_affinity

# echo 1 > /sys/module/migt/parameters/force_reset_runtime
# lock_value 0 /sys/module/migt/parameters/enable_pkg_monitor
lock_value 1 /sys/module/migt/parameters/glk_disable
lock_value 0 /sys/module/migt/parameters/glk_fbreak_enable
lock_value 0 /sys/module/migt/parameters/force_cluster_sched_enable
lock_value -1 /sys/module/migt/parameters/render_prefer_cluster
lock_value -1 /sys/module/migt/parameters/vip_prefer_cluster
lock_value -1 /sys/module/migt/parameters/stask_prefer_cluster
lock_value -1 /sys/module/migt/parameters/ip_prefer_cluster
lock_value 0 /sys/module/migt/parameters/glk_freq_limit_start
echo '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' > /sys/module/migt/parameters/migt_ceiling_freq
echo '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' > /sys/module/migt/parameters/migt_freq
echo 1 > /sys/module/metis/parameters/reset_clus_affinity_uidlist
echo 1 > /sys/module/metis/parameters/reset_rebind_task
lock_value 0 /sys/module/metis/parameters/thermal_break_enable
lock_value 0 /sys/module/metis/parameters/is_break_enable
lock_value 0 /sys/module/metis/parameters/mi_freq_enable

chmod 444 /proc/perfmgr/global_reclaim

metis=/sys/module/metis/parameters
for file in $metis/*enable*; do
  lock_value 0 $file
done
if [[ -d $metis ]]; then
  chmod -R 444 $metis
fi

# echo 1 > /sys/module/mtk_core_ctl/parameters/policy_enable
lock_value 1 /sys/devices/system/cpu/cpu4/core_ctl/enable
lock_value 3 /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
lock_value 3 /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
lock_value 0 /sys/devices/system/cpu/cpu4/core_ctl/enable

lock_value 1 /sys/devices/system/cpu/cpu7/core_ctl/enable
lock_value 1 /sys/devices/system/cpu/cpu7/core_ctl/max_cpus
lock_value 1 /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
lock_value 0 /sys/devices/system/cpu/cpu7/core_ctl/enable

echo 12000000 > /sys/kernel/debug/sched/latency_ns # default 24000000
echo 2000000 > /sys/kernel/debug/sched/min_granularity_ns # default 3000000
echo 3000000 > /sys/kernel/debug/sched/wakeup_granularity_ns # default 4000000


# vivo
if [[ -e /sys/module/vivo_board_info ]] || [[ -e /sys/module/vivo_display ]]; then
  stop vivo-vperf-hal-1-0
  stop vendor.vivoperfservice
  echo 0 > /proc/powerhal_cpu_ctrl/adpf_enable
  stop thermal_core
  stop thermald
  stop touch_boost
fi
if [[ $(getprop vtools.thermal.disguise) != '1' ]]; then
  lock_value "MIN_TTJ 90000 90000 90000" /sys/kernel/thermal/min_ttj
  lock_value "MAX_TTJ 95000 90000 90000" /sys/kernel/thermal/max_ttj
  lock_value "TTJ 90000 90000 90000" /sys/kernel/thermal/ttj
fi


lock_value 1 /proc/game_opt/disable_cpufreq_limit
lock_value 1 /sys/module/migt/parameters/glk_disable
lock_value 0 /sys/module/perfmgr/parameters/perfmgr_enable
lock_value 0 /sys/module/migt/parameters/glk_freq_limit_walt
lock_value 0 /sys/module/cpufreq_bouncing/parameters/enable
lock_value 0 /sys/devices/platform/soc/soc:oplus-omrg/oplus-omrg0/ruler_enable
lock_value 0 /proc/task_overload/skip_goplus_enabled
lock_value 0 /sys/module/mtk_fpsgo/parameters/cfp_onoff
stop vendor.oplus.ormsHalService-aidl-default

# set_slc [cpu%] [gpu%]
set_slc_force_ratio(){
  chmod 777 /proc/oplus_slc/force_ratio
  echo 1,$1 > /proc/oplus_slc/force_ratio # cpu
  echo 2,$2 > /proc/oplus_slc/force_ratio # gpu
  chmod 444 /proc/oplus_slc/force_ratio
}

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

set_cpuset touch_report 'foreground'
set_cpuset surfaceflinger 'foreground'
set_cpuset system_server 'foreground'
set_cpuset update_engine 'top-app/7'
set_cpuset vendor.qti.hardware.display.composer-service 'foreground'

for file in ls /sys/kernel/fpsgo/fbt/*limit*
do
  lock_value 0 $file
done

stop_services(){
  services="magt fpsgo ged oiface midasd frs uart_launcher touch_boost oplus_sched oplus_sched_rename"
  for service in $services; do
    stop $service
    killall $service
  done
}
# stop_services

gpu_ulimit(){
  # release gpu 1.6ghz
  for i in $(seq 0 9); do
    echo "switch $i 0 0" > /proc/gpufreq/limit_table
  done
  # gpt index temp opp
  echo "enable" > /sys/kernel/thermal/gpt
  echo "gpt 1 85000 7" > /sys/kernel/thermal/gpt
  echo "gpt 2 90000 12" > /sys/kernel/thermal/gpt
  echo "disable" > /sys/kernel/thermal/gpt
}
gpu_ulimit
