## 过时的函数
- 由于过于复杂或不实用已经不推荐使用的内置函数

### 优先级 `@set_priority`
- 实际上，如果不是懒人，并不推荐使用这个函数，因为它有点笨重
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
> 是指分两次分别写入`0 1991000`和`1 2025000`
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
- `@lock_value` 的锁定效果与`@set_value`特殊用法的`#value`是相同的
- 并且`@lock_value`也支持对[value]增加特殊用法修饰符

