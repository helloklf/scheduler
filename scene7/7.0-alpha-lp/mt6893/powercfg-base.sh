killall scene-scheduler 2>/dev/null


# /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies
# 840000000 778000000 738000000 676000000 608000000 540000000 491000000 443000000 379000000 315000000


# [none] intra-slot inter-slot full full-reset
serialize_jobs(){
  echo $1 > /sys/devices/platform/13000000.mali/scheduling/serialize_jobs
}

# 0 Default(Normal) mode
# 1 Low Power mode
# 2 Just Make mode
# 3 Performance(Sports) mode
cpu_power_mode() {
  echo $1 > /proc/cpufreq/cpufreq_power_mode
}

# sched_deisolation [cpuIndex]
sched_deisolation() {
  echo $1 > /sys/devices/system/cpu/sched/set_sched_deisolation
}
# sched_isolation [cpuIndex]
sched_isolation() {
  echo $1 > /sys/devices/system/cpu/sched/set_sched_isolation
}
disable_core_ctl() {
  c0=/sys/devices/system/cpu/cpu0/core_ctl
  c1=/sys/devices/system/cpu/cpu4/core_ctl
  c2=/sys/devices/system/cpu/cpu7/core_ctl

  lock_value 4 $c0/max_cpus
  lock_value 4 $c0/min_cpus
  lock_value 0 $c0/enable

  lock_value 3 $c1/max_cpus
  lock_value 3 $c1/min_cpus
  lock_value 0 $c1/enable

  lock_value 1 $c2/max_cpus
  lock_value 1 $c2/min_cpus
  lock_value 0 $c2/enable

  lock_value -1 /sys/kernel/fpsgo/fbt/thrm_limit_cpu
  lock_value -1 /sys/kernel/fpsgo/fbt/thrm_sub_cpu
}
sched_isolation_disable() {
  for i in 0 1 2 3 4 5 6 7; do
    echo $i > /sys/devices/system/cpu/sched/set_sched_deisolation
  done
  chmod 000 /sys/devices/system/cpu/sched/set_sched_isolation
  disable_core_ctl
}

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

ctl_off() {
  echo 0 > /sys/devices/system/cpu/$1/core_ctl/enable
}

set_ctl() {
  echo $2 > /sys/devices/system/cpu/$1/core_ctl/busy_up_thres
  echo $3 > /sys/devices/system/cpu/$1/core_ctl/busy_down_thres
  echo $4 > /sys/devices/system/cpu/$1/core_ctl/offline_delay_ms
}

set_stune() {
  echo $2 > /dev/stune/$1/schedtune.prefer_idle
  echo $3 > /dev/stune/$1/schedtune.boost
}
stune_top_app() {
  set_stune top-app $1 $2
}

disable_oppo_elf() {
  pm disable com.coloros.oppoguardelf/com.coloros.powermanager.fuelgaue.GuardElfAIDLService
  pm disable com.coloros.oppoguardelf/com.coloros.oppoguardelf.OppoGuardElfService
}

# GPU
serialize_jobs none

# DRAM
dram_freq 0

# PPM
echo 1 > /proc/ppm/enabled
cat /proc/ppm/policy_status | grep -e '\[.*\]' | while read row
do
  case "$row" in
    *"PPM_POLICY_HARD_USER_LIMIT"*)
      v=1
    ;;
    *)
      v=0
    ;;
  esac
  echo ${row:1:1} $v > /proc/ppm/policy_status
done

lock_value 2 /sys/kernel/fpsgo/common/force_onoff
lock_value 0 /sys/kernel/fpsgo/fbt/switch_idleprefer


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
lock_value 0 /sys/kernel/fpsgo/common/fpsgo_enable
# 0: 0ff 1:on 2:free
echo 2 > /sys/kernel/fpsgo/common/force_onoff
echo 250 > /sys/kernel/fpsgo/fbt/thrm_activate_fps
lock_value 0 /sys/kernel/fpsgo/fbt/limit_cfreq
lock_value 0 /sys/kernel/fpsgo/fbt/limit_rfreq
lock_value 0 /sys/kernel/fpsgo/fbt/limit_cfreq_m
lock_value 0 /sys/kernel/fpsgo/fbt/limit_rfreq_m

echo 0 > /sys/module/fbt_cpu/parameters/boost_affinity
echo 0 > /sys/module/fbt_cpu/parameters/boost_affinity_90
echo 0 > /sys/module/fbt_cpu/parameters/boost_affinity_120

# echo 0 > /sys/kernel/fpsgo/fbt/enable_switch_cap_margin
# echo 0 > /sys/kernel/fpsgo/fbt/enable_switch_sync_flag
# echo 0 > /sys/kernel/fpsgo/fbt/enable_switch_cap_margin
# echo 0 > /sys/kernel/fpsgo/fbt/light_loading_policy
# echo 0 > /sys/kernel/fpsgo/fbt/llf_task_policy
# lock_value 0 /sys/kernel/fpsgo/fbt/switch_idleprefer
lock_value 90 /sys/kernel/fpsgo/fbt/thrm_temp_th
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

for i in 3 4 5 6; do
  echo $i 0 0 > /proc/gpufreq/gpufreq_limit_table
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
process_opt &
# voltage_offset &

# OnePlus/Realme
for service in orms-hal-1-0 # gameopt_hal_service-1-0 midas_hal_service thermal_mnt_hal_servic
do
  stop $service
done
