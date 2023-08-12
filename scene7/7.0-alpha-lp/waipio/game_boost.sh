set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuset/$2/tasks
    done
  done
}

mk_cpuset(){
  mkdir /dev/cpuset/top-app/$1
  echo $1 > /dev/cpuset/top-app/$1/cpus
  echo 0 > /dev/cpuset/top-app/$1/mems
}
mk_cpuset 4-5
mk_cpuset 0-5

set_cpuset toucheventcheck "top-app/4-5"
set_cpuset touch_report "top-app/4-5"
set_cpuset surfaceflinger "top-app/0-5"
set_cpuset system_server "top-app/0-5"
set_cpuset update_engine "top-app/0-5"
set_cpuset vendor.qti.hardware.display.composer-service "top-app/0-5"
