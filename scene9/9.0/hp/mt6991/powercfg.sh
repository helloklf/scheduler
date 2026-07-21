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
lock_value 0 $t_message/market_download_limit
lock_value 0 $t_message/modem_limit
lock_value 0 0 0 0 /sys/class/thermal/thermal_message/boost

lock_value 0 /sys/kernel/fpsgo/fbt/enable_ceiling
lock_value 0 /sys/module/mtk_fpsgo/parameters/perfmgr_enable

if [[ $(grep /proc/perfmgr/perf_ioctl /proc/mounts) == '' ]]; then
mount --bind /proc/perfmgr_touch_boost/ioctl_touch_boost /proc/perfmgr/perf_ioctl
fi
chmod 444 /proc/perfmgr/global_reclaim

umount /proc/powerhal_cpu_ctrl/perfserv_freq
little_min=339000
middle_min=622000
big_min=798000
little_max=2700000
middle_max=3300000
big_max=3600000
echo "0 $little_min $little_max" > /proc/powerhal_cpu_ctrl/perfserv_freq
echo "4 $middle_min $middle_max" > /proc/powerhal_cpu_ctrl/perfserv_freq
echo "7 $big_min $big_max" > /proc/powerhal_cpu_ctrl/perfserv_freq
mount --bind /proc/powerhal_cpu_ctrl/adpf_enable /proc/powerhal_cpu_ctrl/perfserv_freq
lock_value "$middle_max $big_max" /sys/module/mtk_fpsgo/parameters/cpus_limit
lock_value "0:$little_max 1:$little_max 2:$little_max 3:$little_max 4:$middle_max 5:$middle_max 6:$middle_max 7:$big_max" /sys/kernel/qos_arbiter/parameters/cpu_max_freq
lock_value "0:$little_min 1:$little_min 2:$little_min 3:$little_min 4:$middle_min 5:$middle_min 6:$middle_min 7:$big_min" /sys/kernel/qos_arbiter/parameters/cpu_min_freq
# lock_value 1 /sys/module/mtk_fpsgo/parameters/better_perf
stop touch_boost

chmod 444 /sys/kernel/fpsgo/fbt/fbt_attr_by_pid
chmod 444 /sys/kernel/fpsgo/fbt/fbt_attr_by_tid
lock_value 0 /sys/module/mtk_fpsgo/parameters/boost_affinity

set_value 1 /sys/module/metis/parameters/reset_clus_affinity_uidlist
set_value 1 /sys/module/metis/parameters/reset_rebind_task
lock_value 0 /sys/module/metis/parameters/thermal_break_enable
lock_value 0 /sys/module/metis/parameters/is_break_enable
lock_value 0 /sys/module/metis/parameters/mi_freq_enable

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

# vivo
if [[ -e /sys/module/vivo_board_info ]] || [[ -e /sys/module/vivo_display ]]; then
  stop vivo-vperf-hal-1-0
  stop vendor.vivoperfservice
  echo 0 > /proc/powerhal_cpu_ctrl/adpf_enable
  stop thermal_core
  stop thermald
fi

c_min(){
  echo $(cat /sys/devices/system/cpu/cpufreq/policy*/cpuinfo_min_freq)
}
# Xiaomi
if [[ -d /proc/mi_display ]]; then
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
            lock_value "$(c_min)" $dir/$file
          ;;
          migt_ceiling_freq|migt_freq)
            lock_value '0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0' $dir/$file
          ;;
          glk_fbreak_enable|force_cluster_sched_enable|glk_freq_limit_start|glk_freq_limit_walt|thermal_break_enable|is_break_enable|mi_freq_enable|force_stask_to_big|freq_break_enable|enable_pkg_monitor|flt_enable_other|flt_in_frame_enable|cluaff_control|override_schedboost_in_coldstart|metis_schlat_enable|limit_bgtask_sched|choose_cpu_exclusive_enable|frame_boost_enable)
            lock_value 0 $dir/$file
          ;;
          flt_deq_ajust_enable|flt_in_frame_enable|flt_preboost_enable|flt_wakeup_enable)
            lock_value 0 $dir/$file
          ;;
          # 导致Xiaomi 15上日常会非常激进的使用大核
          mi_fboost_enable)
            set_value 1 $dir/$file
          ;;
          render_prefer_cluster|vip_prefer_cluster|stask_prefer_cluster|ip_prefer_cluster)
            lock_value -1 $dir/$file
          ;;
          glk_disable|affinity_only|force_reset_runtime|reset_clus_affinity_uidlist|reset_rebind_task|clean_user_group)
            lock_value 1 $dir/$file
          ;;
          game_minfreq_limit|game_maxfreq_limit)
            lock_value '0 0 0' $dir/$file
          ;;
          flt_preboost_cluster_enable)
            lock_value '0,0' $dir/$file
          ;;
          flt_cal_freq_enable|flt_in_frame_enable_cluster)
            lock_value '0,0,0,0' $dir/$file
          ;;
        esac
      done
    fi
  done
  chmod 444 /sys/module/metis/parameters
  chmod 444 /sys/module/migt/parameters
  am force-stop com.xiaomi.joyose
