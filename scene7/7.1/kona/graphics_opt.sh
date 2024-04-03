
alias encodeURIComponent="xxd -p | tr -d '\n' | sed 's/\(..\)/%\1/g'"
alias decodeURIComponent="sed 's/%/\\\\x/g' | xargs -0 printf '%b'"

speed_mobile_presets() {
  for game in com.tencent.tmgp.speedmobile
  do
    xml=/storage/emulated/0/Android/data/$game/files/GameSettingData.json
    sed -i 's/mIsOpenMASS".*,/mIsOpenMASS": false,/' $xml
    sed -i 's/PowerSaving".*,/PowerSaving": false,/' $xml
    sed -i 's/PowerSavingEx".*,/PowerSavingEx": true,/' $xml
    sed -i 's/mResolutionOption": [0-9]/mResolutionOption": 2/' $xml
    sed -i 's/mHighQuaOption": [0-9]/mHighQuaOption": 0/' $xml
    sed -i 's/mEffectQuality": [0-9]/mEffectQuality": 1/' $xml
  done
}

hkrpg_presets() {
  # <string name="GraphicsSettings_Model">%7B%22FPS%22%3A60%2C%22EnableVSync%22%3Afalse%2C%22RenderScale%22%3A1.0%2C%22ResolutionQuality%22%3A3%2C%22ShadowQuality%22%3A3%2C%22LightQuality%22%3A3%2C%22CharacterQuality%22%3A3%2C%22EnvDetailQuality%22%3A2%2C%22ReflectionQuality%22%3A2%2C%22SFXQuality%22%3A2%2C%22BloomQuality%22%3A1%2C%22AAMode%22%3A0%2C%22EnableMetalFXSU%22%3Afalse%7D</string>

  a='GraphicsSettings_Model">.*'
  # {"FPS":60,"EnableVSync":false,"RenderScale":1.0,"ResolutionQuality":3,"ShadowQuality":3,"LightQuality":3,"CharacterQuality":3,"EnvDetailQuality":2,"ReflectionQuality":2,"SFXQuality":2,"BloomQuality":1,"AAMode":0,"EnableMetalFXSU":false}
  b='%7B%22FPS%22%3A60%2C%22EnableVSync%22%3Afalse%2C%22RenderScale%22%3A1.0%2C%22ResolutionQuality%22%3A3%2C%22ShadowQuality%22%3A3%2C%22LightQuality%22%3A3%2C%22CharacterQuality%22%3A3%2C%22EnvDetailQuality%22%3A2%2C%22ReflectionQuality%22%3A2%2C%22SFXQuality%22%3A2%2C%22BloomQuality%22%3A1%2C%22AAMode%22%3A0%2C%22EnableMetalFXSU%22%3Afalse%7D'
  for game in com.miHoYo.hkrpg com.miHoYo.hkrpg.bilibili com.HoYoverse.hkrpgoversea
  do
    xml=/data/data/$game/shared_prefs/$game.v2.playerprefs.xml
    if [ -f $xml ]; then
      sed -i "s/$a/GraphicsSettings_Model\">$b<\/string>/" $xml
      restorecon -DF $xml
    fi
  done
}

