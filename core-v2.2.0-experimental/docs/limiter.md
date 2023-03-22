### 辅助调速器
- SCENE提供了辅助调速器来帮助控制CPU余量，用于解决使用内核/系统自带的调速器在特定场景下过于激进或过于保守
- 如果有需要，可以选择使用它。


### 基本配置
- Limiter 的基础配置位于在 `features`， 但它并不是必须

```json
{
  "platform": "taro",
  "platform_name": "8+GEN1",
  "framework": 220,
  "features": {
    "limiter": {
      "active_interval": 24,
      "gaming_interval": 30,
      "inactive_interval": 150,
      "logger": false,
      "params": [
        { "id": "p1:cpu0", "step_shift": -1, "max_freq": 1555200, "min_freq": 691200, "margin_mhz": 250 },
        { "id": "p1:cpu4", "step_shift": -0.7, "max_freq": 2112000, "min_freq": 768000, "margin_mhz": 270 },
        { "id": "p1:cpu7", "step_shift": -0.2, "max_freq": 2246400, "min_freq": 1171200, "margin_mhz": 250 },

        { "id": "idle:cpu0", "max_freq": 1440000, "margin_mhz": 70 },
        { "id": "idle:cpu4", "max_freq": 1555200, "margin_mhz": 70 },
        { "id": "idle:cpu7", "max_freq": 1536000, "margin_mhz": 80 }
      ]
    }
  },
}
```

