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

reset_basic_governor

if [[ "$action" = "powersave" ]]; then
  set_cpu_freq 300000 1708800 710400 1401600 825600 1497600
  sched_boost 0 0
  stune_top_app 0 0
  sched_config "85 85" "96 96" "160" "260"
  sched_limit 0 0 0 5000 0 5000
  # set_hispeed_freq 1209600 825600 940800
  # set_hispeed_load 80 90 90
  cpuset '0-2' '0-3' '0-3' '0-7'
  bw_min
  bw_down 2
  ufshc_perf off

elif [[ "$action" = "balance" ]]; then
  set_cpu_freq 300000 1708800 710400 1708800 825600 1920000
  sched_boost 1 0
  stune_top_app 0 0
  sched_config "78 85" "89 96" "120" "200"
  sched_limit 0 0 0 500 0 500
  # set_hispeed_freq 1478400 1056000 1286400
  # set_hispeed_load 80 90 90
  cpuset '0-2' '0-3' '0-7' '0-7'
  bw_min
  bw_down 1
  ufshc_perf off

elif [[ "$action" = "performance" ]]; then
  set_cpu_freq 300000 1785600 710400 2419200 825600 2841600
  sched_boost 1 0
  stune_top_app 0 0
  sched_config "62 78" "72 85" "85" "100"
  sched_limit 0 0 0 0 0 0
  # set_hispeed_freq 1632000 1708800 2016000
  # set_hispeed_load 60 70 80
  cpuset '0-2' '0-3' '0-7' '0-7'
  bw_min
  bw_max
  ufshc_perf off

elif [[ "$action" = "fast" ]]; then
  set_cpu_freq 1209600 1785600 1497600 2600000 1497600 3200000
  sched_boost 1 0
  stune_top_app 1 10
  sched_config "55 60" "65 73" "300" "400"
  sched_limit 50000 0 20000 0 20000 0
  # set_hispeed_freq 0 0 0
  # set_hispeed_load 50 60 70
  cpuset '0-1' '0-3' '0-7' '0-7'
  bw_max_always
  ufshc_perf on

elif [[ "$action" = "pedestal" ]]; then
  set_cpu_freq 1785600 1785600 2419200 2600000 2841600 3200000
  sched_boost 1 0
  stune_top_app 1 100
  sched_config "55 58" "65 70" "300" "400"
  sched_limit 50000 0 20000 0 20000 0
  # set_hispeed_freq 0 0 0
  # set_hispeed_load 50 60 70
  cpuset '0-1' '0-3' '0-7' '0-7'
  bw_max_always
  ufshc_perf on

fi

adjustment_by_top_app