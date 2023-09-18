exit

set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    taskset -p $3 $pid
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuset/$2/tasks
      taskset -p $3 $tid
    done
  done
}

mkdir /dev/cpuset/foreground/4-5
echo 4-5 > /dev/cpuset/foreground/4-5/cpus
echo 0 > /dev/cpuset/foreground/4-5/mems

set_cpuset toucheventcheck 'foreground/4-5' 38
set_cpuset touch_report 'foreground/4-5' 38
set_cpuset surfaceflinger 'foreground/4-5' 38
set_cpuset system_server 'foreground/4-5' 38
set_cpuset update_engine 'top-app' f0
set_cpuset android.hardware.graphics.composer 'foreground/4-5' 38



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
  sleep 20

  change_task_cpuset "svendor.mediatek.hardware.pq|android.hardware.sensors|statsd|logd|scene-daemon" "foreground"
  change_task_cpuset "aal_sof|kfps|dsp_send_thread|vdec_ipi_recv|mtk_drm_disp_id|disp_feature|hif_thread|main_thread|rx_thread|ged_" "system-background"
  change_task_cpuset 'mediaserver64|android.hardware.media.c2' 'foreground'


  for name in 'kcompactd0' 'aal_sof' 'kfps' 'kworker'
  do
    taskset -p 3f $(pgrep -ef $name) > /dev/null
  done
}

process_opt &


metis=/sys/module/metis/parameters
for file in $metis/*enable*; do
  echo 0 > $file
done
if [[ -d $metis ]]; then
  chmod -R 444 $metis
fi
