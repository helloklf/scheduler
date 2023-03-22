# /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies
# 840000000 778000000 738000000 676000000 608000000 540000000 491000000 443000000 379000000 315000000

manufacturer=$(getprop ro.product.manufacturer)

core_online=(1 1 1 1 1 1 1 1)
set_core_online() {
  for index in 0 1 2 3 4 5 6 7; do
    core_online[$index]=`cat /sys/devices/system/cpu/cpu$index/online`
    echo 1 > /sys/devices/system/cpu/cpu$index/online
  done
}
restore_core_online() {
  for i in "${!core_online[@]}"; do
     echo ${core_online[i]} > /sys/devices/system/cpu/cpu$i/online
  done
}

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

stune_top_app() {
  echo $1 > /dev/stune/top-app/schedtune.prefer_idle
  echo $2 > /dev/stune/top-app/schedtune.boost
}

lock_freq() {
  policy ut_fix_freq_idx "$1 $2"
}

max_freq() {
  policy hard_userlimit_max_cpu_freq "0 $1"
  policy hard_userlimit_max_cpu_freq "1 $2"
  # policy userlimit_max_cpu_freq "0 $1"
  # policy userlimit_max_cpu_freq "1 $2"
}

min_freq() {
  policy hard_userlimit_min_cpu_freq "0 $1"
  policy hard_userlimit_min_cpu_freq "1 $2"
  # policy userlimit_min_cpu_freq "0 $1"
  # policy userlimit_min_cpu_freq "1 $2"
}

ged() {
  echo $2 > /sys/module/ged/parameters/$1
}

cpuset() {
  echo $1 > /dev/cpuset/background/cpus
  echo $2 > /dev/cpuset/system-background/cpus
  echo $3 > /dev/cpuset/foreground/cpus
  echo $4 > /dev/cpuset/top-app/cpus
  echo $5 > /dev/cpuset/restricted/cpus
}

# gpu_freq_max [oppIndex]
gpu_freq_max() {
  echo $1 > /sys/kernel/ged/hal/custom_upbound_gpu_freq
}
# gpu_freq_max_freq [freqKHZ]
gpu_freq_max_freq() {
  gpu_opp=$(grep "freq = $1," /proc/gpufreq/gpufreq_opp_dump)
  lock_value $((${gpu_opp:1:2}+0)) /sys/kernel/ged/hal/custom_upbound_gpu_freq
  lock_value 32 /sys/kernel/ged/hal/custom_boost_gpu_freq
}

gpu_dvfs_margin() {
  echo $1 > /sys/kernel/ged/hal/timer_base_dvfs_margin
  echo $1 > /sys/kernel/ged/hal/dvfs_margin_value
}

# gpu_freq_fixed [freqKHZ]
gpu_freq_fixed() {
  echo $1 > /proc/gpufreq/gpufreq_opp_freq
  local dvfs=/proc/mali/dvfs_enable
  if [[ -f $dvfs ]]; then
    if [[ "$1" == "0" ]]; then
      echo 1 > $dvfs
      # set_value 1 /sys/module/ged/parameters/gpu_dvfs_enable
    else
      echo 0 > $dvfs
      # set_value 0 /sys/module/ged/parameters/gpu_dvfs_enable
    fi
  fi
  echo $1 > /proc/gpufreq/gpufreq_opp_freq
}

reset_basic_governor() {
  stop_scene_scheduler
  set_core_online

  # CPU
  governor0=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor`
  governor6=`cat /sys/devices/system/cpu/cpufreq/policy6/scaling_governor`

  if [[ ! "$governor0" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
  fi
  if [[ ! "$governor6" = "schedutil" ]]; then
    echo 'schedutil' > /sys/devices/system/cpu/cpufreq/policy6/scaling_governor
  fi

  # GPU
  gpu_freq_fixed 0
  serialize_jobs none
  gpu_freq_max 0
  # gpu_dvfs_margin 10

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

set_cpu_freq() {
  # echo "0:$2 1:$2 2:$2 3:$2 4:$4 5:$4 6:$4 7:$4" > /sys/module/msm_performance/parameters/cpu_max_freq
  # echo $1 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
  # echo $2 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
  # echo $3 > /sys/devices/system/cpu/cpufreq/policy6/scaling_min_freq
  # echo $4 > /sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq

  min_freq $1 $2
  max_freq $3 $4
}

sched_limit() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
  echo $2 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
  echo $3 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us
  echo $4 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us
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
  echo $2 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/hispeed_freq
}

set_hispeed_load() {
  echo $1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_load
  echo $2 > /sys/devices/system/cpu/cpufreq/policy6/schedutil/hispeed_load
}

cpuctl () {
  echo $2 > /dev/cpuctl/$1/cpu.uclamp.sched_boost_no_override
  echo $3 > /dev/cpuctl/$1/cpu.uclamp.latency_sensitive
  echo $4 > /dev/cpuctl/$1/cpu.uclamp.min
  echo $5 > /dev/cpuctl/$1/cpu.uclamp.max
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

# set_task_affinity $pid $use_cores[cpu7~cpu0]
set_task_affinity() {
  pid=$1
  if [[ "$pid" != "" ]]; then
    mask=`echo "obase=16;$((num=2#$2))" | bc`
    for tid in $(ls "/proc/$pid/task/"); do
      taskset -p "$mask" "$tid" 1>/dev/null
    done
    taskset -p "$mask" "$pid" 1>/dev/null
  fi
}


move_to_cpuset() {
  local pid="$1"
  local cpuset="/dev/cpuset/$2/cgroup.procs"
  if [[ "$pid" != "" ]] && [[ -e "$cpuset" ]]; then
    echo $pid > "$cpuset"
  fi
}
