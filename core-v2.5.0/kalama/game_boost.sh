# version=$(dumpsys package com.omarea.vtools | grep versionCode | cut -f2 -d '=' | cut -f1 -d ' ')
cpus=3-6

set_cpuset(){
  pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/$2/cgroup.procs
    ls /proc/$pid/task | while read tid
    do
      echo $tid > /dev/cpuset/$2/tasks
    done
  done
}

rmdir /dev/cpuset/background/untrustedapp
mkdir /dev/cpuset/top-app/$cpus
echo $cpus > /dev/cpuset/top-app/$cpus/cpus
echo 0 > /dev/cpuset/top-app/$cpus/mems

rmdir /dev/cpuset/foreground/boost
set_cpuset kswapd0 'foreground'
set_cpuset toucheventcheck "top-app/$cpus"
set_cpuset touch_report "top-app/$cpus"
set_cpuset surfaceflinger "top-app/$cpus"
set_cpuset system_server "top-app/$cpus"
set_cpuset update_engine "top-app/$cpus"
set_cpuset audioserver 'foreground'
set_cpuset android.hardware.audio.service_64 'foreground'
set_cpuset vendor.qti.hardware.display.composer-service "top-app/$cpus"
