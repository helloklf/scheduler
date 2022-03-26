## 适用版本
- 本文档适用于Scene5.2.0 (framework版本号 `110` )

## 创建一个配置文件
- 在开始之前，你起码应该稍微了解JSON的格式规范
- 如下所示，这是一个空的配置文件
> `platform` 属性标识该配置用于`msm8998`平台，是必需的<br>
> **platformName** 是一个说明性属性，方便使用者理解**msm8998**是什么<br>
> `framework` 属性用于标注该配置适用的调度框架版本号<br>
> `schemes` 下则是对SCENE5中5个模式的配置

```json
{
  "platform": "msm8998",
  "platformName": "骁龙835",
  "framework": 110,
  "schemes": {
    "powersave": {
      "call": []
    },
    "balance": {
      "call": []
    },
    "performance": {
      "call": []
    },
    "fast": {
      "call": []
    },
    "pedestal": {
      "call": []
    }
  }
}
```

| KEY | NAME |
| :- | :- |
| powersave | 省电模式 |
| balance | 均衡模式 |
| performance | 性能模式 |
| fast | 极速模式 |
| pedestal | 底座模式 |



## 内置函数
- Scene内置了一些常用的调度调节函数
- 并对(Qualcomm|MediaTek)设备做了兼容适配

### CPU频率范围 **`@cpu_freq`**
- 参数格式为 **@cpu_freq [clusterExpr] [freqExpr] [freqExpr]**
- 例如，我准备在省电模式下将CPU小核限制为最高900Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@cpu_freq", "cpu0", "min", "900Mhz"]
      ]
    }
  }
}
```


#### CPU最小频率 **`@cpu_freq_min`**
- 参数格式为 **@cpu_freq_min [clusterExpr] [freqExpr]**
- 例如，我准备在省电模式下将CPU小核限制为最低300Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@cpu_freq_min", "cpu0", "300Mhz"]
      ]
    }
  }
}
```

#### CPU最大频率 **`@cpu_freq_max`**
- 参数格式为 **@cpu_freq_max [clusterExpr] [freqExpr]**
- 例如，我准备在省电模式下将CPU小核限制为最高900Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@cpu_freq_max", "cpu0", "900Mhz"]
      ]
    }
  }
}
```

#### 补充说明
- 频率范围冲突
  > 假设，CPU0此时已经被限制为 [600Mhz ~ 1.2Ghz]<br>
  > 我们调用 **`@cpu_freq_min` cpu0 1.5Ghz** 必然不会成功<br>
  > 因为 1.5Ghz 不符合 [600Mhz ~ 1.2Ghz]这个区间<br>
  > 建议使用 **`@cpu_freq` cpu0 1.5Ghz 2.0Ghz** 直接指定CPU频率范围

- clusterExpr说明
  > 我们修改CPU频率通常是以核心集群(Cluster)为单位进行的<br>
  > 例如，4+3+1的骁龙处理器，小、中、大核可以用以下几种格式来表示<br>
  > `cpu0`、`cpu4`、`cpu7`<br>
  > `policy0`、`policy4`、`policy7`<br>
  > `cluster0`、`cluster1`、`cluster2`<br>
  > 但是，千万不要用意义不明的数字来表示，例如 `0`、`4`、`7`，这是非常不利于理解

- freqExpr说明
  > 为了更方便的表示频率，Scene内置了多种格式兼容和特殊值<br>
  > 例：`min`、`max` 分别表示该核心(Cluster)支持的最小、最大频率<br>
  > 例：`1800Mhz`、`1.8Ghz` 均等同于 `1800000Khz` 或 直接写 `1800000`<br>
  > 如果你指定了一个不存在的频率，那么Scene会帮你选择低于指定频率的最大频率<br>
  > 又或者，指定的频率比核心支持的最高频率还要高，那么Scene会帮你选择支持的最高频率<br>
  > 又或者，指定的频率比核心支持的最低频率还低，那么Scene会帮你选择支持的最低频率<br>

  > 但是，小心！用`Ghz|Mhz`表示频率虽然非常方便，但你可能会掉进陷阱<br>
  > 因为CPU的频率经常不是 2.8Ghz(2800000Khz) 这样整齐的数字，更多是 2841600Khz这样<br>
  > 如果你写2.8Ghz，是不会匹配到2841600Khz这个频率的！<br>

  > 负值频率<br>
  > 这是Scene定义的一种表示频率的方式，它是指在 `max` 的基础上减去一个频率<br>
  > 例如 `-300Mhz`、`-0.3Ghz`、`-300000`<br>
  > 如果，小核最高频率为`1800Mhz`<br>
  > 那么 **`@cpu_freq` cpu0 -1200Mhz -300Mhz** 相当于 **`@cpu_freq` cpu0 600Mhz 1500Mhz**<br>
  > 如果，小核最高频率为`2000Mhz`<br>
  > 那么 **`@cpu_freq` cpu0 -1200Mhz -300Mhz** 相当于 **`@cpu_freq` cpu0 800Mhz 1700Mhz**

### GPU频率范围 `@gpu_freq`
- 参数格式为 **@gpu_freq [freqExpr] [freqExpr]**
- 例如，我准备在省电模式下将CPU小核限制为最高500Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@gpu_freq", "min", "500Mhz"]
      ]
    }
  }
}
```

