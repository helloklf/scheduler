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

rmdir /dev/cpuset/background/untrustedapp
rmdir /dev/cpuset/foreground/boost

t_message=/sys/class/thermal/thermal_message
if [[ -f $t_message/cpu_limits ]]; then
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
echo 0 300000 2000000 > /proc/cpudvfs/cpufreq_debug
echo 4 550000 2850000 > /proc/cpudvfs/cpufreq_debug
echo 7 600000 3250000 > /proc/cpudvfs/cpufreq_debug
lock_value '300000 2000000 550000 2850000 600000 3250000' /proc/powerhal_cpu_ctrl/perfserv_freq
lock_value '3000000 3350000' /sys/module/mtk_fpsgo/parameters/cpus_limit
lock_value 1 /sys/module/mtk_fpsgo/parameters/better_perf

chmod 444 /sys/kernel/fpsgo/fbt/fbt_attr_by_pid
chmod 444 /sys/kernel/fpsgo/fbt/fbt_attr_by_tid
lock_value 0 /sys/module/mtk_fpsgo/parameters/boost_affinity

echo 1 > /sys/module/migt/parameters/force_reset_runtime
# lock_value 0 /sys/module/migt/parameters/enable_pkg_monitor
lock_value 1 /sys/module/migt/parameters/glk_disable
lock_value 0 /sys/module/migt/parameters/glk_fbreak_enable
lock_value 0 /sys/module/migt/parameters/force_cluster_sched_enable
lock_value -1 /sys/module/migt/parameters/render_prefer_cluster
lock_value -1 /sys/module/migt/parameters/vip_prefer_cluster
lock_value -1 /sys/module/migt/parameters/stask_prefer_cluster
lock_value -1 /sys/module/migt/parameters/ip_prefer_cluster
# lock_value 1 /sys/module/migt/parameters/affinity_only
echo 0,0,0 > /sys/module/metis/parameters/user_min_freq
lock_value 0 /sys/module/migt/parameters/glk_freq_limit_start
echo '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' > /sys/module/migt/parameters/migt_ceiling_freq
echo '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' > /sys/module/migt/parameters/migt_freq
echo 1 > /sys/module/metis/parameters/reset_clus_affinity_uidlist
echo 1 > /sys/module/metis/parameters/reset_rebind_task
lock_value 0 /sys/module/metis/parameters/thermal_break_enable
lock_value 0 /sys/module/metis/parameters/is_break_enable
lock_value 0 /sys/module/metis/parameters/mi_freq_enable
lock_value '0,0,0' /sys/module/metis/parameters/user_min_freq
for file in /sys/kernel/fpsgo/fbt/*freq*
do
  lock_value 0 $file
done

# chmod -R 444 /proc/perfmgr_powerhal
chmod 444 /proc/perfmgr/global_reclaim
# chmod 444 /proc/perfmgr/perf_ioctl
chmod 444 /proc/perfmgr_touch_boost/ioctl_touch_boost

metis=/sys/module/metis/parameters
for file in $metis/*enable*; do
  lock_value 0 $file
done
if [[ -d $metis ]]; then
  chmod -R 444 $metis
fi

lock_value 1 /sys/devices/system/cpu/cpu4/core_ctl/enable
lock_value 3 /sys/devices/system/cpu/cpu4/core_ctl/max_cpus
lock_value 3 /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
lock_value 0 /sys/devices/system/cpu/cpu4/core_ctl/enable

lock_value 1 /sys/devices/system/cpu/cpu7/core_ctl/enable
lock_value 1 /sys/devices/system/cpu/cpu7/core_ctl/max_cpus
lock_value 1 /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
lock_value 0 /sys/devices/system/cpu/cpu7/core_ctl/enable
