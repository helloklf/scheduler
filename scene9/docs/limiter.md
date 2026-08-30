### 辅助调速器
- SCENE提供了辅助调速器来帮助控制CPU余量
- 用于解决使用内核/系统自带的调速器在特定场景下过于激进或过于保守
- 如果有需要，可以选择使用它


### 基本配置
- Limiter 的基础配置位于在 `features`， 但它并不是必须
- 一个简单的示例

```json
// profile.json
{
  "features": {

    "limiter": {
      "ddr_boost": true,
      "l3_boost": true,
      "params": {
        "p1": {
          // 工作模式，upper表示控制频率上限
          "mode": "upper",
          // 指定低负载时允许从哪些cluster关闭部分核心
          "core_ctl": [],
          // 这里有3条配置，分别对应处理器的3个cluster，实际数目应与硬件保持一致
          "cpus": [
            { "max": 1555200, "min": 691200, "margin": 250 },
            { "max": 2112000, "min": 768000, "margin": 270 },
            { "max": 2246400, "min": 1171200, "margin": 250 },
          ]
        },
        "p2": {
          "mode": "upper",
          // cpus 字段中包含的数据条数，必须与cpu的cluster数量一致，
          // 如果不需要控制某一cluster，则对应的cluster配置至少应保留一个null 
          "cpus": [
            null,
            { "max": 2450000, "min": 768000, "margin": 270 },
            { "max": 2850000, "min": 1171200, "margin": 250 },
          ]
        }
      }
    }

  },

  "schemes": {
    "powersave": {
      "call": [
        ["@limiter", "p1"]
      ]
    },
    "balance": {
      "call": [
        ["@limiter", "p2"]
      ]
    }
  }

}
```

- ddr_boost、l3_boost 是辅助调速器的附带功能，开启后会根据CPU频率适当提升ddr、l3频率，前提是设备硬件受支持
  > 主要用于改善游戏性能，避免ddr、l3升频不积极无法释放最佳性能
- core_ctl 用于指定低负载时允许从哪些cluster关闭部分核心，
  > 适合需要实现极限节能的场景，

  > 例如配置为[1,2]表示允许停用cluster 1, cluster 2的核心，

  > 在3 cluster的处理器中，对应中核、大核



### 工作模式
- limiter 默认执行策略是`upper`，即根据指定的频率和余量，动态调整CPU频率上限(`scaling_max_freq`)
- limiter 还有多种工作模式，具体如下：

| mode | 描述 |
| :- | :- |
| upper | 根据负载和余量调整频率上限，频率写入`scaling_max_freq` |
| bottom | 根据负载和余量调整频率下限，频率写入`scaling_min_freq` |
| performance | 将CPU调速器更改为performance，并以upper模式继续工作 |
| boost | 类似于bottom模式，但使用Hw Cycles统计负载 |


### 完整配置

| 参数 | 含义 | 类型 |
| :- | :- | :-: |
| mode | 工作模式，若不单独配置，默认跟随上级 | string |
| max | 最高频率限制(kHz)，0或不配置为不限制 | int |
| min | 最低频率限制(kHz)，0或不配置为不限制 | int |
| margin | 固定的余量(M Cycles) | int |
| margins | margin的增强版，支持按频率段设置余量 | string |
| perfect | 能效/功耗最佳平衡频率，默认是cluster支持的最高频率×0.8 | int |
| smoothness | 频率平滑度，默认`4`，最小为`1` | int |
| mt | 计算此cluster的负载时的多核负载权重, `0 ~ 100`，默认 `0` | int |
| excludes | 计算负载时排除的cpu核心，例如: `[2, 3]` | []int |
| prefer | 偏好，可配置为 `1`、`2`、`3`，默认`2` | int |


#### 频率平滑度
- 有一种假设是，CPU在完成同样多计算任务时，使用相对稳定的中等频率，会比使用忽高忽低的频率更加节能
- 基于这种假设，Limiter刻意延缓了降频过程，使得CPU频率在游戏中更加平稳。
- 当`smoothness`设为4(默认是4)，则取前4个调速周期频率计算出`平均值`，
- 如果此时要降频，频率不能降到比`平均值`更低。这个策略对大多数游戏都是有益的。

