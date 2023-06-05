action=$1
task=$2
SCDIR=${0%/*}

init () {
  echo '[Scene PerfConfig Init] ...'
  if [[ -f "$SCDIR/powercfg-base.sh" ]]; then
    nohup "$SCDIR/powercfg-base.sh" >/dev/null 2>&1 &
    nohup "$SCDIR/game_boost.sh" >/dev/null 2>&1 &
  fi
  killall 'scene-scheduler' 2>/dev/null
  echo '[Scene PerfConfig Init] √'
}

if [[ "$action" == "init" ]]; then
  init
  exit 0
fi
