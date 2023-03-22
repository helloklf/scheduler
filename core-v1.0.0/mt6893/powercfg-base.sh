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

thermal_gt(){
echo 95 70 > /proc/driver/thermal/clatm_gpu_threshold
echo '' > /proc/mtkcooler/mtktscpu-sysrst
echo 'EXIT 6000' > /proc/mtkcooler/cpu_adaptive_0

echo 'mtktsAP 74000 EXIT 5000' > /proc/mtkcooler/cpu_adaptive_1
echo '' > /proc/mtkcooler/mtktspmic-sysrst
echo '' > /proc/mtkcooler/mtk-cl-kshutdown00
echo '' > /proc/mtkcooler/mtktscharger-sysrst
echo '' > /proc/mtkcooler/mtktswmt-sysrst
echo '' > /proc/mtkcooler/mtktsAP-sysrst
echo '' > /proc/mtkcooler/mtk-cl-kshutdown03

echo 'EXIT 6000' > /proc/mtkcooler/mtk-cl-cam00
echo 'EXIT 999' > /proc/mtkcooler/abcct_lcmoff
echo 'EXIT 999' > /proc/mtkcooler/abcct
echo '' > /proc/mtkcooler/mtk-cl-kshutdown01
echo '' > /proc/mtkcooler/mtk-cl-kshutdown02

echo 'PUP_R 100000 PUP_VOLT 1800 OVER_CRITICAL_L 4397119 NTC_TABLE 7 0' > /proc/driver/thermal/tzbts_param
echo 'PUP_R 100000 PUP_VOLT 1800 OVER_CRITICAL_L 4397119 NTC_TABLE 7 1' > /proc/driver/thermal/tzbtspa_param
echo 'PUP_R 100000 PUP_VOLT 1800 OVER_CRITICAL_L 4397119 NTC_TABLE 7 2' > /proc/driver/thermal/tzbtsnrpa_param

echo '0 2000 10 15 1 570 0 200 0' > /proc/driver/thermal/clatm_setting
echo '1 1000 10 15 1 280 0 170 0' > /proc/driver/thermal/clatm_setting
echo '0 550 350 150' > /proc/driver/thermal/clbcct
echo '0 70000 70000 8 12 16 8 12 16' > /proc/driver/thermal/clmutt_setting
echo '2 100000 90000 80000 85000 93000 85000 235000 2000 230000 2000 500 500 13500' > /proc/driver/thermal/clctm
echo '51000 1000 200000 5 2000 0 0 3000 0 1' > /proc/driver/thermal/clabcct
echo '1 53000 1000 200000 5 2000 600' > /proc/driver/thermal/clabcct_lcmoff
echo '0 3 4 11 3 15 1 15' > /proc/driver/thermal/clatm_cpu_min_opp
echo '1 3 4 5 0 0 0 0' > /proc/driver/thermal/clatm_cpu_min_opp
echo '1 0 4 0 85000 5000 1000 50 200 5000 200 200 10000 10000' > /proc/driver/thermal/wifi_in_soc
echo 0 > /proc/driver/thermal/sspm_thermal_throttle

echo '3 117000 0 mtktscpu-sysrst 77000 0 cpu_adaptive_0 70000 0 cpu_adaptive_1 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 200' > /proc/driver/thermal/tzcpu
echo '1 136000 0 mtktspmic-sysrst 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000' > /proc/driver/thermal/tzpmic
echo '1 120000 0 mtk-cl-kshutdown00 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 2000' > /proc/driver/thermal/tzpa
echo '1 120000 0 mtktscharger-sysrst 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 2000' > /proc/driver/thermal/tzcharger
echo '1 120000 0 mtktswmt-sysrst 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000' > /proc/driver/thermal/tzwmt
echo '5 100000 0 mtktsAP-sysrst 90000 0 mtk-cl-kshutdown03 58000 0 mtk-cl-cam00 52000 0 abcct_lcmoff 50000 0 abcct 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000' > /proc/driver/thermal/tzbts
echo '4 120000 0 mtk-cl-kshutdown01 110000 0 no-cooler 100000 0 no-cooler 68000 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000' > /proc/driver/thermal/tzbtsnrpa
echo '4 120000 0 mtk-cl-kshutdown02 110000 0 no-cooler 100000 0 no-cooler 90000 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000' > /proc/driver/thermal/tzbtspa

echo 'ma_len 1' > /proc/mtktz/mtktscpu
echo 'ma_len 4' > /proc/mtktz/mtktspmic
# echo 'ma_len 4' > /proc/mtktz/mtktsbattery
echo 'ma_len 1' > /proc/mtktz/mtktspa
echo 'ma_len 1' > /proc/mtktz/mtktscharger
echo 'ma_len 1' > /proc/mtktz/mtktswmt
echo 'ma_len 1' > /proc/mtktz/mtktsAP
echo 'ma_len 1' > /proc/mtktz/mtktsbtsnrpa
echo 'ma_len 1' > /proc/mtktz/mtktsbtsmdpa
}