#### 偏好
- prefer需`smoothness`与配合使用
- prefer 为1 表示 省电，此时`smoothness`失效，没有降频延迟，根据实时负载直接降频。由于用户空间负载准确性较差，一般不建议使用此值，以免频率剧烈波动
- prefer 为2 表示 平衡，此时根据`smoothness`计算近期平均负载，如果实时负载低于近期平均负载，则使用近期平均负载决定频率
- prefer 为3 表示 性能，此时根据`smoothness`计算近期最高负载，如果实时负载低于近期最高负载，则使用近期最高负载决定频率

#### 余量
- Limiter没有复杂的能效模型，也不会刻意限制使用更高的频率，因此余量的设置至关重要
- 同时，Limiter不支持百分比余量，而是使用了固定余量。这么做会有什么好处呢？

##### Limiter的固定余量
- 先来看看Limiter的固定余量运算逻辑

  ```
  const loadRatio = 0.8
  const margin = 288

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
  const loadRatio = 0.8
  const marginRatio = 0.3

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
  // nextFreq - expectCycles = 588，expectCycles ÷ nextFreq = 0.77
  ```

  - 可以看出来，按比例设置余量并不科学，这会导致频率越高CPU的空余性能越多



##### 目标余量
- `margins`用于取代`margin`，支持分频段设置余量

  ```js
  { "max": 2850000, "margins": "400 2100000:300 2650000:200" }
  ```

  - 这个例子表示：
    > CPU频率处于 `0 ~ 2100000KHz` 余量为400MHz <br>
    > CPU频率处于 `2100000KHz ~ 2650000KHz` 余量为300MHz <br>
    > CPU频率高于 `2650000KHz` 余量为200Mhz


#### 多核负载权重
- 先说两个定义
  > stLoad = Single Thread Load = cluster的各个核心最高负载<br>
  > mtLoad = Multiple Thread Load = cluster的各个核心平均负载
- 正在情况下，辅助调速器会根据`stLoad`决定是否调整频率
- 当`mt`指定为非`0`数值时，则负载算法变为：
  > loadRatio = ( stLoad * (100 - mt) + mtLoad * mt ) / 100
- 因为`mt`数值越大，该cluster越不容易因为单个线程高负载升频
* 注意：非游戏场景的非交互状态下，用于cluster0的辅助调速器，默认`mt`为`100`，其它情况下均默认为`0`
* 不要在只有一颗核心的cluster上使用，以及确保设置`excludes`后参与负载计算的核心不少于两个


#### 排除核心
- 有时候我们会故意把所有垃圾进程、线程集中在一颗核心，从而把更多的核心留给重要的进程、线程
- 但是，一颗核心承载大量任务，可能会导致该cluster持续高负载，
- 但设置更高的`mt`又不利于该`cluster`上的其它任务正常运行

- 你只将核心添加到 `excludes` 即可解决问题，典型搭配示例如：

  ```js
  // 内核cpuset配置 确保后台进程只使用特定核心
  ["/dev/cpuset/background/cpus", "1"]

  // 调速器 计算负载时排除调专用于后提阿进程的核心
  { "max": 1800000, "margin": 300, "excludes": [1] }
  ```


#### 注意事项
- `mt` `core_ctl` `excludes` 组合使用可能导致负载计算变得非常困难
- 尤其是`core_ctl`应尽量避免和另外两个特性同时使用


### 启用辅助调速器
- 使用`@limiter`函数变更激活的辅助调速器
- 发生场景切换(切换应用)后，SCENE会自动停止已经开启的调速器
- 因此，配置中通常只需要考虑何时开启，而无需考虑为上一个场景停止辅助调速器
- 如果需要要在某些时候主动关闭所有辅助调速器，可以用 `["@limiter", "NONE"]`来完成

  ```json
  // 激活一个id为p1的辅助调速器分组
  ["@limiter", "p1"]
  // 关闭所有正在运行的辅助调速器
  ["@limiter", "NONE"]
  ```