fi

# Low Battery Throttling
echo "low_battery_throttling"
echo "Utest 0" > /sys/devices/platform/low-battery-throttling/low_battery_protect_ut
echo "stop 1"  > /sys/devices/platform/low-battery-throttling/low_battery_protect_stop
echo "bp_thl (battery percent)"
echo "Utest 0" > /sys/devices/platform/bp-thl/bp_thl_ut
echo "stop 1"  > /sys/devices/platform/bp-thl/bp_thl_stop

# FPSGO
# lock_value 0 /sys/kernel/fpsgo/common/force_onoff
#   enable_ceiling related
echo 0 > /sys/kernel/fpsgo/fbt/limit_cfreq
echo 0 > /sys/kernel/fpsgo/fbt/limit_cfreq_m
echo 0 > /sys/kernel/fpsgo/fbt/limit_rfreq
echo 0 > /sys/kernel/fpsgo/fbt/limit_rfreq_m
lock_value 0 /sys/kernel/fpsgo/fbt/enable_ceiling
# dynamicc throttling / tas?
lock_value 0 /sys/kernel/fpsgo/fbt/powerRL_enable
# lock_value "0 0" /sys/kernel/fpsgo/fstb/fstb_debug
chmod 444 /sys/kernel/fpsgo/common/render_attr_params
chmod 444 /sys/kernel/fpsgo/common/render_attr_params_tid
chmod 444 /sys/kernel/fpsgo/common/render_info
chmod 444 /sys/kernel/fpsgo/common/render_info_params

lock_value 1 /proc/game_opt/disable_cpufreq_limit
lock_value 0 /sys/module/perfmgr/parameters/perfmgr_enable
lock_value 0 /sys/module/cpufreq_bouncing/parameters/enable
lock_value 0 /sys/devices/platform/soc/soc:oplus-omrg/oplus-omrg0/ruler_enable
lock_value 0 /proc/task_overload/skip_goplus_enabled
lock_value 0 /sys/module/mtk_fpsgo/parameters/cfp_onoff
lock_value 0 /proc/touch_boost/enable
stop vendor.oplus.ormsHalService-aidl-default
resetprop sys.oplus.hmbird.manager.enable 0
echo -1 > /proc/oplus_hmbird/manager_pid

# set_slc_force_ratio [cpu%] [gpu%]
set_slc_force_ratio(){
  chmod 777 /proc/oplus_slc/force_ratio
  echo 1,$1 > /proc/oplus_slc/force_ratio # cpu
  echo 2,$2 > /proc/oplus_slc/force_ratio # gpu
  chmod 444 /proc/oplus_slc/force_ratio
  if [[ "$1" == "100" ]]; then
    echo "1" > /proc/oplus_slc/priority
    echo "slbc_cg_priority 1" > /proc/slbc/dbg_slbc
  elif [[ "$2" == "100" ]]; then
    echo "2" > /proc/oplus_slc/priority
    echo "slbc_cg_priority 2" > /proc/slbc/dbg_slbc
  fi
}
# echo "slbc_force 0x80640001" > /proc/slbc/dbg_slbc
set_slc_force_ratio 0 100

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
  services="magt ged fpsgo oiface midasd frs touch_boost oplus_sched oplus_sched_rename vendor.mtkpower_applist-default vendor.urcc-hal-aidl"
  for service in $services; do
    stop $service
    killall $service 2>/dev/null
  done
}
# stop_services

gpu_ulimit(){
  # gpt index temp opp
  echo "enable" > /sys/kernel/thermal/gpt
  echo "gpt 1 88000 7" > /sys/kernel/thermal/gpt
  echo "gpt 2 92000 12" > /sys/kernel/thermal/gpt
  # echo "disable" > /sys/kernel/thermal/gpt
}
gpu_ulimit


if [[ $(getprop vtools.thermal.disguise) != '1' ]]; then
  lock_value "MIN_TTJ 95000 95000 95000" /sys/kernel/thermal/min_ttj
  lock_value "MAX_TTJ 95000 95000 95000" /sys/kernel/thermal/max_ttj
  lock_value "TTJ 95000 95000 95000" /sys/kernel/thermal/ttj
fi
