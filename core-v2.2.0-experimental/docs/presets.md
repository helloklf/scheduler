### 预设 `@preset`
- 如果有需要重复使用的公共设定，那么通过预设引用将会非常方便
- 例如，这是一段不使用预设的原始配置：

```json
{
  "alias": {
    "cpufreq": "/proc/cpudvfs/cpufreq_debug"
  },
  "schemes": {
    "powersave": {
      "call": [
        ["$cpufreq", "0 450000 2000000"],
        ["$cpufreq", "4 200000 2850000"],
        ["$cpufreq", "7 500000 2850000"],
        ["@uclamp", "0.00~max", "0.00~max", "0.1~max"],
        ["@cpuset", "2-3", "0-4", "0-6", "0-7"]
      ]
    },
    "balance": {
      "call": [
        ["$cpufreq", "0 450000 2000000"],
        ["$cpufreq", "4 200000 2850000"],
        ["$cpufreq", "7 500000 2850000"],
        ["@uclamp", "0.00~max", "0.00~max", "0.1~max"],
        ["@cpuset", "0-3", "0-4", "0-6", "0-7"]
      ]
    },
  }
}
```

- 这里有非常多的重复代码。如果使用预设，则可以简化为：


```json
{
  "alias": {
    "cpufreq": "/proc/cpudvfs/cpufreq_debug"
  },
  "presets": {
    "set_001": [
      ["$cpufreq", "0 450000 2000000"],
      ["$cpufreq", "4 200000 2850000"],
      ["$cpufreq", "7 500000 2850000"],
      ["@uclamp", "0.00~max", "0.00~max", "0.1~max"]
    ]
  },
  "schemes": {
    "powersave": {
      "call": [
        ["@preset", "set_001"],
        ["@cpuset", "2-3", "0-4", "0-6", "0-7"]
      ]
    },
    "balance": {
      "call": [
        ["@preset", "set_001"],
        ["@cpuset", "0-3", "0-4", "0-6", "0-7"]
      ]
    },
  }
}
```

- `@preset`函数还支持一次性使用多个预设，格式像是 `["@preset", "set_001", "set_001"...]` 这样




### 替换值 `@values`
- 它是增强版的`@preset`，允许在使用预设时再传入值，这样就可以实现像是自定义函数的效果
- 但它不支持指定多个预设，从参数3开始会被解析为要传给(参数2指定)预设的值，
- 像是这样 `["@values", "set_001", "value_001", "value_002"...]`

```json
{
  "presets": {
    "min_freq": [
      ["/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"],
      ["/sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq"],
      ["/sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq"]
    ],
    "max_freq": [
      ["/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq", "1600000"],
      ["/sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq", "2100000"],
      ["/sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq", "2300000"]
    ],
  },
  "schemes": {
    "powersave": {
      "call": [
        ["@values", "min_freq", "300000", "500000", "500000"],
        ["@values", "max_freq", "1500000", "1800000", "1800000"]
      ]
    },
    "powersave": {
      "call": [
        ["@values", "min_freq", "400000", "700000", "700000"],
        ["@values", "max_freq"]
      ]
    },
    "performance": {
      "call": [
        ["@values", "min_freq", "500000", "900009", "1100000"],
        ["@values", "max_freq", "1800000", "2400000", "2800000"]
      ]
    }
  }
}
```

