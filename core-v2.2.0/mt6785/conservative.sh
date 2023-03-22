action=$1
task=$2

cfg_dir=$(cd $(dirname $0); pwd)


source "$cfg_dir/powercfg-utils.sh"

init () {
  killall scene-scheduler 2>/dev/null

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
