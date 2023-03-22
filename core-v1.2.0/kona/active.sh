action=$1
task=$2

init () {
  echo '[Scene PerfConfig Init] ...'
  if [[ -f "$cfg_dir/powercfg-base.sh" ]]; then
    nohup "$cfg_dir/powercfg-base.sh" >/dev/null 2>&1 &
  elif [[ -f '/data/powercfg-base.sh' ]]; then
    nohup /data/powercfg-base.sh >/dev/null 2>&1 &
  fi
  echo '[Scene PerfConfig Init] √'
}

if [[ "$action" == "init" ]]; then
  init
  exit 0
fi

cfg_dir=$(cd $(dirname $0); pwd)

if [[ ! -f "$cfg_dir/powercfg-utils.sh" ]]; then
  echo "The dependent '$cfg_dir/powercfg-utils.sh' was not found !" > /cache/powercfg.sh.log
  exit 1
fi

source "$cfg_dir/powercfg-utils.sh"

if [[ "$action" == "fast" ]]; then
  bw_max_always
else
  bw_min
fi
reset_basic_governor

if [[ "$action" = "powersave" ]]; then
  set_cpu_freq 300000 1708800 710400 1574400 844800 1747200
  gpu_pl_up 0
  sched_boost 0 0
  set_hispeed_freq 1075200 710400 844800
  sched_config "70 67" "86 80" "200" "400"
  sched_limit 0 0 0 2000 0 1000
  cpuset '0-2' '0-3' '0-7' '0-7'
  stune_top_app 0 0
  set_cpu_pl 0

  realme_gt_on=0

elif [[ "$action" = "balance" ]]; then
  set_cpu_freq 300000 1804800 710400 2054400 844800 2361600
  gpu_pl_up 0
  sched_boost 1 0
  set_hispeed_freq 1612800 1056000 1305600
  sched_config "53 65" "70 80" "200" "400"
  sched_limit 0 0 0 0 0 0
  cpuset '0-2' '1-4' '1-6' '0-7'
  stune_top_app 0 0
  set_cpu_pl 1

  realme_gt_on=0

elif [[ "$action" = "performance" ]]; then
  set_cpu_freq 300000 1804800 710400 2419200 825600 3200000
  gpu_pl_up 1
  sched_boost 1 0
  set_hispeed_freq 1612800 1766400 2073600
  sched_config "50 63" "65 78" "200" "400"
  sched_limit 0 0 0 0 0 0
  cpuset '0-1' '1-4' '1-6' '0-7'
  stune_top_app 1 0
  set_cpu_pl 1

  realme_gt_on=1

elif [[ "$action" = "fast" ]]; then
  set_cpu_freq 1420800 1804800 1766400 2600000 1977600 3200000
  set_hispeed_freq 0 0 0
  gpu_pl_up 2
  sched_boost 1 0
  sched_config "47 60" "60 78" "300" "400"
  sched_limit 5000 0 2000 0 2000 0
  cpuset '0-1' '1-4' '1-7' '0-7'
  stune_top_app 1 50
  set_cpu_pl 1

  realme_gt_on=1


elif [[ "$action" = "pedestal" ]]; then
  set_cpu_freq 1804800 1804800 2419200 2600000 2841600 3200000
  set_hispeed_freq 0 0 0
  gpu_pl_up 4
  sched_boost 1 0
  sched_config "47 50" "60 68" "75" "90"
  sched_limit 5000 0 5000 0 5000 0
  cpuset '0-1' '1-4' '1-7' '0-7'
  stune_top_app 1 100
  set_cpu_pl 1

  realme_gt_on=1

fi

adjustment_by_top_app
realme_gt $realme_gt_on