thermal_ht(){
echo 95 70 > /proc/driver/thermal/clatm_gpu_threshold
echo '' > /proc/mtkcooler/mtktscpu-sysrst
echo '' > /proc/mtkcooler/mtktspmic-sysrst
echo '' > /proc/mtkcooler/mtktsbattery-sysrst
echo '' > /proc/mtkcooler/mtk-cl-kshutdown00
echo '' > /proc/mtkcooler/mtktscharger-sysrst
echo '' > /proc/mtkcooler/mtktswmt-sysrst
echo '' > /proc/mtkcooler/mtktsAP-sysrst
echo '' > /proc/mtkcooler/mtk-cl-kshutdown01
echo '' > /proc/mtkcooler/mtk-cl-kshutdown02

echo 'PUP_R 100000 PUP_VOLT 1800 OVER_CRITICAL_L 4397119 NTC_TABLE 7 0' > /proc/driver/thermal/tzbts_param
echo 'PUP_R 100000 PUP_VOLT 1800 OVER_CRITICAL_L 4397119 NTC_TABLE 7 1' > /proc/driver/thermal/tzbtspa_param
echo 'PUP_R 100000 PUP_VOLT 1800 OVER_CRITICAL_L 4397119 NTC_TABLE 7 2' > /proc/driver/thermal/tzbtsnrpa_param

if [[ "$1" == "1" ]]; then
  echo 1 > /proc/driver/thermal/sspm_thermal_throttle
fi

echo '3 117000 0 mtktscpu-sysrst 85000 0 cpu_adaptive_0 76000 0 cpu_adaptive_1 0 0 no-cooler 0 0' > /proc/driver/thermal/tzcpu
echo '1 136000 0 mtktspmic-sysrst 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000' > /proc/driver/thermal/tzpmic
echo '1 60000 0 mtktsbattery-sysrst 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000' > /proc/driver/thermal/tzbattery
echo '1 120000 0 mtk-cl-kshutdown00 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 2000' > /proc/driver/thermal/tzpa
echo '1 120000 0 mtktscharger-sysrst 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 2000' > /proc/driver/thermal/tzcharger
echo '1 120000 0 mtktswmt-sysrst 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000' > /proc/driver/thermal/tzwmt
echo '1 100000 0 mtktsAP-sysrst 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000' > /proc/driver/thermal/tzbts
echo '1 120000 0 mtk-cl-kshutdown01 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000' > /proc/driver/thermal/tzbtsnrpa
echo '1 120000 0 mtk-cl-kshutdown02 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000' > /proc/driver/thermal/tzbtspa

echo 'ma_len 1' > /proc/mtktz/mtktscpu
echo 'ma_len 4'  > /proc/mtktz/mtktspmic
echo 'ma_len 4' > /proc/mtktz/mtktsbattery
echo 'ma_len 1' > /proc/mtktz/mtktspa
echo 'ma_len 1' > /proc/mtktz/mtktscharger
echo 'ma_len 1' > /proc/mtktz/mtktswmt
echo 'ma_len 1'  => /proc/mtktz/mtktsAP
echo 'ma_len 1' > /proc/mtktz/mtktsbtsnrpa
echo 'ma_len 1' > /proc/mtktz/mtktsbtsmdpa
}

