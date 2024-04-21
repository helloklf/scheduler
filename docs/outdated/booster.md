### 辅助升频 `booster`
- booster在SCENE里实际上是`InputBooster`

- 用户触摸屏幕或按下按键时，执行`enter`
- 用户一段时间(`duration`)没有操作手机后，执行`exit`
- 或切换应用一段时间(`idle_delay`)从未操作过手机，执行`exit`

- 配置示例：

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
