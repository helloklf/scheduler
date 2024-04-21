## 修改数值
- 在配置里最常用的操作就是修改指定路径的值，最基础的语法是：
- `["path", "value"]` 和 `["path", "#value"]` 两种，其中`#`代表写入值并设置文件为只读(`0444`)
- 看个例子：

```json
{
  "schemes": {
    "powersave": {
      "call": [
        ["/proc/sys/kernel/sched_boost", "#0"],
        ["/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq", "300000"],
        ["/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq", "1800000"]
      ]
    }
  }
}
```


## 内置函数
- Scene内置了一些常用的调度调节函数 (可以了解下，也不是必要的)
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
