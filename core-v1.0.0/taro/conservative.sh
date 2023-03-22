action=$1
task=$2

cfg_dir=$(cd $(dirname $0); pwd)

if [[ ! -f "$cfg_dir/powercfg-utils.sh" ]]; then
  echo "The dependent '$cfg_dir/powercfg-utils.sh' was not found !" > /cache/powercfg.sh.log
  exit 1
fi

source "$cfg_dir/powercfg-utils.sh"

init () {
  echo '[Scene PerfConfig Init] ...'
  if [[ -f "$cfg_dir/powercfg-base.sh" ]]; then
    source "$cfg_dir/powercfg-base.sh"
  elif [[ -f '/data/powercfg-base.sh' ]]; then
    source /data/powercfg-base.sh
  fi
  echo '[Scene PerfConfig Init] √'
}

if [[ "$action" == "init" ]]; then
  init
  exit 0
fi

reset_basic_governor

if [[ "$action" = "powersave" ]]; then
  cpu4_core_ctl on
  cpu7_core_ctl on

  set_cpu_freq 307200 1689600 633600 1555200 806400 1728000
  gpu_pl_up 0
  sched_boost 0 0
  set_hispeed_freq 960000 633600 806400
  sched_config "85 75" "96 86" "150" "400"
  sched_limit 0 2000 0 5000 0 1000
  stune_top_app 0 0
  cpuset '0-2' '0-3' '0-7' '0-7'
  cpuctl foreground 1 0 0 max
  cpuctl background 1 0 0 1
  cpuctl top-app 1 0 0 max
  bw_min
  bw_down 3 3
  thermal_disguise 0
  set_cpu_pl 0
  if [[ "$manufacturer" == "Xiaomi" ]]; then
    stop miuibooster
  fi
  realme_gt_on=0


elif [[ "$action" = "balance" ]]; then
  cpu4_core_ctl off
  cpu7_core_ctl off

  set_cpu_freq 307200 1785600 633600 1881600 806400 2054400
  gpu_pl_up 0
  sched_boost 1 0
  set_hispeed_freq 1689600 1113600 1401600
  sched_config "78 75" "89 86" "150" "400"
  sched_limit 0 0 0 500 0 500
  stune_top_app 0 0
  cpuset '0-2' '0-3' '0-7' '0-7'
  cpuctl foreground 1 0 0 max
  cpuctl background 1 0 0 max
  cpuctl top-app 1 0 0 max
  bw_min
  bw_down 2 2
  thermal_disguise 0
  set_cpu_pl 0
  if [[ "$manufacturer" == "Xiaomi" ]]; then
    stop miuibooster
  fi
  realme_gt_on=0


elif [[ "$action" = "performance" ]]; then
  cpu4_core_ctl off
  cpu7_core_ctl off

  set_cpu_freq 307200 1785600 633600 2419200 806400 2822400
  gpu_pl_up 0
  sched_boost 1 0
  set_hispeed_freq 1689600 1766400 2054400
  sched_config "65 65" "75 78" "200" "400"
  sched_limit 0 0 0 0 0 0
  stune_top_app 0 0
  cpuset '0-1' '0-3' '0-7' '0-7'
  cpuctl foreground 1 0 0.25 max
  cpuctl background 1 0 0 1
  cpuctl top-app 1 0 0.25 max
  bw_min
  bw_max
  thermal_disguise 0
  set_cpu_pl 1
  if [[ "$manufacturer" == "Xiaomi" ]]; then
    start miuibooster
  fi
  realme_gt_on=1


elif [[ "$action" = "fast" ]]; then
  cpu4_core_ctl off
  cpu7_core_ctl off

  set_cpu_freq 1478400 1785600 1440000 2419200 1612800 3200000
  set_hispeed_freq 0 0 0
  gpu_pl_up 2
  sched_boost 1 0
  sched_config "62 40" "70 52" "300" "400"
  sched_limit 5000 0 2000 0 2000 0
  stune_top_app 1 0
  cpuset '0' '0-3' '0-7' '0-7'
  cpuctl foreground 1 0 0.5 max
  cpuctl background 1 0 0 max
  cpuctl top-app 1 0 0.5 max
  bw_max_always
  thermal_disguise 1
  set_cpu_pl 1
  if [[ "$manufacturer" == "Xiaomi" ]]; then
    start miuibooster
  fi
  realme_gt_on=1

fi

adjustment_by_top_app
realme_gt $realme_gt_on
restore_core_online
# renice -n -20 `pgrep com.miui.home` 2> /dev/null
