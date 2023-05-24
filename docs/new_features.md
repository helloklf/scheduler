## 新特新
- SCENE6并不局限于CPU/GPU性能的调度，还添加了一些拓展的特性来形成体验闭环


### 刷新率管理
- 此特性由用户在SCENE通过GUI进行配置，无需再方案配置中做任何预设


### 核心分配
> 过去，我们发现很多设备并不喜欢使用处理器的CPU7，这导致游戏性能下降或功耗增加<br>
> 我们曾经人工测试并预先配置线程放置，收效很好，但我们无法测试和配置所有游戏<br>
> 而`核心分配`是自动完成配置，尽管效果变差了，但工作量减少了，适用性提高了<br>
> 如果某个应用已经单独添加了[CPUSET配置，](./cpuset.md)`核心分配`就不会继续在那个应用里工作<br>
> 以及，关闭`核心分配`不会使[CPUSET配置](./cpuset.md)失效


- 此特性是否默认开启由`enable`参数决定
- 如果需要默认关闭并由用户决定是否开启，可设置 `enable_control` 参数
- `enable_control` 应当是个可以写入的路径，开启时写入`1`，关闭时写入`0`
- 例如

```json
{
    "features": {
        "high_rate": {
            "enable": false,
            "enable_control": "/data/local/tmp/scene_cpus_control"
        }
    }
}
```



### 充电控制
- 此特性默认启用，并允许用户在SCENE中主动关闭或微调温度阈值

> 游戏玩家们经常忘记充电或插上充电器玩，过快的充电速度产生导致设备升温变得卡顿<br>
> 为了实现极致的性能释放，我们需要适时停止充电，像是`旁路`供电那样<br>
> 充电控制会在处于`游戏中`，且电量高于`20%`，电池温度高于`41°C`时生效<br>
> 不过，SCENE无法保证该特性能兼容所有手机，因为厂家总是喜欢设计私有充电技术却不愿意暴露更多的参数<br>
> 如果你有自己的方法，也可以通过`suspend`和`normal`来指定`进入`和`退出`[旁路供电]时额外执行的修改<br>
> 例如


```json
{
    "features": {
        "charge_control": {
            "suspend": [
                ["/sys/class/power_supply/battery/charge_control_limit", "15"],
                ["/sys/class/power_supply/battery/night_charging", "1"]
            ],
            "normal": [
                ["/sys/class/power_supply/battery/charge_control_limit", "0"],
                ["/sys/class/power_supply/battery/night_charging", "0"]
            ]
        }
    }
}
```


### 手势BOOST
- 这里的手势主要是指从屏幕四个边缘，向屏幕中心进行的长距离滑动操作
- 在手机上，实现精致的120FPS过场动画，几乎需要和耗尽处理器全部性能
- 如果我们为了省电，把处理器余量调的很小或频率调的很低，就容易发生卡顿
- 利用手势BOOST，可以实现短时间的性能大幅提升，从而避免过场动画卡顿

- 例如


```
{
    "features": {
        "gesture_boost": {
            "enter": [
                ["/sys/kernel/ged/hal/custom_boost_gpu_freq", "24"],
                ["/sys/class/devfreq/mtk-dvfsrc-devfreq/userspace/set_freq", "4266000000"]
            ],
            "exit": [
                ["/sys/kernel/ged/hal/custom_boost_gpu_freq", "99"],
                ["/sys/class/devfreq/mtk-dvfsrc-devfreq/userspace/set_freq", "#0"]
            ]
        }
    }
}
```


> 调度矛盾
- 遗憾的是，在触发手势的同时，其它性能调节策略仍然处于运行状态
- 因此手势BOOST不可避免的会与之产生矛盾，这会让BOOST的效果变差
- 临时性的解决办法是在手势BOOST中，采用优先级更高的修改方式(当然，并不建议这么做)
- 例如

```js
高通可以用msm_performance
["/sys/module/msm_performance/parameters/cpu_min_freq", "0:1400000 4:1800000 7:2000000"]
["/sys/kernel/msm_performance/parameters/cpu_min_freq", "0:1400000 4:1800000 7:2000000"]

新款天玑(8000/9000等)可以用
["/proc/cpudvfs/cpufreq_debug", "0 1400000 2000000 |4 1800000 2850000|7 2000000 3050000"]
```

> 无需担忧的情形
- SCENE的辅助调速器已针对手势Boost做出优化，也就是用户触发手势时，Scene会自行临时提高余量以确保动画流畅运行