### 辅助调速器
- SCENE提供了辅助调速器来帮助控制CPU余量，用于解决使用内核/系统自带的调速器在特定场景下过于激进或过于保守
- 如果有需要，可以选择使用它。


### 基本配置
- Limiter 的基础配置位于在 `features`， 但它并不是必须

```json
{
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
  "schemes": {
    "powersave": {
      "call": [
        ["@limiters", "p1:cpu0", "p1:cpu4", "p1:cpu7"]
      ]
    }
  }
}
```

> 这里3个interval是指不同状态下轮询CPU负载的间隔时长(ms)
- active_interval 交互状态(指最近发生了应用切换或用户操作了手机)下的【CPU负载轮询间隔】，默认24
- gaming_interval 游戏类应用交互状态下的【CPU负载轮询间隔】默认， 30
- inactive_interval 非交互状态下的【CPU负载轮询间隔】，默认 150

> 下面的 `params` 则是添加了6条`limiter`执行策略
- 留意ID格式，例如：`p1:cpu0` 的 `:`后其实一个 `clusterExpr`，说明可以在[基础](./basic.md)章节找到

> 通过 `@limiters` 就可以使用已添加的执行策略
- 调用`@limiters`时会先移除已经启用的限速器，再添加指定的限速器


### 工作模式
- limiter 默认执行策略是`upper`，即根据指定的频率和余量，动态调整CPU频率上限(`scaling_max_freq`)
- limiter 还有多种工作模式，具体如下：

| mode | 描述 |
| :- | :- |
| upper | 根据负载和余量调整频率上限，频率写入`scaling_max_freq` |
| bottom | 根据负载和余量调整频率下限，频率写入`scaling_min_freq` |
| range | 根据负载调整频率上下限，上限同`upper`，下限为`(当前频率×负载)` + `(margin÷2)` |
| performance | 将CPU调速器更改为performance，并以upper模式继续工作 |
| powersave | 将CPU调速器更改为powersave，并以bottom模式继续工作 |


### 完整配置

| 参数 | 含义 | 类型 |
| :- | :- | :-: |
| id | 格式为`**:[clusterExpr]`，必须在整套配置里保持不重名 | string |
| mode | 工作模式 | string |
| step_shift | 连续升频时的跳频力度微调，范围 `-1 ~ 1` | float |
| max_freq | 最高频率限制，0或不配置为不限制 | int |
| min_freq | 最低频率限制，0或不配置为不限制 | int |
| margin_mhz | 固定的余量 | int |
| perfect_freq | 能效/功耗最佳平衡频率，默认是CPU支持的最高频率×0.8 | int |
| smoothness | 频率平滑度，默认`4`，最小为`1` | int |
| margin_ratio | 余量比例，`0 ~ 1` | float |


#### 连续升频
- 使用Limiter通常是为了减少CPU余量降低功耗
- 因此经常把`margin`设置的非常小，这导致升频变得非常谨慎和缓慢
- 为了解决这个问题，limiter在连续的上调频率时，会不断加大升频幅度
- 如果频率低于`perfect_freq`，跳频策略就会生效，这对减少卡顿非常有用
- step_shift 在跳频过程的大致作用，可以通过一段假代码来描述

  ```
  nextFreq = currentFreq * loadRatio + marginMHz
  scale = 1 + ((连续升频次数 / 0.1) * (1 + stepShift))
  if gaming {
    nextFreq = nextFreq * scale
  } else {
    nextFreq = nextFreq * scale * scale
  }
  ```

  > 建议
  - 从上面的代码就可以看出来，判定为`游戏`时跳频力度会有所收敛，
  - 这是因为游戏的负载通常趋于稳定，减少跳频可以有效降低功耗，
  - 有些游戏，甚至可以将`step_shift`设置为`-1`来完全禁止跳频
  - 但在平常多任务切换的使用中，限制跳频并且余量也很小的话就容易发生卡顿

#### 频率平滑度
- 有一种假设是，CPU在完成同样多计算任务时，使用相对稳定的中等频率，会比使用忽高忽低的频率更加节能
- 基于这种假设，Limiter刻意延缓了降频过程，使得CPU频率在游戏中更加平稳。
- 当`smoothness`设为4(默认是4)，则取前4个调速周期频率计算出`平均值`，
- 如果此时要降频，频率不能降到比`平均值`更低。这个策略对大多数游戏都是有益的。

#### 余量
- Limiter没有复杂的能效模型，也不会刻意限制使用更高的频率，因此余量的设置至关重要
- 但 max_margin_ratio 和 margin_mhz 有区别？ 

#### 百分比余量
- 假设，我们期望CPU负载达到70%时升频，所以margin_ratio应设为0.3，看看运算逻辑

  ```
  loadRatio = 0.8
  marginRatio = 0.3

  currentFreq = 700
  expectCycles = currentFreq * loadRatio      // 560
  nextFreq = expectCycles * (1 + marginRatio) // 728
  // nextFreq - expectCycles = 168，expectCycles ÷ nextFreq = 0.77

  currentFreq = 1200
  expectCycles = currentFreq * loadRatio      // 960
  nextFreq = expectCycles * (1 + marginRatio) // 1248
  // nextFreq - expectCycles = 288，expectCycles ÷ nextFreq = 0.77

  currentFreq = 2450
  expectCycles = currentFreq * loadRatio      // 1960
  nextFreq = expectCycles * (1 + marginRatio) // 2548
  // nextFreq - nextFreq = 588，expectCycles ÷ nextFreq = 0.77
  ```

  - 可以看出来，按比例设置余量并不科学，这会导致频率越高浪费的性能越多


#### 固定余量
- 现在换成通过margin_mhz设置余量，看看运算逻辑

  ```
  loadRatio = 0.8
  marginMHz = 288

  currentFreq = 700
  expectCycles = currentFreq * loadRatio      // 560
  nextFreq = expectCycles + marginMHz         // 848
  // expectCycles ÷ nextFreq = 0.66

  currentFreq = 1200
  expectCycles = currentFreq * loadRatio      // 960
  nextFreq = expectCycles + marginMHz         // 1248
  // expectCycles ÷ nextFreq = 0.77

  currentFreq = 2450
  expectCycles = currentFreq * loadRatio      // 1960
  nextFreq = expectCycles + marginMHz         // 2248
  // expectCycles ÷ nextFreq = 0.87
  ```

  - 可以看出来，通过margin_mhz设置固定余量，实际上会产生一个低频更激进高频更保守的效果
  - 这让没有能源模型的Limiter也有了少许的高频抑制效果
