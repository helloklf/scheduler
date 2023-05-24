killall scene-scheduler 2>/dev/null

# [none] intra-slot inter-slot full full-reset
serialize_jobs(){
  echo $1 > /sys/devices/platform/13000000.mali/scheduling/serialize_jobs
}

# 0:Nrmal 1:Perf
cpu_cci_mode() {
  echo $1 > /proc/cpufreq/cpufreq_cci_mode
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
sched_isolation_disable() {
  for i in 0 1 2 3 4 5 6 7; do
    echo $i > /sys/devices/system/cpu/sched/set_sched_deisolation
  done
  chmod 000 /sys/devices/system/cpu/sched/set_sched_isolation
}
hmp() {
  lock_value 0 /sys/devices/system/cpu/eas/enable
}
eas() {
  lock_value 1 /sys/devices/system/cpu/eas/enable
}
hybrid() {
  lock_value 2 /sys/devices/system/cpu/eas/enable
}

ppm() {
  echo $2 > "/proc/ppm/$1"
}

policy() {
  lock_value "$2" "/proc/ppm/policy/$1"
}

ged() {
  echo $2 > /sys/module/ged/parameters/$1
}

# gpu_freq_max [oppIndex]
gpu_freq_max() {
  echo $1 > /sys/kernel/ged/hal/custom_upbound_gpu_freq
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

ctl_on() {
  echo 1 > /sys/devices/system/cpu/$1/core_ctl/enable
  if [[ "$2" != "" ]]; then
    echo $2 > /sys/devices/system/cpu/$1/core_ctl/min_cpus
  else
    echo 0 > /sys/devices/system/cpu/$1/core_ctl/min_cpus
  fi
}

ctl_off() {
  echo 0 > /sys/devices/system/cpu/$1/core_ctl/enable
}

set_ctl() {
  echo $2 > /sys/devices/system/cpu/$1/core_ctl/busy_up_thres
  echo $3 > /sys/devices/system/cpu/$1/core_ctl/busy_down_thres
  echo $4 > /sys/devices/system/cpu/$1/core_ctl/offline_delay_ms
}

set_hispeed_freq() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_freq
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/hispeed_freq
}

set_hispeed_load() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_load
  echo $2 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/hispeed_load
}

# cpuset() {
#   echo $1 > /dev/cpuset/background/cpus
#   echo $2 > /dev/cpuset/system-background/cpus
#   echo $3 > /dev/cpuset/foreground/cpus
#   echo $4 > /dev/cpuset/top-app/cpus
# }

