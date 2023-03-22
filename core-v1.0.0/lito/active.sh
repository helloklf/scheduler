#!/system/bin/sh

action=$1
task=$2

cfg_dir=$(cd $(dirname $0); pwd)

if [[ ! -f "$cfg_dir/powercfg-utils.sh" ]]; then
  echo "The dependent '$cfg_dir/powercfg-utils.sh' was not found !" > /cache/powercfg.sh.log
  exit 1
fi

source "$cfg_dir/powercfg-utils.sh"

init () {
  if [[ -f "$cfg_dir/powercfg-base.sh" ]]; then
    source "$cfg_dir/powercfg-base.sh"
  elif [[ -f '/data/powercfg-base.sh' ]]; then
    source /data/powercfg-base.sh
  fi
}

if [[ "$action" == "init" ]]; then
  init
  exit 0
fi

if [[ "$action" == "fast" ]]; then
  devfreq_performance
else
  devfreq_restore
fi
reset_basic_governor

if [[ "$action" = "powersave" ]]; then
  set_cpu_freq 300000 1804800 652800 1900800 806400 2188800
  set_input_boost_freq 0 0 0 0
  # gpu_pl_up 0
  sched_boost 0 0
  stune_top_app 0 0
  cpu6_core_ctl on
  cpu7_core_ctl on
  set_hispeed_freq 1651200 1152000 1401600
  cpuset '0-2' '0-3' '0-7' '0-7'
  sched_config "78 78" "96 96" "300" "400"
  sched_limit 0 500 0 1000 0 1000

elif [[ "$action" = "balance" ]]; then
  set_cpu_freq 300000 1804800 652800 2092800 806400 2188800
  set_input_boost_freq 0 0 0 0
  # gpu_pl_up 0
  sched_boost 1 0
  stune_top_app 0 0
  cpu6_core_ctl off
  cpu7_core_ctl off
  set_hispeed_freq 1651200 1478400 1401600
  cpuset '0-2' '0-3' '0-7' '0-7'
  sched_config "60 60" "75 75" "300" "400"
  sched_limit 0 0 0 0 0 0

elif [[ "$action" = "performance" ]]; then
  set_cpu_freq 902400 1804800 652800 2208000 806400 2400000
  set_input_boost_freq 0 0 0 0
  gpu_pl_up 1
  sched_boost 1 0
  stune_top_app 0 2
  cpu6_core_ctl off
  cpu7_core_ctl off
  set_hispeed_freq 0 0 0
  cpuset '0-1' '0-3' '0-7' '0-7'
  sched_config "60 60" "72 72" "300" "400"
  sched_limit 20000 0 3000 0 3000 0

elif [[ "$action" = "fast" ]]; then
  set_cpu_freq 1651200 1804800 1728000 2208000 1766400 2900000
  set_input_boost_freq 0 0 0 0
  gpu_pl_up 2
  sched_boost 1 0
  stune_top_app 1 30
  cpu6_core_ctl off
  cpu7_core_ctl off
  set_hispeed_freq 0 0 0
  cpuset '0' '0-1' '0-7' '0-7'
  sched_config "52 52" "65 65" "300" "400"
  sched_limit 50000 0 2000 0 2000 0

elif [[ "$action" = "pedestal" ]]; then
  set_cpu_freq 1804800 1804800 2208000 2208000 2400000 2900000
  set_input_boost_freq 0 0 0 0
  gpu_pl_up 3
  sched_boost 1 0
  stune_top_app 1 100
  cpu6_core_ctl off
  cpu7_core_ctl off
  set_hispeed_freq 0 0 0
  cpuset '0' '0' '0-7' '0-7'
  sched_config "48 48" "65 65" "300" "400"
  sched_limit 50000 0 20000 0 20000 0
  echo 0-7 > /dev/cpuset/foreground/cpus

fi

adjustment_by_top_app
