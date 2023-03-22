## 内置函数
- Scene内置了一些常用的调度调节函数
- 并对(Qualcomm|MediaTek)设备做了兼容适配

### CPU频率范围 **`@cpu_freq`**
- 参数格式为 **@cpu_freq [clusterExpr] [freqExpr] [freqExpr]**
- 例如，我准备在省电模式下将CPU小核限制为最高900Mhz
```json
{
  "schemes": {
    "powersave": {
      "call": [
        ["@cpu_freq", "cpu0", "min", "900MHz"]
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
  "schemes": {
    "powersave": {
      "call": [
        ["@cpu_freq_min", "cpu0", "300MHz"]
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
  "schemes": {
    "powersave": {
      "call": [
        ["@cpu_freq_max", "cpu0", "900MHz"]
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

  > 但是，小心！用`GHz|MHz`表示频率虽然非常方便，但你可能会掉进陷阱<br>
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
  "schemes": {
    "powersave": {
      "call": [
        ["@gpu_freq", "min", "500MHz"]
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
  "schemes": {
    "fast": {
      "call": [
        ["@gpu_freq_min", "400MHz"]
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
  "schemes": {
    "powersave": {
      "call": [
        ["@gpu_freq_max", "400MHz"]
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
  "platform_name": "骁龙888",
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
  "platform_name": "骁龙888",
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



### 设置值 `@set_value`
- 参数格式为 **@set_value [path] [value]**
- 例如，我准备在省电模式下向指定路径写入值(示例中为意图关闭CPU7)
```json
{
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

