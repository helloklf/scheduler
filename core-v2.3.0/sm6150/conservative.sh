#!/system/bin/sh

action=$1
task=$2

cfg_dir=$(cd $(dirname $0); pwd)

init () {
  source "$cfg_dir/powercfg-utils.sh"
  source "$cfg_dir/powercfg-base.sh"
}

if [[ "$action" == "init" ]]; then
  init
  exit 0
fi
