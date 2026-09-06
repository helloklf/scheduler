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
    ```json
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

- 可恢复性，你需要通过便于恢复的方式配置性能调节
    ```json
    // ✅ boost本身具有属性备份机制，使用路径直写是良好的配置方式，框架可自动恢复
    "gesture_boost": {
      "enable": true,
      "enter": [
        ["/proc/sys/walt/sched_boost", "1"],
        ["/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq", "^2112000"],
        ["/sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq", "^2880000"]
      ],
      "exit": []
    }
    // ❌ 通过@函数修属性，会让变化难以追溯，boost结束时无法自动恢复原来的设定
    "gesture_boost": {
      "enable": true,
      "enter": [
        ["/proc/sys/walt/sched_boost", "1"],
        ["@cpu_freq_min", "^2112000", "^2880000"]
      ],
      "exit": [
        // 由于无法自动恢复，你需要自行声明如何结束boost
        ["@cpu_freq_min", "384000", "768000"]
      ]
    }
    // ✅ 但支持 $路径别名（@preset 和 @values 也可以使用，因为会自动展开为路径直写）
    "gesture_boost": {
      "enable": true,
      "enter": [
        ["$sched_boost", "1"],
        ["$cpu_min_0", "^2112000"],
        ["$cpu_min_6", "^2880000"]
      ],
      "exit": []
    }
    ```

> 其它情形
- SCENE的辅助调速器已针对手势Boost做出优化，也就是用户触发手势时，Scene会自行临时提高余量以确保动画流畅运行
- SCENE FAS运行期间因为停止检测输入，gesture_boost 完全不生效，这是处于能耗和性能开销考虑的设定
