### 辅助升频 `booster`
- booster在SCENE里实际上是`InputBooster`
- 当=用户触摸屏幕或按下按键，执行`enter` 在如果用户没有后续操作，在倒计时结束后执行`exit`
- 使用方法例如：

```json
{
  "booster": {
    "duration": 3000,
    "idle_delay": 5000,
    "enter": [
      ["@gpu_freq_min", "0.4GHz"]
      ["/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq", "951000"]
    ],
    "exit": [
      ["@gpu_freq_min", "0.2GHz"]
      ["/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq", "255000"]
    ]
  }
}
```

- [duration] 是boost持续时长，单位为毫秒
- [enter] 触发boost时执行的修改
- [exit] 结束boost时执行的修改
- [idle_delay] 用户切换应用(且之后没有操作设备)多长时间后主动执行`exit`，单位为毫秒