#### GPU最小频率 **`@gpu_freq_min`**
- 参数格式为 **@gpu_freq_min [freqExpr]**
- 例如，我准备在极速模式下将GPU最低频率限制为400Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "fast": {
      "call": [
        ["@gpu_freq_min", "400Mhz"]
      ]
    }
  }
}
```

#### GPU最大频率 **`@gpu_freq_max`**
- 参数格式为 **@gpu_freq_max [freqExpr]**
- 例如，我准备在省电模式下将GPU最膏限制为最高300Mhz
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@gpu_freq_max", "400Mhz"]
      ]
    }
  }
}
```

#### 补充说明
- 频率范围冲突
  与CPU频率设置类似，不再赘述
- clusterExpr说明
  与CPU频率设置类似，不再赘述

### 刷新率 `@refresh_rate`
- 参数格式为 **@refresh_rate [60]**
- 例如，我准备在省电模式下将刷新率限制为60
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@refresh_rate", "60"]
      ]
    }
  }
}
```

#### 补充说明
- 近似刷新率档位
> 在可以的情况下，会优先匹配完全一致的刷新率档位<br>
> 在无完全匹配档位时，择优匹配近似档位，逻辑如下<br>

> 趋大（T >= 61 时，取高于T的最低一档）<br>
> 例  T=90，设备只支持 [60, 120, 144]<br>
>	   会命中 120

> 趋小（T < 61 时，取低于T的最高一档）<br>
> 例  T=48，设备只支持 [30, 45, 60, 90, 120]<br>
>	  会命中 45<br>

> 注：T 指目标刷新率refreshRate

> 防抖处理<br>
> 某些情况下，刷新率并非整数。例如某些设备的60Hz可能实际是60.5Hz或59.8Hz<br>
> Scene已经对这种情况做了容错处理，最高允许 ±2Hz 的刷新率误差

### 优先级 `@set_priority`
- 严格意义来说，这个参数改变的处理器的升降频、大小核迁移策略，而非进程抢占CPU资源的优先级
- 参数格式为 **@set_priority [group] [level]**
- `group` 可指定 `background`、`foreground`、`top-app`，或简写为 `bg`、`fg`、`top`
- `level` 按积极性分别为 `min`、`low`、`normal`、`high`、`max`、`turbo` 6个档
  > Scene会根据你指定的`level`自动调整 <br>
    **cpu.uclamp.min**、<br>
    **schedtune.boost**、<br>
    **cpuset**、<br>
    **sched_boost**、<br>
    **sched_upmigrate**、<br>
    **up_rate_limit_us**、<br>
    **schedtune.util.max** <br>
    等一系列参数(具体取决于内核支持情况)

- 例如，在性能模式下我们希望处理器尽可能积极点，同时限制后台进程的CPU占用
- 则可以像这样配置
```json
{
  "platform": "lahaina",
  "platformName": "骁龙888",
  "schemes": {
    "performance": {
      "call": [
        ["@set_priority", "top-app", "high"],
        ["@set_priority", "foreground", "normal"],
        ["@set_priority", "background", "low"]
      ]
    }
  }
}
```

- 又或者，极速模式下，我们想让处理器升频变的非常积极，同时让后台进程也可以比较正常的保持运行
- 则可以像这样配置
```json
{
  "platform": "lahaina",
  "platformName": "骁龙888",
  "schemes": {
    "performance": {
      "call": [
        ["@set_priority", "top-app", "max"],
        ["@set_priority", "foreground", "high"],
        ["@set_priority", "background", "normal"]
      ]
    }
  }
}
```

#### 补充说明
- 关乎处理器升降频积极性的全局参数，只会在调用 **`@set_priority` top-app [level]** 时修改
- `high`、`max`、`turbo` 均会提高处理器升频积极性和重负载任务向大核迁移的积极性
  > 注意：`turbo`级别会无条件的优先使用大核<br>
  > 优先使用大核，在负载不高的情况下，能显著提高流畅度和响应速度<br>
  > `但`在高帧率的游戏和大型游戏中，单核性能要求往往非常之高，<br>
  > 将过多的任务迁移至大核，可能会压垮本就负载极高的大核



### Realme GT模式 `@realme_gt`
- 参数格式为 **@realme_gt [on|off]**
- 例如，我准备在极速模式下自动开启GT模式
```json
{
  "platform": "msm8998",
  "schemes": {
    "fast": {
      "call": [
        ["@realme_gt", "on"]
      ]
    }
  }
}
```


### 设置值 `@set_value`
- 参数格式为 **@set_value [path] [value]**
- 例如，我准备在省电模式下向指定路径写入值(示例中为意图关闭CPU7)
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@set_value", "/sys/devices/system/cpu/cpu7/online", "0"]
      ]
    }
  }
}
```

