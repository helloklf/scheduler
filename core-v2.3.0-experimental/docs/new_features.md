## 新特新
- SCENE6并不局限于CPU/GPU性能的调度，还添加了一些拓展的特性来形成体验闭环


### 刷新率管理
- 此特性是否默认开启由`enable`参数决定
- 如果需要默认关闭并由用户决定是否开启，可设置 `enable_control` 参数
- `enable_control` 应当是个可以写入的路径，开启时写入`1`，关闭时写入`0`
- 例如

```json
{
    "features": {
        "high_rate": {
            "enable": false,
            "enable_control": "/data/local/tmp/scene_refresh_rate"
        }
    }
}
```



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
> 游戏玩家们经常忘记充电或插上充电器玩，过快的充电速度产生导致设备升温变得卡顿<br>
> 为了实现极致的性能释放，我们需要适时停止充电，像是`旁路`充电那样<br>
> 充电控制会在处于`游戏中`，且电量高于`10%`，电池温度高于`40°C`时生效<br>
> 但SCENE只提供逻辑支持，并不实现具体的充电控制，因此需要自己配制`suspend`和`normal`


- 此特性是否默认开启由`enable`参数决定
- 如果需要默认关闭并由用户决定是否开启，可设置 `enable_control` 参数
- `enable_control` 应当是个可以写入的路径，开启时写入`1`，关闭时写入`0`
- 例如


```json
{
    "features": {
        "charge_control": {
            "enable": true,
            "enable_control": "/data/local/tmp/scene_charge_control",
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

