
### 高刷切换 `@high_rate`
- 通过 @high_rate "on"|"off"在高低刷新率之间切换
- 这对某些刷新率管理不完善的系统非常有用，但只建议在搭载LTPS OLED屏幕的设备上使用
- 但在使用该函数之前，你需要通过features按设备(device)配置高/低刷新率状态对应的DisplayModeID

```json
{
  "platform": "mt6895",
  "platform_name": "D8100",
  "framework": 220,
  "features": {
    "high_rate": {
      "enable": true,
      "enable_control": "/data/local/tmp/scene_refresh_rate",
      "device_policy": [
        { "device": "rubens", "enable": true, "mode_high_rate": "1", "mode_low_rate": "0" },
        { "device": "OP5565", "enable": true, "mode_high_rate": "1", "mode_low_rate": "0" }
      ]
    }
  }
}
```

- device 可以通过 `getprop ro.product.device` 获取
- mode_high_rate 高刷状态的DisplayModeID
- mode_low_rate 低刷状态的DisplayModeID
- enable_control 指定一个控制@high_rate函数启用状态的额外控制文件
    > enable_control 通常固定为 /data/local/tmp/scene_refresh_rate<br>
    > 如果指定了文件则必须向该文件写入1才能启用@high_rate函数


### 充电控制 `@charge_control`
- 通过 @charge "suspend"|"normal"切换两种模式
- 但该函数并未提供具体的实现，因此你需要在suspend和normal节点配置实际要进行的修改操作

```json
{
  "platform": "mt6895",
  "platform_name": "D8100",
  "framework": 220,
  "features": {
    "charge_control": {
      "enable": true,
      "enable_control": "/data/local/tmp/scene_charge_control",
      "suspend": [
        ["$charge_limit", "15"],
        ["$night_charging", "1"]
      ],
      "normal": [
        ["$charge_limit", "0"],
        ["$night_charging", "0"]
      ]
    }
  },
  "schemes": {
    "powersave": {
      "call": [
        ["@charge", "normal"]
      ]
    }
  }
}
```

- enable_control 指定一个控制@high_rate函数启用状态的额外控制文件
    > enable_control 通常固定为 /data/local/tmp/scene_charge_control<br>
    > 如果指定了文件则必须向该文件写入1才能启用@high_rate函数

