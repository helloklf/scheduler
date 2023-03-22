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

if [[ "$action" = "powersave" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 60 80 70 90 78 93
  conservative_step 2 1 1
  set_cpu_freq 307200 1689600 633600 1555200 806400 1728000
  gpu_pl_up 0
  # set_hispeed_freq 960000 633600 806400
  set_cpu_pl 0
  realme_gt_on=0


elif [[ "$action" = "balance" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 55 75 68 87 69 87
  conservative_step 2 2 2
  walt_mode 0 3000 0 10000 0 10000
  set_cpu_freq 307200 1785600 633600 1881600 806400 2054400
  # set_hispeed_freq 1689600 1113600 1401600
  set_cpu_pl 0
  realme_gt_on=0


elif [[ "$action" = "performance" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 43 67 68 82 67 83
  conservative_step 3 3 3
  walt_mode 0 2000 0 6000 0 6000
  set_cpu_freq 307200 1785600 633600 2419200 806400 2822400
  # set_hispeed_freq 1689600 1766400 2054400
  set_cpu_pl 1
  realme_gt_on=1


elif [[ "$action" = "fast" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 35 50 58 68 48 63
  conservative_step 3 3 3
  walt_mode 0 1000 0 4000 0 4000
  set_cpu_freq 1075200 1785600 633600 2496000 806400 2995200
  # set_hispeed_freq 0 0 0
  set_cpu_pl 1
  realme_gt_on=1

elif [[ "$action" = "pedestal" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 35 50 45 68 37 55
  conservative_step 3 3 3
  walt_mode 0 0 0 0 0 0
  set_cpu_freq 1075200 1785600 1209600 2496000 1286400 2995200
  # set_hispeed_freq 0 0 0
  set_cpu_pl 1
  realme_gt_on=1

fi

adjustment_by_top_app
realme_gt $realme_gt_on