lock_value () {
  chmod 644 $2
  echo $1 > $2
  chmod 444 $2
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

# 0 / max / 4266000 3733000 3733000 3068000 3068000 2366000 2366000 2366000 1866000 1866000 1866000 1866000 1534000 1534000 1534000 1534000 1200000 1200000 1200000 1200000 800000 800000 800000 800000
dram_freq(){
  if [[ "$1" == "max" ]]; then
    echo 1 > /sys/devices/platform/boot_dramboost/dramboost/dramboost
    ddr_opp=$(cat /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_opp_table | head -1)
    echo ${ddr_opp:4:2} > /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
  elif [[ "$1" == "0" ]]; then
    echo 0 > /sys/devices/platform/boot_dramboost/dramboost/dramboost
    echo -1 > /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
  else
    ddr_opp=$(grep ${1}000 /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_opp_table | head -1)
    echo ${ddr_opp:4:2} > /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
  fi
}

disable_oppo_elf() {
  pm disable com.coloros.oppoguardelf/com.coloros.powermanager.fuelgaue.GuardElfAIDLService
  pm disable com.coloros.oppoguardelf/com.coloros.oppoguardelf.OppoGuardElfService
}

sched_boost_get() {
  cat /sys/devices/system/cpu/sched/sched_boost | cut -f2 -d '='
}

sched_boost_set() {
  if [[ "$state" == "no boost" ]]; then
    echo 0 > /sys/devices/system/cpu/sched/sched_boost
  elif [[ "$state" == "all boost" ]]; then
    echo 1 > /sys/devices/system/cpu/sched/sched_boost
  elif [[ "$state" == "foreground boost" ]]; then
    echo 2 > /sys/devices/system/cpu/sched/sched_boost
  fi
}

# 0:Normal 1:Extreme(dangerous)
sspm_thermal_throttle(){
  echo $1 > /proc/driver/thermal/sspm_thermal_throttle
}

move_to_cpuset() {
  local pid="$1"
  local cpuset="/dev/cpuset/$2/cgroup.procs"
  if [[ "$pid" != "" ]] && [[ -e "$cpuset" ]]; then
    echo $pid > "$cpuset"
  fi
}


echo 90 > /sys/module/ged/parameters/g_fb_dvfs_threshold
echo 358000 > /sys/module/ged/parameters/gpu_bottom_freq
echo 1000000 > /sys/module/ged/parameters/gpu_cust_upbound_freq
echo 1 > /proc/perfmgr/syslimiter/syslimiter_force_disable
echo 0 > /proc/perfmgr/boost_ctrl/cpu_ctrl/cfp_enable
echo 100 > /sys/kernel/fpsgo/fbt/thrm_temp_th
echo -1 > /sys/kernel/fpsgo/fbt/thrm_limit_cpu
echo -1 > /sys/kernel/fpsgo/fbt/thrm_sub_cpu
echo 0 > /sys/kernel/eara_thermal/enable
echo 0 > /sys/kernel/fpsgo/common/fpsgo_enable
# 0: 0ff 1:on 2:free
echo 2 > /sys/kernel/fpsgo/common/force_onoff
echo 250 > /sys/kernel/fpsgo/fbt/thrm_activate_fps
echo 2600000 > /sys/kernel/fpsgo/fbt/limit_cfreq
echo 2600000 > /sys/kernel/fpsgo/fbt/limit_rfreq
echo 2600000 > /sys/kernel/fpsgo/fbt/limit_cfreq_m
echo 2600000 > /sys/kernel/fpsgo/fbt/limit_rfreq_m

echo 0 > /sys/devices/system/cpu/sched/hint_enable
# echo 5 > /sys/devices/system/cpu/sched/hint_load_thresh
# cat /sys/devices/system/cpu/sched/hint_info
echo 0 > /proc/sys/kernel/slide_boost_enabled
echo 0 > /proc/sys/kernel/launcher_boost_enabled

serialize_jobs none

for i in 0 4; do
  chmod 444 /sys/devices/system/cpu/cpufreq/policy$i/scaling_min_freq
  chmod 444 /sys/devices/system/cpu/cpufreq/policy$i/scaling_max_freq
done
for i in 'hard_userlimit_cpu_freq' 'hard_userlimit_freq_limit_by_others'; do
  echo 0 -1 > /proc/ppm/policy/$i
  echo 1 -1 > /proc/ppm/policy/$i
  chmod 444 /proc/ppm/policy/$i
  # cat /proc/ppm/policy/$i
done
for i in 3 4 5 6; do
  echo $i 0 0 > /proc/gpufreq/gpufreq_limit_table
done
sched_isolation_disable

# echo 100|0 > /proc/perfmgr/boost_ctrl/eas_ctrl/current_ta_uclamp_min
# echo 100|0 > /proc/perfmgr/boost_ctrl/eas_ctrl/perfserv_fg_uclamp_min
# echo 1 > /proc/perfmgr/boost_ctrl/eas_ctrl/sched_big_task_rotation
# echo 0 > /sys/module/task_turbo/parameters/feats
echo enable 0 > /proc/perfmgr/tchbst/user/usrtch

set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    echo $pid > /dev/stune/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuset/$2/tasks
    done
  done
}

process_opt() {
  set_cpuset surfaceflinger top-app
  set_cpuset system_server top-app

  echo 1 > /dev/stune/rt/schedtune.sched_boost_no_override
  # echo 1 > /dev/stune/rt/schedtune.prefer_idle
  echo 0 > /dev/stune/rt/schedtune.boost
}

set_value 8000000 /proc/sys/kernel/sched_latency_ns
set_value 2000000 /proc/sys/kernel/sched_min_granularity_ns

ctl_off cpu0
ctl_off cpu4
ctl_off cpu7
disable_oppo_elf
process_opt &


# GPU
gpu_freq_fixed 0
serialize_jobs none
gpu_freq_max 0

# DRAM
dram_freq 0

# PPM
# policy_status
# [0] PPM_POLICY_PTPOD: enabled
# [1] PPM_POLICY_UT: enabled
# [2] PPM_POLICY_FORCE_LIMIT: enabled
# [3] PPM_POLICY_PWR_THRO: enabled
# [4] PPM_POLICY_THERMAL: enabled
# [6] PPM_POLICY_HARD_USER_LIMIT: enabled
# [7] PPM_POLICY_USER_LIMIT: enabled
# [8] PPM_POLICY_LCM_OFF: disabled
# [9] PPM_POLICY_SYS_BOOST: disabled

# Usage: echo <idx> <1/0> > /proc/ppm/policy_status

ppm enabled 1
ppm policy_status "0 0"
ppm policy_status "1 0"
ppm policy_status "2 0"
ppm policy_status "3 0"
ppm policy_status "4 0"
# ppm policy_status "5 0"
ppm policy_status "6 1"
ppm policy_status "7 0"
ppm policy_status "9 0"

sspm_thermal_throttle 0
