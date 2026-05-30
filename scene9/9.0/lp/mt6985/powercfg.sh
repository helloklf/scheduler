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

lock_value () {
  if [[ -f $2 ]];then
    chmod 644 $2
    echo $1 > $2
    chmod 444 $2
  fi
}

dev_mount=/dev/$(cat /dev/urandom | tr -dc 'a-z_' | head -c 8; echo)
# hide_value /sys/module/task_turbo/parameters/feats [write_value]
hide_value() {
  if [[ -e "$1" ]]; then
    umount "$1" 2>/dev/null
    c_path="$dev_mount${1}"
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
hide_value $t_message/market_download_limit 0
hide_value $t_message/modem_limit 0
lock_value 0 0 0 0 /sys/class/thermal/thermal_message/boost

lock_value 0 /sys/kernel/fpsgo/fbt/enable_ceiling
if [[ $(cat /proc/version | grep Pandora) == '' ]]; then
  hide_value /sys/kernel/fpsgo/fbt/limit_cfreq 0
  hide_value /sys/kernel/fpsgo/fbt/limit_rfreq 0
  hide_value /sys/kernel/fpsgo/fbt/limit_cfreq_m 0
  hide_value /sys/kernel/fpsgo/fbt/limit_rfreq_m 0
fi
lock_value 1 /sys/module/sspm_v3/holders/ged/parameters/is_GED_KPI_enabled
lock_value '220000 2000000 400000 3000000 1200000 3350000' /proc/powerhal_cpu_ctrl/perfserv_freq
lock_value '3000000 3350000' /sys/module/mtk_fpsgo/parameters/cpus_limit
lock_value 0 /sys/module/cpufreq_bouncing/parameters/enable
lock_value 0 /sys/module/mtk_fpsgo/parameters/cfp_onoff
chmod 444 /proc/cpumgr/core_ioctl

metis=/sys/module/metis/parameters
echo 1 > $metis/reset_clus_affinity_uidlist
for file in $metis/*enable*; do
  lock_value 0 $file
done
if [[ -d $metis ]]; then
  chmod -R 444 $metis
fi

chmod 444 /sys/kernel/fpsgo/fbt/fbt_attr_by_pid
chmod 444 /sys/kernel/fpsgo/fbt/fbt_attr_by_tid
lock_value 0 /sys/module/mtk_fpsgo/parameters/boost_affinity

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
