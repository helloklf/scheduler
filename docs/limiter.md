### 辅助调速器
- SCENE提供了辅助调速器来帮助控制CPU余量，用于解决使用内核/系统自带的调速器在特定场景下过于激进或过于保守
- 如果有需要，可以选择使用它。


### 基本配置
- Limiter 的基础配置位于在 `features`， 但它并不是必须

```json
{
  "features": {
    "limiter": {
      "logger": false,
      "params": [
        { "id": "p1:cpu0", "step": -1, "max": 1555200, "min": 691200, "margin": 250 },
        { "id": "p1:cpu4", "step": -0.7, "max": 2112000, "min": 768000, "margin": 270 },
        { "id": "p1:cpu7", "step": -0.2, "max": 2246400, "min": 1171200, "margin": 250 },

        { "id": "idle:cpu0", "max": 1440000, "margin": 70 },
        { "id": "idle:cpu4", "max": 1555200, "margin": 70 },
        { "id": "idle:cpu7", "max": 1536000, "margin": 80 }
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
| performance | 将CPU调速器更改为performance，并以upper模式继续工作 |


### 完整配置

| 参数 | 含义 | 类型 |
| :- | :- | :-: |
| id | 格式为`**:[clusterExpr]`，必须在整套配置里保持不重名 | string |
| mode | 工作模式 | string |
| step | 连续升频时的跳频力度微调，范围 `-1 ~ 1` | float |
| max | 最高频率限制(kHz)，0或不配置为不限制 | int |
| min | 最低频率限制(kHz)，0或不配置为不限制 | int |
| margin | 固定的余量(M Cycles) | int |
| target_margin | margin的增强版，支持按频率段设置余量 | string |
| perfect | 能效/功耗最佳平衡频率，默认是CPU支持的最高频率×0.8 | int |
| smoothness | 频率平滑度，默认`4`，最小为`1` | int |
| mt | 计算此cluster的负载时的多核负载权重, `0 ~ 100`，默认 `0` | int |
| excludes | 计算负载时排除的cpu核心，例如: [2, 3] | []int |
| prefer | 偏好，可配置为 0 或 3 , 配置为3时延缓负载降低后降频的速度 | int |


#### 连续升频
- 使用Limiter通常是为了减少CPU余量降低功耗
- 因此经常把`margin`设置的非常小，这导致升频变得非常谨慎和缓慢
- 为了解决这个问题，limiter在连续的上调频率时，会不断加大升频幅度
- 跳频机制只会在用户操作手机或运行游戏，且频率低于`perfect`时生效，这对减少卡顿非常有用
- `step`(**stepAdj**)参数在跳频过程的大致作用，可以通过一段假代码来描述

  ```
  nextFreq = currentFreq * loadRatio + margin
  scale = 1 + ((连续升频次数 / 0.1) * (1 + stepAdj))
  if gaming {
    nextFreq = nextFreq * scale
  } else {
    nextFreq = nextFreq * scale * scale
  }
  ```

  > 建议
  - 从上面的代码就可以看出来，判定为`游戏`时跳频力度会有所收敛，
  - 这是因为游戏的负载通常趋于稳定，减少跳频可以有效降低功耗，
  - 有些游戏，甚至可以将`step`设置为`-1`来完全禁止跳频
  - 但在平常多任务切换的使用中，限制跳频并且余量也很小的话就容易发生卡顿

#### 频率平滑度
- 有一种假设是，CPU在完成同样多计算任务时，使用相对稳定的中等频率，会比使用忽高忽低的频率更加节能
- 基于这种假设，Limiter刻意延缓了降频过程，使得CPU频率在游戏中更加平稳。
- 当`smoothness`设为4(默认是4)，则取前4个调速周期频率计算出`平均值`，
- 如果此时要降频，频率不能降到比`平均值`更低。这个策略对大多数游戏都是有益的。

#### 余量
- Limiter没有复杂的能效模型，也不会刻意限制使用更高的频率，因此余量的设置至关重要
- 同时，Limiter不支持百分比余量，而是使用了固定余量。这么做会有什么好处呢？

##### Limiter的固定余量
- 先来看看Limiter的固定余量运算逻辑

  ```
  loadRatio = 0.8
  margin = 288

  currentFreq = 700
  expectCycles = currentFreq * loadRatio      // 560
  nextFreq = expectCycles + margin            // 848
  // expectCycles ÷ nextFreq = 0.66

  currentFreq = 1200
  expectCycles = currentFreq * loadRatio      // 960
  nextFreq = expectCycles + margin            // 1248
  // expectCycles ÷ nextFreq = 0.77

  currentFreq = 2450
  expectCycles = currentFreq * loadRatio      // 1960
  nextFreq = expectCycles + margin            // 2248
  // expectCycles ÷ nextFreq = 0.87
  ```

  - 可以看出来，Limiter采用的固定余量，实际上会产生一个低频更激进高频更保守的效果
  - 这让没有能源模型的Limiter也有了少许的高频抑制效果



##### 百分比余量
- 作为对比，百分比余量会有什么缺点，为什么Limiter不采用呢？
- 假设，我们期望CPU负载达到70%时升频，所以marginRatio应该是0.3，看看运算逻辑

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

  - 可以看出来，按比例设置余量并不科学，这会导致频率越高CPU的空余性能越多



##### 目标余量
- Scene7.3 新增特性 `target_margin`，用于取代`margin`，支持设置不同频率下的余量
- 配置格式如：`400 2100000:300 2650000:200`
- 这个例子表示：
> CPU频率处于 `0 ~ 2100000KHz` 余量为400MHz <br>
> CPU频率处于 `2100000KHz ~ 2650000KHz` 余量为300MHz <br>
> CPU频率高于 `2650000KHz` 余量为200Mhz


#### 多核负载权重(Scene7.2+)
- 先说两个定义
  > stLoad = Single Thread Load = cluster的各个核心最高负载<br>
  > mtLoad = Multiple Thread Load = cluster的各个核心平均负载
- 正在情况下，辅助调速器会根据`stLoad`决定是否调整频率
- 当`mt`指定为非`0`数值时，则负载算法变为：
  > loadRatio = ( stLoad * (100 - mt) + mtLoad * mt ) / 100
- 因为`mt`数值越大，该cluster越不容易因为单个线程高负载升频
* 注意：非游戏场景的非交互状态下，用于cluster0的辅助调速器，默认`mt`为`100`，其它情况下均默认为`0`
* 不要在只有一颗核心的cluster上使用，以及确保设置`excludes`后参与负载计算的核心不少于两个


#### 排除核心(Scene7.2+)
- 有时候我们会故意把所有垃圾进程、线程集中在一颗核心，从而把更多的核心留给重要的进程、线程
- 但是，一颗核心承载大量任务，可能会导致该cluster持续高负载，设置更高的`mt`又不利于该`cluster`上的其它任务正常运行

- 你只将核心添加到 `excludes` 即可解决问题，典型搭配示例如：

  ```
  // 内核cpuset配置
  ["/dev/cpuset/background/cpus", "1"],
  ["/dev/cpuset/top-app/cpus", "0,2-7"]

  // 调速器
  {
    "id": "p1:cpu0", "margin": 300, "excludes": [1] }
  }
  ```