#### 补充说明
> `@set_value` 函数的拓展用法非常复杂，如果你还没有遇到需要特殊用法的场景，可以先略过本节，继续阅读其它说明<br>
> 留意，所有特殊用法都是在 [value] 上加特殊标识符

- 特殊用法：多次写入 `|`符号
> 下面这个例子是我们通过PPM，修改MTK处理器频率<br>
> 是指分两次分别写入`0 1991000`和`"1 2025000`
```
"call": [
  ["@set_value", "/proc/ppm/policy/hard_userlimit_max_cpu_freq", "0 1991000|1 2025000"]
]
```

- 所有特殊用法

```
多个值 如 123|223|323
只调大 如 ^223 或 >223，说明：如属性当前值为 123, value指定^122 则不会执行写入，如果 value指定^124 会执行写入
只调小 如 <123，说明：如属性当前值为 123, value指定^124 则不会执行写入，如果 value指定^122 会执行写入
锁定值 如 #123，说明：向指定属性写入123，完成将属性改为只读状态
校验值 如 true(enabled:true)，说明：如果属性当前值 是 enabled:true，则不执行写入
模糊校验 如 true(~enabled:true)，说明：如果属性当前值 包含 enabled:true，则不执行写入
不校验 如 =123，表示跳过比对属性当前值，即使属性当前值与value相等，也会执行写入
			* 框架默认会有比对逻辑，value直接写 111 等同于 111(111),
			* 但是注意，value包含 | 符号时无法执行校验，例如 1500|1700|1899 等同于 =1500|=1700|=1899

values 特殊格式 标识符特殊用法
正确示例
#^223 只上调数值，并锁定数值
#^1600000(boost_cluster_0:1600000) 只上调数值，并锁定数值
0 1600000|1 1400000|#1 1400000 分别向属性写入 0 1600000, 1 1400000, 1 1400000, 并在完成后锁定

错误示例
^#223 锁定标识符(#)和其它标识符共同使用时，#必须永远放在最前面
```

### 锁定值 `@lock_value`
- 参数格式为 **@lock_value [path] [value]**
- 例如，我准备在省电模式下向指定路径写入值(示例中为意图关闭CPU7)，并在写入后将属性改为只读状态
```json
{
  "platform": "msm8998",
  "schemes": {
    "powersave": {
      "call": [
        ["@lock_value", "/sys/devices/system/cpu/cpu7/online", "0"]
      ]
    }
  }
}
```

#### 补充说明
- `@lock_value` 的锁定效果与`@set_value`特殊用法的`#[value]`是相同的
- 并且`@lock_value`也支持对[value]增加特殊用法修饰符


## 进阶(场景)
- 虽然基础的5个模式已经足够应对绝大多数场景
- 但如果能针对特定应用，做特定的优化，那不是更好吗？

- 举个例子：
```json
{
  "platform": "mt6893",
  "platformName": "D1200",
  "apps": [
    {
      "friendly": "原神",
      "scene": "Scene-For-YS",
      "packages": [
        "com.miHoYo.Yuanshen",
        "com.miHoYo.ys.mi",
        "com.miHoYo.ys.bilibili",
        "com.miHoYo.GenshinImpact"
      ],
      "call": []
    }
  ]
}
```

