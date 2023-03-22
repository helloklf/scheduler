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

reset_basic_governor

if [[ "$action" = "powersave" ]]; then
  cpu4_core_ctl on
  cpu7_core_ctl on

  set_cpu_freq 300000 1708800 710400 1555200 844800 1785600
  gpu_pl_up 0
  sched_boost 0 0
  set_hispeed_freq 902400 710400 844800
  sched_config "85 75" "96 86" "150" "400"
  sched_limit 0 0 0 2000 0 1000
  stune_top_app 0 0
  if [[ $a12 == true ]]; then
    cpuset '0-2' '0-3' '0-7' '0-7'
    cpuctl foreground 1 0 0 max
    cpuctl background 1 0 0 1
    cpuctl top-app 1 0 0 max
  else
    cpuset '0-2' '0-3' '0-3' '0-7'
    cpuctl foreground 0 0 0 1
    cpuctl background 0 0 0 0
    cpuctl top-app 0 0 0 max
  fi
  bw_min
  bw_down 3 3
  set_cpu_pl 0
  tcp_low_latency 0

  realme_gt_on=0

elif [[ "$action" = "balance" ]]; then
  cpu4_core_ctl off
  cpu7_core_ctl off

  set_cpu_freq 300000 1804800 710400 1996800 844800 2380800
  gpu_pl_up 0
  sched_boost 1 0
  set_hispeed_freq 1612800 1075200 1305600
  sched_config "78 70" "89 82" "150" "400"
  sched_limit 0 0 0 500 0 500
  stune_top_app 0 0
  if [[ $a12 == true ]]; then
    cpuset '0-2' '0-3' '0-7' '0-7'
    cpuctl foreground 1 0 0 max
    cpuctl background 1 0 0 max
    cpuctl top-app 1 0 0.25 max
  else
    cpuset '0-2' '0-3' '0-6' '0-7'
    cpuctl foreground 0 1 0 max
    cpuctl background 0 1 0 1
    cpuctl top-app 0 1 0.25 max
  fi
  bw_min
  bw_down 2 2
  set_cpu_pl 0
  tcp_low_latency 0

  realme_gt_on=0

elif [[ "$action" = "performance" ]]; then
  cpu4_core_ctl off
  cpu7_core_ctl off

  set_cpu_freq 300000 1804800 710400 2419200 825600 2841600
  gpu_pl_up 1
  sched_boost 1 0
  set_hispeed_freq 0 0 0
  sched_config "62 55" "72 65" "200" "400"
  sched_limit 0 0 0 0 0 0
  stune_top_app 1 0
  if [[ $a12 == true ]]; then
    cpuset '0-1' '0-3' '0-7' '0-7'
    cpuctl foreground 1 0 0.25 max
    cpuctl background 1 0 0 max
    cpuctl top-app 1 0 0.5 max
  else
    cpuset '0-1' '0-3' '0-6' '0-7'
    cpuctl foreground 0 1 0 max
    cpuctl background 0 1 0 max
    cpuctl top-app 0 1 0.5 max
  fi
  bw_min
  bw_max
  set_cpu_pl 1
  tcp_low_latency 1

  realme_gt_on=1

elif [[ "$action" = "fast" ]]; then
  cpu4_core_ctl off
  cpu7_core_ctl off

  set_cpu_freq 1401600 1804800 1766400 2600000 1670400 3200000
  set_hispeed_freq 0 0 0
  gpu_pl_up 2
  sched_boost 1 2
  sched_config "62 35" "70 50" "300" "400"
  sched_limit 5000 0 2000 0 2000 0
  stune_top_app 1 50
  if [[ $a12 == true ]]; then
    cpuset '0' '0-3' '0-7' '0-7'
    cpuctl foreground 1 0 0.5 max
    cpuctl background 1 0 0 max
    cpuctl top-app 1 0 max max
  else
    cpuset '0' '0-3' '0-6' '0-7'
    cpuctl foreground 0 1 0 max
    cpuctl background 0 1 0 max
    cpuctl top-app 0 1 max max
  fi
  bw_max_always
  set_cpu_pl 1
  tcp_low_latency 1

  realme_gt_on=1

elif [[ "$action" = "pedestal" ]]; then
  cpu4_core_ctl off
  cpu7_core_ctl off

  set_cpu_freq 1804800 1804800 2419200 2600000 2841600 3200000
  set_hispeed_freq 0 0 0
  gpu_pl_up 5
  sched_boost 1 0
  sched_config "62 40" "70 52" "300" "400"
  sched_limit 50000 0 20000 0 20000 0
  stune_top_app 1 100
  if [[ $a12 == true ]]; then
    cpuset '0' '0-3' '0-7' '0-7'
    cpuctl foreground 1 0 max max
    cpuctl background 1 0 0 max
    cpuctl top-app 1 0 max max
  else
    cpuset '0' '0-3' '0-7' '0-7'
    cpuctl foreground 0 1 max max
    cpuctl background 0 1 0 max
    cpuctl top-app 0 1 max max
  fi
  bw_max_always
  set_cpu_pl 1
  tcp_low_latency 1

  realme_gt_on=1

fi

adjustment_by_top_app
realme_gt $realme_gt_on
restore_core_online
# renice -n -20 `pgrep com.miui.home` 2> /dev/null
