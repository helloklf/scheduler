killall scene-scheduler 2>/dev/null


target=`getprop ro.board.platform`

eem_offset() {
  if [[ $(cat /proc/eem/EEM_DET_$1/eem_offset) == 0 ]]; then
    echo $2 > /proc/eem/EEM_DET_$1/eem_offset
  fi
}
eemg_offset() {
  if [[ $(cat /proc/eemg/EEMG_DET_$1/eemg_offset) == 0 ]]; then
    echo $2 > /proc/eemg/EEMG_DET_$1/eemg_offset
  fi
}

voltage_offset(){
  sleep 30
  # B
  eem_offset B -10
  # S
  eem_offset L -10
  # M
  eem_offset BL -10
  eem_offset CCI -10
  eemg_offset GPU 0
  eemg_offset GPU_HI 0
}

core_ctl_init(){
  # Core control parameters for gold
  echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
  echo 60 > /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
  echo 30 > /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
  echo 100 > /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms
  echo 3 > /sys/devices/system/cpu/cpu4/core_ctl/task_thres
  echo 1 1 1 > /sys/devices/system/cpu/cpu4/core_ctl/not_preferred

  # Core control parameters for gold+
  echo 0 > /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
  echo 60 > /sys/devices/system/cpu/cpu7/core_ctl/busy_up_thres
  echo 30 > /sys/devices/system/cpu/cpu7/core_ctl/busy_down_thres
  echo 100 > /sys/devices/system/cpu/cpu7/core_ctl/offline_delay_ms
  echo 1 > /sys/devices/system/cpu/cpu7/core_ctl/task_thres
  echo 1 > /sys/devices/system/cpu/cpu4/core_ctl/not_preferred

  # Controls how many more tasks should be eligible to run on gold CPUs
  # w.r.t number of gold CPUs available to trigger assist (max number of
  # tasks eligible to run on previous cluster minus number of CPUs in
  # the previous cluster).
  #
  # Setting to 1 by default which means there should be at least
  # 4 tasks eligible to run on gold cluster (tasks running on gold cores
  # plus misfit tasks on silver cores) to trigger assitance from gold+.
  echo 1 > /sys/devices/system/cpu/cpu7/core_ctl/nr_prev_assist_thresh

  # Disable Core control on silver
  # echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
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
    c_path="/cache${1}"
    if [[ ! -f "$c_path" ]]; then
      mkdir -p "$c_path"
      rm -r "$c_path"
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

thermal_basic(){
echo 95 70 > /proc/driver/thermal/clatm_gpu_threshold
echo 3 117000 0 mtktscpu-sysrst 85000 0 cpu_adaptive_0 76000 0 cpu_adaptive_1 0 0 no-cooler 0 0 > /proc/driver/thermal/tzcpu
echo 4 120000 0 mtk-cl-kshutdown02 110000 0 no-cooler 100000 0 no-cooler 90000 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000 > /proc/driver/thermal/tzbtspa
echo 2 100000 90000 80000 85000 93000 85000 235000 2000 230000 2000 500 500 13500 > /proc/driver/thermal/clctm
echo 0 3 4 11 3 15 1 15 > /proc/driver/thermal/clatm_cpu_min_opp
echo 1 3 4 5 0 0 0 0 > /proc/driver/thermal/clatm_cpu_min_opp
}


echo 0 > /sys/devices/system/cpu/perf/enable
echo 0 > /sys/devices/system/cpu/perf/fuel_gauge_enable
echo 0 > /sys/devices/system/cpu/perf/gpu_pmu_enable

echo 90 > /sys/module/ged/parameters/g_fb_dvfs_threshold
echo 350000 > /sys/module/ged/parameters/gpu_bottom_freq
echo 886000 > /sys/module/ged/parameters/gpu_cust_upbound_freq
echo 1 > /proc/perfmgr/syslimiter/syslimiter_force_disable
echo 0 > /proc/perfmgr/boost_ctrl/cpu_ctrl/cfp_enable
echo 0 > /sys/kernel/eara_thermal/enable
echo 0 > /sys/kernel/fpsgo/common/fpsgo_enable
# 0: 0ff 1:on 2:free
echo 2 > /sys/kernel/fpsgo/common/force_onoff
echo 250 > /sys/kernel/fpsgo/fbt/thrm_activate_fps
echo 3000000 > /sys/kernel/fpsgo/fbt/limit_cfreq
echo 3000000 > /sys/kernel/fpsgo/fbt/limit_rfreq
echo 2600000 > /sys/kernel/fpsgo/fbt/limit_cfreq_m
echo 2600000 > /sys/kernel/fpsgo/fbt/limit_rfreq_m

echo 0 > /sys/module/fbt_cpu/parameters/boost_affinity
echo 0 > /sys/module/fbt_cpu/parameters/boost_affinity_90
echo 0 > /sys/module/fbt_cpu/parameters/boost_affinity_120


# echo 0 > /sys/kernel/fpsgo/fbt/enable_switch_cap_margin
# echo 0 > /sys/kernel/fpsgo/fbt/enable_switch_sync_flag
# echo 0 > /sys/kernel/fpsgo/fbt/enable_switch_cap_margin
# echo 0 > /sys/kernel/fpsgo/fbt/light_loading_policy
# echo 0 > /sys/kernel/fpsgo/fbt/llf_task_policy
# echo 0 > /sys/kernel/fpsgo/fbt/switch_idleprefer
echo 100 > /sys/kernel/fpsgo/fbt/thrm_temp_th
echo -1 > /sys/kernel/fpsgo/fbt/thrm_limit_cpu
echo -1 > /sys/kernel/fpsgo/fbt/thrm_sub_cpu
# echo 0 > /sys/kernel/fpsgo/fbt/ultra_rescue

echo 0 > /sys/devices/system/cpu/sched/hint_enable
# echo 5 > /sys/devices/system/cpu/sched/hint_load_thresh
# cat /sys/devices/system/cpu/sched/hint_info
echo 0 > /proc/sys/kernel/slide_boost_enabled
echo 0 > /proc/sys/kernel/launcher_boost_enabled

# thermal_basic

serialize_jobs none

for i in 0 4 7; do
  chmod 444 /sys/devices/system/cpu/cpufreq/policy$i/scaling_min_freq
  chmod 444 /sys/devices/system/cpu/cpufreq/policy$i/scaling_max_freq
done
for i in 'hard_userlimit_cpu_freq' 'hard_userlimit_freq_limit_by_others'; do
  echo 0 -1 > /proc/ppm/policy/$i
  echo 1 -1 > /proc/ppm/policy/$i
  echo 2 -1 > /proc/ppm/policy/$i
  chmod 444 /proc/ppm/policy/$i
  # cat /proc/ppm/policy/$i
done
for i in 3 4 5 6; do
  echo $i 0 0 > /proc/gpufreq/gpufreq_limit_table
done
set_stune background 0 0
set_stune foreground 0 0
set_stune nnapi-hal 0 0
set_stune io 0 0
sched_isolation_disable

# echo 100|0 > /proc/perfmgr/boost_ctrl/eas_ctrl/current_ta_uclamp_min
# echo 100|0 > /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_fg_uclamp_min
# echo 1 > /proc/perfmgr/boost_ctrl/eas_ctrl/sched_big_task_rotation
# echo 0 > /sys/module/task_turbo/parameters/feats
echo enable 0 > /proc/perfmgr/tchbst/user/usrtch
hide_value /proc/perfmgr/boost_ctrl/cpu_ctrl/perfserv_iso_cpu 0
hide_value /proc/perfmgr/boost_ctrl/cpu_ctrl/perfserv_freq
hide_value /proc/perfmgr/boost_ctrl/cpu_ctrl/current_freq

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
  change_task_cpuset system_server top-app
  change_task_cpuset kswapd0 foreground
  change_task_cpuset com.omarea.vtools foreground
  change_task_cpuset surfaceflinger foreground
}

echo 8000000 > /proc/sys/kernel/sched_latency_ns
echo 2000000 > /proc/sys/kernel/sched_min_granularity_ns

ctl_off cpu0
ctl_off cpu4
ctl_off cpu7
# disable_oppo_elf
reset_basic_governor
process_opt &
# voltage_offset &