thermal_basic(){
echo 95 70 > /proc/driver/thermal/clatm_gpu_threshold
echo 3 117000 0 mtktscpu-sysrst 85000 0 cpu_adaptive_0 76000 0 cpu_adaptive_1 0 0 no-cooler 0 0 > /proc/driver/thermal/tzcpu
echo 4 120000 0 mtk-cl-kshutdown02 110000 0 no-cooler 100000 0 no-cooler 90000 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 0 0 no-cooler 1000 > /proc/driver/thermal/tzbtspa
echo 2 100000 90000 80000 85000 93000 85000 235000 2000 230000 2000 500 500 13500 > /proc/driver/thermal/clctm
echo 0 3 4 11 3 15 1 15 > /proc/driver/thermal/clatm_cpu_min_opp
echo 1 3 4 5 0 0 0 0 > /proc/driver/thermal/clatm_cpu_min_opp
}

# cpuset parameters
echo 0-2 > /dev/cpuset/background/cpus
echo 0-3 > /dev/cpuset/system-background/cpus
echo 0-7 > /dev/cpuset/foreground/cpus
echo 0-7 > /dev/cpuset/top-app/cpus

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


echo 0 > /sys/kernel/fpsgo/fbt/enable_switch_cap_margin
echo 0 > /sys/kernel/fpsgo/fbt/enable_switch_sync_flag
echo 0 > /sys/kernel/fpsgo/fbt/enable_switch_cap_margin
echo 0 > /sys/kernel/fpsgo/fbt/light_loading_policy
echo 0 > /sys/kernel/fpsgo/fbt/llf_task_policy
echo 0 > /sys/kernel/fpsgo/fbt/switch_idleprefer
echo 100 > /sys/kernel/fpsgo/fbt/thrm_temp_th
echo -1 > /sys/kernel/fpsgo/fbt/thrm_limit_cpu
echo -1 > /sys/kernel/fpsgo/fbt/thrm_sub_cpu
echo 0 > /sys/kernel/fpsgo/fbt/ultra_rescue

echo 0 > /sys/devices/system/cpu/sched/hint_enable
# echo 5 > /sys/devices/system/cpu/sched/hint_load_thresh
# cat /sys/devices/system/cpu/sched/hint_info
echo 0 > /proc/sys/kernel/slide_boost_enabled
echo 0 > /proc/sys/kernel/launcher_boost_enabled

thermal_gt 0

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
# echo cluster_opp 0 -1 > /proc/perfmgr/tchbst/user/usrtch
# echo cluster_opp 1 -1 > /proc/perfmgr/tchbst/user/usrtch
# echo cluster_opp 2 -1 > /proc/perfmgr/tchbst/user/usrtch
# echo eas_boost 0 > /proc/perfmgr/tchbst/user/usrtch # 0 ~ 100 , default 80

set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    echo $pid > /dev/stune/$2/cgroup.procs
  done
}

process_opt() {
  set_cpuset surfaceflinger top-app
  set_cpuset system_server top-app
  # set_cpuset mediaserver background
  # set_cpuset media.hwcodec background

  # set_task_affinity `pgrep com.miui.home` 11111111
  # set_task_affinity `pgrep com.miui.home` 11110000

  echo 1 > /dev/stune/rt/schedtune.sched_boost_no_override
  echo 1 > /dev/stune/rt/schedtune.prefer_idle
  echo 0 > /dev/stune/rt/schedtune.boost
  move_to_rt surfaceflinger
  move_to_rt system_server
  move_to_rt android.hardware.graphics.composer@2.2-service
  move_to_rt com.android.systemui
  move_to_rt com.miui.home
  move_to_rt com.omarea.gesture
}

# cpuctl top-app 0 0 0 max
# cpuctl foreground 0 0 0 max
# cpuctl background 0 0 0 max
# mk_cpuctl 'top-app/heavy' 1 1 max max

set_value 8000000 /proc/sys/kernel/sched_latency_ns
set_value 2000000 /proc/sys/kernel/sched_min_granularity_ns

move_to_rt() {
  pidof $1 | while read pid; do
    echo $pid > /dev/stune/rt/cgroup.procs
    echo $pid > /dev/cpuset/top-app/cgroup.procs
  done
}

ctl_off cpu0
ctl_off cpu4
ctl_off cpu7
disable_migt
# disable_oppo_elf
process_opt &
# voltage_offset &
