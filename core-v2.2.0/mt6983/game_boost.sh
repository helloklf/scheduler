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