# ys_graphics_mod key[0~18] value[1~N]
ys_graphics_mod() {
  local key=$1
  local value=$2
  local value_i=$3
  for ys in com.miHoYo.Yuanshen com.miHoYo.ys.mi com.miHoYo.ys.bilibili com.miHoYo.GenshinImpact
  do
    xml=/data/data/$ys/shared_prefs/$ys.v2.playerprefs.xml
    if [ -f $xml ]; then
      a="%7B%5C%22key%5C%22%3A${key}%2C%5C%22value%5C%22%3A[0-9]%7D" # '{\\"key\\":${key},\\"value\\":[0-9]}'
      b="%7B%5C%22key%5C%22%3A${key}%2C%5C%22value%5C%22%3A${value}%7D" # '{\\"key\\":${key},\\"value\\":${value}}'
      c="entryType%5C%22%3A${key}%2C%5C%22index%5C%22%3A[0-9]%2C%5C%22" # 'entryType\\":${key},\\"index\\":[0-9],\\"'
      d="entryType%5C%22%3A${key}%2C%5C%22index%5C%22%3A${value_i}%2C%5C%22" # 'entryType\\":${key},\\"index\\":${value},\\"'
      sed "s/$a/$b/" $xml | sed "s/$c/$d/" > $xml
      restorecon -DF $xml
      echo $ys graphicsData $key to $value
      echo $ys graphicsPerfData $key to $value_i
    fi
  done
}
ys_graphics_presets() {
  for ys in com.miHoYo.Yuanshen com.miHoYo.ys.mi com.miHoYo.ys.bilibili com.miHoYo.GenshinImpact
  do
    xml=/data/data/$ys/shared_prefs/$ys.v2.playerprefs.xml
    if [ -f $xml ]; then
      a='graphicsData.*volatileVersion'
      b='graphicsData%22%3A%22%7B%5C%22currentVolatielGrade%5C%22%3A-1%2C%5C%22customVolatileGrades%5C%22%3A%5B%7B%5C%22key%5C%22%3A1%2C%5C%22value%5C%22%3A3%7D%2C%7B%5C%22key%5C%22%3A2%2C%5C%22value%5C%22%3A4%7D%2C%7B%5C%22key%5C%22%3A3%2C%5C%22value%5C%22%3A3%7D%2C%7B%5C%22key%5C%22%3A4%2C%5C%22value%5C%22%3A3%7D%2C%7B%5C%22key%5C%22%3A5%2C%5C%22value%5C%22%3A4%7D%2C%7B%5C%22key%5C%22%3A6%2C%5C%22value%5C%22%3A3%7D%2C%7B%5C%22key%5C%22%3A7%2C%5C%22value%5C%22%3A0%7D%2C%7B%5C%22key%5C%22%3A8%2C%5C%22value%5C%22%3A1%7D%2C%7B%5C%22key%5C%22%3A9%2C%5C%22value%5C%22%3A0%7D%2C%7B%5C%22key%5C%22%3A10%2C%5C%22value%5C%22%3A0%7D%2C%7B%5C%22key%5C%22%3A11%2C%5C%22value%5C%22%3A1%7D%2C%7B%5C%22key%5C%22%3A12%2C%5C%22value%5C%22%3A2%7D%2C%7B%5C%22key%5C%22%3A13%2C%5C%22value%5C%22%3A1%7D%2C%7B%5C%22key%5C%22%3A16%2C%5C%22value%5C%22%3A1%7D%2C%7B%5C%22key%5C%22%3A15%2C%5C%22value%5C%22%3A0%7D%5D%2C%5C%22volatileVersion'
      c='saveItems.*truePortedFromGraphicData'
      d='saveItems%5C%22%3A%5B%7B%5C%22entryType%5C%22%3A18%2C%5C%22index%5C%22%3A4%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%2C%7B%5C%22entryType%5C%22%3A1%2C%5C%22index%5C%22%3A2%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%2C%7B%5C%22entryType%5C%22%3A6%2C%5C%22index%5C%22%3A2%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%2C%7B%5C%22entryType%5C%22%3A8%2C%5C%22index%5C%22%3A0%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%2C%7B%5C%22entryType%5C%22%3A11%2C%5C%22index%5C%22%3A0%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%2C%7B%5C%22entryType%5C%22%3A13%2C%5C%22index%5C%22%3A0%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%2C%7B%5C%22entryType%5C%22%3A4%2C%5C%22index%5C%22%3A2%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%2C%7B%5C%22entryType%5C%22%3A12%2C%5C%22index%5C%22%3A1%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%2C%7B%5C%22entryType%5C%22%3A16%2C%5C%22index%5C%22%3A0%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%2C%7B%5C%22entryType%5C%22%3A3%2C%5C%22index%5C%22%3A2%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%2C%7B%5C%22entryType%5C%22%3A2%2C%5C%22index%5C%22%3A3%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%2C%7B%5C%22entryType%5C%22%3A5%2C%5C%22index%5C%22%3A3%2C%5C%22itemVersion%5C%22%3A%5C%22CNRELAndroid4.5.0%5C%22%7D%5D%2C%5C%22truePortedFromGraphicData'
      
      cat $xml | sed "s/$a/$b/" | sed "s/$c/$d/" > $xml.scene
      cat $xml.scene > $xml
      cat $xml.scene > $xml
      # own=$(ls -l /data/data/$ys/shared_prefs/${ys}_preferences.xml | awk '{ print $3}')
      # chown $own:$own $xml.scene
      # restorecon -DF $xml.scene
      # mount --bind $xml.scene $xml
      restorecon -DF $xml
      echo $ys 'graphicsData applied!'
      echo $ys 'graphicsPerfData applied!'
    fi
  done
}

speed_mobile_presets
hkrpg_presets
ys_graphics_presets

# ys_graphics_mod 18 5 4 # 画质 - 自定义
# ys_graphics_mod 6 2 1 # 场景质量 - 低
# ys_graphics_mod 1 3 2 # 帧率 - 60
