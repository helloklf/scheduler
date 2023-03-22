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

if [[ "$action" = "powersave" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 60 80 70 90 78 93
  conservative_step 2 1 1
  walt_mode 0 3000 0 6000 0 6000
  set_cpu_freq 307200 1478400 633600 1555200 806400 1728000
  gpu_pl_up 0
  set_hispeed_freq 1075200 633600 806400
  set_hispeed_load 90 90 90
  set_cpu_pl 0
  realme_gt_on=0


elif [[ "$action" = "balance" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 55 75 68 87 69 87
  conservative_step 2 2 2
  walt_mode 0 2000 0 4000 0 4000
  set_cpu_freq 307200 1574400 633600 1881600 806400 2054400
  set_hispeed_freq 1363200 1209600 1401600
  set_hispeed_load 85 85 85
  set_cpu_pl 0
  realme_gt_on=0


elif [[ "$action" = "performance" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 43 67 68 82 67 83
  conservative_step 3 3 3
  walt_mode 0 2000 0 3000 0 3000
  set_cpu_freq 307200 1785600 633600 2419200 806400 2822400
  set_hispeed_freq 1363200 1766400 1843200
  set_hispeed_load 82 82 82
  set_cpu_pl 1
  realme_gt_on=1


elif [[ "$action" = "fast" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 35 50 58 68 48 63
  conservative_step 3 3 3
  walt_mode 0 1000 0 2000 0 2000
  set_cpu_freq 1075200 1785600 998400 2496000 940800 2995200
  set_hispeed_freq 1478400 1996800 1958400
  set_hispeed_load 80 80 80
  set_cpu_pl 1
  realme_gt_on=1

elif [[ "$action" = "pedestal" ]]; then
  cpu_governor='walt' # walt schedutil
  reset_basic_governor

  retro_mode 35 50 45 68 37 55
  conservative_step 3 3 3
  walt_mode 0 0 0 0 0 0
  set_cpu_freq 1075200 1785600 1209600 2496000 1286400 2995200
  set_hispeed_freq 1574400 2227200 2284800
  set_hispeed_load 75 75 75
  set_cpu_pl 1
  realme_gt_on=1

fi

adjustment_by_top_app
realme_gt $realme_gt_on
