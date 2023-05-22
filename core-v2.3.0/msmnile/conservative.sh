action=$1
task=$2
cfg_dir=$(cd $(dirname $0); pwd)

init () {
  nohup "$cfg_dir/powercfg-base.sh" >/dev/null 2>&1 &
  echo '[Scene PerfConfig Init] √'
}

if [[ "$action" == "init" ]]; then
  init
  exit 0
fi

