### 状态 `state`
- 指定在“交互:active”和“非交互:inactive”状态下的参数
- 以便实现兼顾操控体验和静置节能效果

- 配置示例：

```json
{
  "state": {
    "active": [
      ["@gpu_freq_min", "0.4GHz"]
      ["/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq", "951000"]
    ],
    "inactive": [
      ["@gpu_freq_min", "0.2GHz"]
      ["/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq", "255000"]
    ]
  }
}
```
