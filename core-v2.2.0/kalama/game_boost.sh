set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuset/$2/tasks
    done
  done
}

mkdir /dev/cpuset/top-app/3-5
echo 3-5 > /dev/cpuset/top-app/3-5/cpus
echo 0 > /dev/cpuset/top-app/3-5/mems

set_cpuset toucheventcheck 'top-app/3-5'
set_cpuset touch_report 'top-app/3-5'
set_cpuset surfaceflinger 'top-app/3-5'
set_cpuset system_server 'top-app/3-5'
set_cpuset update_engine 'top-app/3-5'
set_cpuset vendor.qti.hardware.display.composer-service 'top-app/3-5'
