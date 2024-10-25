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


c_min(){
  cat /sys/devices/system/cpu/cpu$1/cpufreq/cpuinfo_min_freq
}
disable_migt() {
  for dir in /sys/module/migt/parameters /sys/module/metis/parameters /proc/sys/migt /sys/class/misc/migt;do
    if [[ -d $dir ]];then
      for file in `ls $dir`; do
        case "$file" in
          'add_'*)
            chmod 444 $dir/$file
          ;;
          glk_maxfreq)
            lock_value '0 0 0' $dir/$file
          ;;
          min_cluster_freqs|user_min_freq)
            lock_value '0,0,0' $dir/$file
          ;;
          glk_minfreq)
            lock_value "$(c_min 0) $(c_min 4) $(c_min 7)" $dir/$file
          ;;
          migt_ceiling_freq|migt_freq)
            lock_value '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' $dir/$file
          ;;
          glk_fbreak_enable|force_cluster_sched_enable|glk_freq_limit_start|glk_freq_limit_walt|thermal_break_enable|is_break_enable|mi_freq_enable|force_stask_to_big|freq_break_enable)
            lock_value 0 $dir/$file
          ;;
          render_prefer_cluster|vip_prefer_cluster|stask_prefer_cluster|ip_prefer_cluster)
            lock_value -1 $dir/$file
          ;;
          glk_disable|affinity_only|force_reset_runtime|reset_clus_affinity_uidlist|reset_rebind_task)
            lock_value 1 $dir/$file
          ;;
          game_minfreq_limit|game_maxfreq_limit)
            lock_value '0 0 0' $dir/$file
          ;;
        esac
      done
    fi
  done

  glk=/proc/sys/glk
  if [[ -d $glk ]]; then
    hide_value $glk/glk_disable '1'
    hide_value $glk/freq_break_enable '0'
    hide_value $glk/game_minfreq_limit '0 0 0'
    hide_value $glk/game_maxfreq_limit '0 0 0'
  fi

  migt=/proc/sys/migt
  if [[ -d $migt ]]; then
    hide_value $migt/force_stask_tob '0'
    hide_value $migt/enable_pkg_monitor '0'
    hide_value $migt/boost_pid '0'
  fi
}

core_ctl_preset() {
  cpu7_core_ctl_dir=/sys/devices/system/cpu/cpu7/core_ctl
  echo 50 > $cpu7_core_ctl_dir/offline_delay_ms
  echo 1 > $cpu7_core_ctl_dir/min_cpus

  cpu3_core_ctl_dir=/sys/devices/system/cpu/cpu3/core_ctl
  lock_value 0 $cpu3_core_ctl_dir/min_cpus
  lock_value 0 $cpu3_core_ctl_dir/enable
}

hide_value /sys/module/msm_performance/parameters/cpu_max_freq '0:4294967295 1:4294967295 2:4294967295 3:4294967295 4:4294967295 5:4294967295 6:4294967295 7:4294967295'
chattr +i  /sys/module/msm_performance/parameters/cpu_max_freq
hide_value /sys/module/msm_performance/parameters/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
chattr +i  /sys/module/msm_performance/parameters/cpu_min_freq

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
lock_value 1 /sys/module/perfmgr/parameters/load_scaling_y

core_ctl_preset
disable_migt


# OnePlus
if [[ -d  /proc/game_opt ]]; then
  hide_value /proc/game_opt/cpu_max_freq '0:2147483647 1:2147483647 2:2147483647 3:2147483647 4:2147483647 5:2147483647 6:2147483647 7:2147483647'
  hide_value /proc/game_opt/cpu_min_freq '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0'
fi
hide_value /proc/oplus_scheduler/sched_assist/sched_assist_enabled 0
lock_value N /sys/module/sched_assist_common/parameters/boost_kill
for service in orms-hal-1-0 vendor.oplus.ormsHalService-aidl-default # gameopt_hal_service-1-0 midas_hal_service thermal_mnt_hal_servic
do
  stop $service
done
lock_value 0 /sys/devices/platform/soc/soc:oplus-omrg/oplus-omrg0/ruler_enable
for file in silver_core_boost splh_notif lplh_notif dplh_notif l3_boost; do
  lock_value 0 /sys/kernel/msm_performance/parameters/$file
done
echo -R 444 /sys/kernel/msm_performance/parameters


# Meizu
if [[ $(getprop ro.product.model | grep -i Note) == '' ]]; then
  lock_value 0 /proc/mz_scheduler/vip_task/enabled
  # [MB] [swappiness] [MB] [swappiness] [MB] [swappiness]
  echo 3072 125 2048 150 1024 160 > /proc/mz_memory/reclaim_opt/kswapd_reclaim_swappiness
  for tz in /sys/class/thermal/*/mode
  do
    echo disabled > $tz
  done
  stop traced_probes
  lock_value 0 /sys/devices/platform/main_touch.0/screen_mode_node
  echo 1017000 0 0 0 0 0 0 0 > /proc/sys/walt/input_boost/input_boost_freq
  echo 70 70 > /proc/sys/walt/sched_upmigrate
  echo 60 60 > /proc/sys/walt/sched_downmigrate
  # echo 1 > /proc/sys/walt/sched_asymcap_boost
fi

for dir in /sys/devices/system/cpu/cpufreq/policy*;do
  lock_value 0 $dir/walt/adaptive_high_freq
  lock_value 0 $dir/walt/adaptive_low_freq
  echo 1024 > $dir/walt/target_load_thresh
  echo 4 > $dir/walt/target_load_shift
done

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
kgsl min_clock_mhz 220 # 默认124易卡顿，且并不会更省电
kgsl devfreq/min_freq 0
kgsl devfreq/max_freq 999000000


cpus=3-6

set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuset/$2/tasks
    done
  done
}

rmdir /dev/cpuset/background/untrustedapp
rmdir /dev/cpuset/foreground/boost
mkdir /dev/cpuset/top-app/$cpus
echo $cpus > /dev/cpuset/top-app/$cpus/cpus
echo 0 > /dev/cpuset/top-app/$cpus/mems
mkdir /dev/cpuset/top-app/sf
echo $cpus > /dev/cpuset/top-app/sf/cpus
echo 0 > /dev/cpuset/top-app/sf/mems
set_cpuset surfaceflinger "top-app/sf"
set_cpuset touch_report "foreground"
set_cpuset system_server "foreground"
set_cpuset update_engine "top-app/$cpus"
set_cpuset audioserver 'foreground'
set_cpuset android.hardware.audio.service_64 'foreground'
set_cpuset vendor.qti.hardware.display.composer-service "top-app/$cpus"
set_cpuset vendor.qti.hardware.perf-hal-service 'foreground'
set_cpuset kswapd 'foreground'

for file in /sys/devices/system/cpu/bus_dcvs/LLCC/*/min_freq; do
  lock_value 300000 $file
done
for file in /sys/devices/system/cpu/bus_dcvs/DDR/*/min_freq; do
  lock_value 547000 $file
done
for file in /sys/devices/system/cpu/bus_dcvs/L3/*/min_freq; do
  lock_value 307200 $file
done
