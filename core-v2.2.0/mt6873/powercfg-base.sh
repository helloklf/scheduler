killall scene-scheduler 2>/dev/null

target=`getprop ro.board.platform`

echo 90 > /sys/module/ged/parameters/g_fb_dvfs_threshold
echo 358000 > /sys/module/ged/parameters/gpu_bottom_freq
echo 902000 > /sys/module/ged/parameters/gpu_cust_upbound_freq
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