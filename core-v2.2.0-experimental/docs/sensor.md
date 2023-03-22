
### 传感器 `sensors`
- Scene实现录简单的数值监听。注意，是数值，也就是说监听的值必须是个数字
- 它的作用是，定时轮询(读取)某个文件或虚拟传感器，并根据所得的值决定要修改什么参数

- 完整用法 如：
```json
{
  "platform": "mt6893",
  "platform_name": "D1200",
  "schemes": {},
  "apps": [
    {
      "friendly": "原神",
      "packages": [
        "com.miHoYo.Yuanshen",
        "com.miHoYo.ys.mi",
        "com.miHoYo.ys.bilibili",
        "com.miHoYo.GenshinImpact"
      ],
      "sensors": [
        {
          "sensor": "/sys/devices/platform/charger/power_supply/battery/capacity",
          "interval": 5000,
          "props": [],
          "rules": [
            {
              "threshold": [-1, 15],
              "note": "[capacity] < MAX && [capacity] >= 15, Removing GPU restrictions",
              "enter_once" : [],
              "enter": [
                ["/proc/mali/dvfs_enable", "1"], ["/proc/gpufreq/gpufreq_opp_freq", "0"]
              ],
              "values": []
            },
            {
              "threshold": [16, -1],
              "note": "[capacity] < 16 && [capacity] >= MIN, GPU limited to 370MHz",
              "enter_once" : [],
              "enter": [
                ["/proc/mali/dvfs_enable", "0"], ["/proc/gpufreq/gpufreq_opp_freq", "370000"]
              ],
              "values": []
            }
          ]
        }
      ]
    }
  ]
}
```

> 这个示例说的是，每5秒读取一次电池电量百分比<br>
> 如果电量百分比 >= 15，恢复GPU频率<br>
> 如果电量百分比 < 16，限制GPU频率为370Mhz<br>

> sensor 可以是一个文件路径，或者一个在下文提到的虚拟传感器名称
> threshold是个范围，由两个值组成，判断逻辑为 ＜ [value1] && >= [value2]，其中 `-1` 表示无限制<br>
> interval指轮询间隔，单位是毫秒<br>
> enter 规则命中时执行的属性修改和函数调用，连续命中同一规则会重复执行<br>
> enter_once 规则命中时执行的属性修改和函数调用，连续命中同一规则时只会执行一次<br>
> note 是个注释属性，与运行逻辑无关<br>

#### sensor rule配置改进写法
- 大多数情况下，rule所做的事都是对同一属性进行修改
- 因此enter配置这种需要重复指定属性和值的做法略显啰嗦
- 因此它可以被简化为单独指定props，和不同rule下的values
- 例如，我想根据电池温度来改变处理器性能，可以这样写

```json
{
  "sensor": "/sys/class/power_supply/battery/temp",
  "interval": 2000,
  "props": ["$gpu_freq", "$ddr_freq_min", "$cpu_max_0", "$cpu_max_4", "$cpu_max_7"],
  "rules": [
    { "threshold": [ -1, 491], "values": ["3200000000", "1800000", "1700000", "1800000"] },
    { "threshold": [490, 471], "values": ["3200000000", "1800000", "1800000", "2000000"] },
    { "threshold": [470, 441], "values": ["4266000000", "1900000", "2000000", "2100000"] },
    { "threshold": [440,  -1], "values": ["4266000000", "2000000", "2150000", "2300000"] }
  ]
}
```

> props 是规则命中时将要修改的属性，与values对应，与enter和enter_once无关<br>
> values 与props对应的各个值<br>
> 并且 `enter` `enter_once` `values` 可以在同一规则里同时出现


#### 虚拟传感器
- 为了更方便的使用传感器，SCENE内置了一些虚拟传感器方便直接使用
- 这样就不用关系具体通过何种方式取得这些数值了，具体如下：

| 名称 | 描述 | 典型值 |
| :-: | :-: | :-: |
| cpu | CPU温度，有多个相关传感器时，自动取最大值 | 45000 ~ 95000 |
| gpu | GPU温度，有多个相关传感器时，自动取最大值 | 45000 ~ 95000 |
| soc | CPU 和 GPU 二者中的较大值 | 45000 ~ 95000 |
| fps | 近期屏幕画面刷新帧率(并不是当前游戏的帧率) | 0 ~ 144 |
| battery | 电池温度(°C) | 10 ~ 50 |
| capacity | 电池电量(%) | 1 ~ 100 |

- 这里有两个注意事项
- 1. SCENE不会对CPU&GPU温度进行除运算，例如 95.5°C 数值通常是 95500
- 2. 此处的fps不代表游戏帧率，例如：你在运行30帧游戏的同时，通过画中画播放60帧的视频，此时的fps的取值 >= 60

- 通常我们喜欢根据游戏的大概帧率来调整设备性能，就像这样：

```json
{
  "sensor": "fps",
  "interval": 2000,
  "props": ["$gpu_freq", "$ddr_freq_min", "$cpu_max_0", "$cpu_max_4", "$cpu_max_7"],
  "rules": [
    { "threshold": [-1,  100], "values": ["3200000000", "1800000", "1700000", "1800000"] },
    { "threshold": [100,  70], "values": ["3200000000", "1800000", "1800000", "2000000"] },
    { "threshold": [70,   -1], "values": ["4266000000", "1900000", "2000000", "2100000"] }
  ]
}
```