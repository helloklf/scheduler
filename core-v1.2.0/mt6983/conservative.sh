action=$1
task=$2

cfg_dir=$(cd $(dirname $0); pwd)

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

source "$cfg_dir/powercfg-utils.sh"

# 当前被打开的前台应用（需要Scene 4.3+版本，并开启【严格模式】才会获得此值）
if [[ "$top_app" != "" ]]; then
  echo "应用切换到前台 [$top_app]" >> /cache/scene_powercfg.log
fi

if [[ "$action" = "powersave" ]]; then
  echo "powersave"
elif [[ "$action" = "balance" ]]; then
  echo "balance"
elif [[ "$action" = "performance" ]]; then
  echo "performance"
elif [[ "$action" = "fast" ]]; then
  echo "fast"
elif [[ "$action" = "pedestal" ]]; then
  echo "pedestal"
fi

adjustment_by_top_app