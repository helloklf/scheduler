### Scene FAS
- FAS是根据帧间隔(时间)和帧率的性能调节实现(仅适用于游戏)
- 在王者荣耀、和平精英等Unity引擎实现的游戏中能有效降低能耗
- 配置示例

  ```json
  {
    "friendly": "和平精英",
    "packages": ["com.tencent.tmgp.pubgmhd"],
    "modes": [
      {
        "mode": ["powersave"],
        "fas": {
          "freq": ["1900000", "1900000"]
        }
      },
      {
        "mode": ["balance"],
        "fas": {
          "freq": ["2100000", "2100000"]
        }
      }
    ]
  }
  ```

### 原理
- 其原理简单来说就是：游戏出现丢帧，提高频率。游戏过于流畅，降低频率
- 由于FAS本身并不计算CPU负载，无法知晓各cluster的实际工作状态
- 因此通常会采用大核中核同频，或保持某种规律同升同降
- 也就是说**大核中核同频或同升同降**只是FAS的**副作用**
- 并且，Scene提供了一些额外设定来缓解该副作用
- 因此，“通过FAS的副作用判断FAS是否生效”是不合理的做法
- **FAS并不总是能起正面作用，除非使用FAS以后出现以下表现**：
  1. CPU频率整体下降 <br>
  2. CPU平均利用率提高 <br>
  3. 帧率没有明显损失 <br>
  4. 功耗有明显降低 <br>

### 基本参数

  | 参数 | 解释 | 类型 |
  | :- | :- | -: |
  | governor | 与FAS配合使用的CPU调速器，walt、schedutil等 | string |
  | mode | 激进级别，可配置值见下文 | string |
  | freq | 默认的频率上限 | [String, String, String] |
  | _60 | 60帧下的频率上限 | [String, String, String] |
  | _90 | 90帧下的频率上限 | [String, String, String] |
  | _120 | 120帧下的频率上限 | [String, String, String] |
  | _144| 144帧下的频率上限 | [String, String, String] |
  | limiters | FAS不适用时的替代辅助调速器 | [String, ...] |

> **governor**: 有时，FAS配合performance调速器使用效果更佳

> **mode**: 默认会根据性能档位匹配不同的值，对应关系为：<br>

  |  |  |
  | :-: | :-: |
  | powersave | energy |
  | balance | normal |
  | performance | fps |
  | fast | fps |
  | pedestal | boost |

> _60/_90/... : 参数为 [BigMaxFreq, MiddleMaxFreq, MiddleOffset]，FAS默认采取大核中核同频策略，但有些时候大核中核所需的性能并不相同，同频策略会造成一些浪费。而MiddleOffset的作用就是，设定中核应该比大核的频率低(或高)多少个个级别

> limiters: 它是个容错配置，如果系统不兼容FAS或用户手动对该应用关闭了FAS，那么limiters指定的限速器就会被启用

- mode 可选值

  | 值 | 释义 |
  | :- | :- |
  | energy | 省电优先，允许更多卡顿 |
  | normal | 默认模式，能耗和帧率平衡 |
  | fps | 帧率优先，更少的丢帧 |
  | boost | 帧率优先，更少丢帧，降频更缓慢 |
  | feas | 如果FEAS可用则使用FEAS，否则使用FAS |
  | feas-only | 如果FEAS可用则使用FEAS，否则关闭FAS |
  | off | 对此应用的此模式禁用FAS |


### 进阶的参数

  | 参数 | 解释 | 类型 |
  | :- | :- | -: |
  | big_min_freq | 大核频率下限 | int |
  | middle_min_freq | 中核频率下限 | int |
  | fast_down_rate | 高频快速下调频率的速率 | float |
  | slow_down_rate | 低频慢速下调频率的速率 | float |
  | lower_freq | 较低频率 | int |
  | max_level | 最大帧率级别，如 `60` `90` `120` | int |
  | min_level | 最小帧率级别，如 `60` `90` `120` | int |

- 进阶的(已在Scene8FAS中废弃的参数)

  | 参数 | 解释 | 类型 |
  | :- | :- | -: |
  | middle_optimum_freq | 中核最佳频率 | int |
  | recent_frames | 用于计算平均“帧耗时”的帧数 | int |
  | thread_analyzer | 线程分析，根据线程负载调整中核与大核的频率差 | int |
  | perfect_load | 完美负载0~100 | float |


> **big_min_freq**, **middle_min_freq**: 大核、中核频率下限。适当提高频率下限有助于减少频率和帧率波动，用极少的功耗换更平稳的帧率

> **fast_down_rate**: 处于较高频率时的降频速率，默认为 `5 ~ 8` (取决于`mode`)。假设目标帧率为120，fast_down_rate为5，则需连续24帧(120/5)没有超时才降频

> **slow_down_rate**: 处于`较低频率`时的降频速率，默认为 `2 ~ 4` (取决于`mode`)。假如游戏目标帧率为120，slow_down_rate为2，则需连续60帧(120/2)没有超时才降频

> **lower_freq**: 处理器频率不高于此值时，[slow_down_rate] 生效，如果未指定该值则由SCENE自动计算。

> **middle_optimum_freq**: FAS默认会使中核大核保持频率相近，尽管有MiddleOffset可以使中核比大核频率低一些，但这又会使得大核频率较低时中核频率更低导致卡顿。 middle_optimum_freq 则是以另一种形式解决中核大核同频。在中核频率低于middle_optimum_freq时，中核跟随大核一起升频，中核频率达到middle_optimum_freq之后不再继续跟随大核升频。直到大核频率到达上限，或者与中核频率相差超过5级，中核才允许继续升频

> **max_level**, **min_level**: FAS的最大、最小目标帧率。FAS会自动根据游戏实际帧率，计算`目标帧率`并匹配设定的频率上限。如果没有利用FAS限制帧率的需求，不需要配置这两个参数

> **recent_frames**: FAS会根据临近几帧的平均[间隔时长]来判断游戏卡顿情况，默认为`6~8`帧。主要影响对卡顿的敏感程度，数值过大会迟钝，数值过小则会过激，值在`6 ~ 12`之间最佳

> **thread_analyzer** 设为true时，FAS将根据线程负载决定中核频率，而不是让中核与大核同步升降频率。启用该特性时MiddleOffset失效。

> **perfect_load** 可设置为0.5~1.0之间的值(表示50%~100%)。负载高于此值时不允许继续降低频率，如果此时需要提升频率，至少会提升至平均频率。
