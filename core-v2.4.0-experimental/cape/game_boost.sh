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

set_cpuset kswapd0 'foreground'
set_cpuset toucheventcheck 'foreground'
set_cpuset touch_report 'foreground'
set_cpuset surfaceflinger 'foreground'
set_cpuset system_server 'foreground'
set_cpuset update_engine 'top-app/7'
set_cpuset vendor.qti.hardware.display.composer-service 'foreground'
