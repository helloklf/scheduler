### 刷新率管理
- 此特性由用户在SCENE通过GUI进行配置，无需在方案配置中做任何预设


### 核心分配
> 过去，我们发现很多设备不喜欢使用CPU7，导致游戏性能下降或功耗增加<br>
> 经人工测试并预先配置线程放置，效果很好，但这耗费的时间和精力太多了<br>
> 核心分配同时支持人工配置(threads.json)，和程序自动按线程负载分配处理器核心<br>
> Scene允许用户禁用此功能，禁用后threads.json和和程序自动分配均不再生效


### 旁路供电
> 游戏玩家们经常忘记充电或插上充电器玩，过快的充电速度产生导致设备升温变得卡顿<br>
> Scene在性能调节框架中集成了[旁路供电]，用户可以通过GUI设置开启<br>


### 手势BOOST
- 手势主要是指从屏幕四个边缘，向屏幕中心进行的长距离滑动操作
- 在手机上实现精致的120FPS过场动画，几乎需要和耗尽处理器全部性能
- 如果我们为了省电，把处理器余量调的很小或频率调的很低，就容易发生卡顿
- 利用手势BOOST，可以实现短时间的性能大幅提升，避免过场动画卡顿
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