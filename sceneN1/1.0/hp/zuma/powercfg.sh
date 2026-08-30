set_value() {
  value=$1
  path=$2
  if [[ -f $path ]]; then
    current_value="$(cat $path)"
    if [[ ! "$current_value" = "$value" ]]; then
      chmod 0664 "$path"
      echo "$value" > "$path"
    fi;
  fi;
}

lock_value() {
  if [[ -f $2 ]];then
    chmod 644 $2
    echo $1 > $2
    chmod 444 $2
  fi
}

dev_mount=/dev/$(cat /dev/urandom | tr -dc 'a-z_' | head -c 8; echo)
# hide_value /sys/module/task_turbo/parameters/feats [write_value]
hide_value() {
  if [[ -e "$1" ]]; then
    umount "$1" 2>/dev/null
    c_path="$dev_mount${1}"
    if [[ ! -f "$c_path" ]]; then
      mkdir -p "$c_path"
      rm -r "$c_path"
    fi
    cp -f "$1" "$c_path"
    if [[ "$2" != "" ]]; then
      set_value "$2" "$1"
    fi
    mount --bind "$c_path" "$1"
  else
    echo "$1" Not Found!
  fi
}

for tz in `ls /sys/class/thermal | grep thermal_zone`
do
  if [[ -f /sys/class/thermal/$tz/type ]]; then
    case $(cat /sys/class/thermal/$tz/type) in
      # "north_therm"|"cam_therm"|"soc_therm"|"charge_therm"|"disp_therm"|"battery"|"neutral_therm"| "quiet_therm"|"usb_pwr_therm")
      "north_therm"|"cam_therm"|"soc_therm"|"charge_therm"|"disp_therm"|"neutral_therm"| "quiet_therm"|"usb_pwr_therm")
      echo 10000 > /sys/class/thermal/$tz/emul_temp
    ;;
    esac
  fi
done