> 这个示例中，添加了一个没有执行任何特殊行为的场景<br>
> 其中[packages]指定该场景会命中哪些应用(写的包名)<br>
> 而[scene]属性的`Scene-For-YS`是一个自定义的场景ID<br>
> [friendly]是一个说明性属性，主要用于改善配置可读性<br>
> [call]中可以像前面配置5个模式一样，调用Scene内置函数

- 如果你需要定义一组场景配置，并适用于所有APP的话
- 那么 可以用 `"packages": ["*"]` 来实现通配，例：
```json
{
  "platform": "mt6893",
  "platformName": "D1200",
  "apps": [
    {
      "friendly": "通用",
      "scene": "Scene-For-Any",
      "packages": ["*"],
      "call": []
    }
  ]
}
```
- 不过，`场景`的匹配过程是自上而下进行的，所以你应当把通配的场景设定放在最后


### 传感器 `sensors`
- Scene实现录简单的数值监听。注意，是数值，也就是说监听的值必须是个数字！
- 它的作用是，定时轮询(读取)指定路径，并根据所得的值决定要修改什么参数

- 完整用法 如：
```json
{
  "friendly": "原神",
  "match": ["miHoYo"],
  "packages": [
    "com.miHoYo.Yuanshen",
    "com.miHoYo.ys.mi",
    "com.miHoYo.ys.bilibili",
    "com.miHoYo.GenshinImpact"
  ],
  "sensors": [
    {
      "sensor": "/sys/devices/platform/charger/power_supply/battery/capacity",
      "logger": false,
      "disable": false,
      "interval": 5000,
      "rules": [
        {
          "threshold": [-1, 15],
          "note": "[capacity] < MAX && [capacity] >= 15, Removing GPU restrictions",
          "enter": [
            ["/proc/mali/dvfs_enable", "1"],
            ["/proc/gpufreq/gpufreq_opp_freq", "0"]
          }
        },
        {
          "threshold": [16, -1],
          "note": "[capacity] < 16 && [capacity] >= MIN, GPU limited to 370Mhz",
          "enter": [
            ["/proc/mali/dvfs_enable", "0"],
            ["/proc/gpufreq/gpufreq_opp_freq", "370000"]
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

> threshold是个范围，由两个值组成，判断逻辑为 ＜ [value1] && >= [value2]，其中 `-1` 表示无限制<br>
> interval指轮询间隔，单位是毫秒<br>
> note是个注释属性，与运行逻辑无关<br>

- Sensor不支持[call]配置，也就是不能调用内置函数
- 这是因为，内置函数的逻辑非常复杂，很难实现值校验和恢复
- 因此，只用[set_value]意图会更加明确，过程也更加可控


### 自动退出 `stop_on`
- 场景配置中，`sensors`和`affinity`都有定时轮询机制
- 利用[stop_on]配置，可以让调度框架在不再需要时自动退出
- 完整用法 如：

```json
{
  "friendly": "原神",
  "match": ["miHoYo"],
  "packages": [
    "com.miHoYo.Yuanshen",
    "com.miHoYo.ys.mi",
    "com.miHoYo.ys.bilibili",
    "com.miHoYo.GenshinImpact"
  ],
  "stop_on": ["display", "leave", "scene"]
}
```

- stop_on有效值
> display 屏幕关闭后，自动停止当前scene-scheduler<br>
> scene   调度命中的场景改变后，自动停止当前scene-scheduler<br>
> leave   离开指定应用后，自动停止当前scene-scheduler<br>


### 特定场景下5个模式的微调
- 我们准备对`原神`做一些针对性调整，并应用于`powersave`和`balance`模式
- 示例如下：

```json
{
  "friendly": "原神",
  "match": ["miHoYo"],
  "packages": [
    "com.miHoYo.Yuanshen",
    "com.miHoYo.ys.mi",
    "com.miHoYo.ys.bilibili",
    "com.miHoYo.GenshinImpact"
  ],
  "modes": [
    {
      "mode": ["powersave", "balance"],
      "logger": false,
      "disable": false,
      "affinity": {
        "comm": {
          "80": ["UnityMain"],
          "70": ["UnityGfxDevice", "UnityMultiRende"],
          "F": ["Worker Thread", "AudioTrack", "Audio"]
        },
        "other": "7f"
      },
      "booster": {
        "events": ["touch", "buttons"],
        "duration": 2000,
        "enter": [],
        "exit": []
      }
    }
  ]
}
```

- mode 可以指定多个模式，但如果你想让这组配置匹配所有模式，可不用五个模式都写上去，你可以直接写["*"]
```json
{
  "modes": [
    {
      "mode": ["powersave", "balance"],
      "affinity": {
      }
    },
    {
      "mode": ["*"],
      "affinity": {
      }
    }
  ]
}
```

#### 线程CPU亲和 `affinity`
- 你可能听说过，绝大多数书Unity游戏，都有个叫`UnityMain`的线程CPU占用极高
- 大多数情况下，内核会根据实际负载需要决定要不要将任务迁移到`Big`核心
- 但不排除有些时候，系统会为了节省电力故意降低调用`Big`核心的积极性
- 对于这种情况，我们可能会手动改变线程的放置来提高游戏流畅性
- Scene提供的CPU亲和设置配置格式如下：

```json
"affinity": {
  "comm": {
    "80": ["UnityMain"],
    "70": ["UnityGfxDevice", "UnityMultiRende", "mali-cmar-backe"],
    "F": ["Worker Thread", "AudioTrack", "Audio"]
  },
  "other": "7f"
}
```

- 你没看懂上面这些 `80`、`70`、`F`、`7f` 是什么意思？
  > 这是一个16进制数，表示的是用哪些核心，比如<br>
  > 把`80`转成2进制，就是 `10000000`，8位数字，这下是否明白了呢？<br>
  > 把`70`转成2进制，就是 `1110000`，7位数，补1个0，补够8位即`01110000`<br>
  > 把`f`转成2进制，就是 `1111`，4位数，补4个0，补够8位即`00001111`<br>

- 想必这下你已经看明白了，它其实是用`0`和`1`来表示是否使用某个核心<br>
  > `80`即`10000000`，表示CPU7<br>
  > `70`即`01110000`，表示CPU6~4<br>
  > `f`即`00001111`，表示CPU3~0


#### 辅助升频 `booster`
- Scene提供了辅助升频，不过目前只实现了监听`InputDevice`作为触发条件(也就是增强版的触摸升频)
- 使用方法例如：

```json
{
  "booster": {
    "events": ["touch", "buttons", "qpnp_pon", "synaptics", "uinput-fpc", "gpio-keys"],
    "duration": 3000,
    "enter": [
      ["/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq", "951000"]
    ],
    "exit": [
      ["/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq", "255000"]
    ]
  }
}
```
- 配置格式一目了然，通过[events]指定设备触发升频的事件
> 其中 `touch`、`buttons` 是Scene预设的输入事件，分别相应代表触摸和按键按下<br>
> 某些时候，Scene可能会无法正确找到`touch`、`buttons`对应的输入设备<br>
> 因此，你还可以在[events]中指定具体输入设备名称，让Scene去监听它来响应输入升频
- [duration]是升频持续时长，单位为毫秒
- [enter]用于配置进入boost状态要执行的属性修改，支持像[Call]一样调用内置函数(但不建议使用)
- [exit]用于配置退出boost状态要执行的属性修改，支持像[Call]一样调用内置函数(但不建议使用)

##### 自动备份/恢复
- Scene在执行进入boost状态执行[enter]指定的修改前，
- 会尽量读取备份对应当前值，并在执行[exit]修改时自动恢复
-  不支持备份/恢复调用内置函数造成的修改
- 由于系统往往有自己的boost逻辑，Scene可能会备份到错误的值
- 因此，如果你愿意勤快点的话，建议保持[exit]与[enter]指定的属性对应

##### 使用函数
- [enter]和[exit]均支持像配置[call]一样，调用Scene内置函数
- 但调用内置函数框架不具备自动备份还原机制
- 因此如果你在[enter]里调用函数做了什么修改
- 务必[exit]中调用相同的函数来还原参数，例如：

```json
{
  "booster": {
    "events": ["touch", "buttons", "qpnp_pon", "synaptics", "uinput-fpc", "gpio-keys"],
    "duration": 3000,
    "enter": [
      ["@cpu_freq_min", "1.4Ghz"]
    ],
    "exit": [
      ["@cpu_freq_min", "300Mhz"]
    ]
  }
}
```


## 结尾
- 注意，文中所有示例代码，仅用于展示框架功能
