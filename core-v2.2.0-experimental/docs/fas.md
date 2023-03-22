### FAS/FEAS
- FAS 是SCENE6.1中添加的一项重要特性，基本原理是根据帧时间和帧率调节CPU频率，相比传统的调速器拥有更强的余量控制能力
- 遗憾的是，FAS并不是对所有游戏都适用，如果想在指定游戏指定模式启用FAS，可以像这样配置

```json
{
  "friendly": "和平精英",
  "packages": ["com.tencent.tmgp.pubgmhd"],
  "modes": [
    {
      "mode": ["powersave"],
      "fas": {
        "_60": ["1900000", "1900000"],
        "_90": ["1900000", "1900000"],
        "_120": ["1900000", "1900000"]
      }
    },
    {
      "mode": ["balance"],
      "fas": {
        "_60": ["2100000", "2100000"],
        "_90": ["2100000", "2100000"],
        "_120": ["2100000", "2100000"]
      }
    }
  ]
}
```

- 简单来说，使用FAS只需为不同帧率指定CPU频率上限即可，而其它参数则都是可选的
- 但是，你不能为普通APP设置FAS，只有在被SCENE识别为游戏的应用FAS配置才会起作用
- 下面再详细介绍下FAS的更多可选的配置参数


- 基本的

    | 参数 | 解释 | 类型 |
    | :- | :- | -: |
    | governor | FAS激活状态下使用的CPU调速器，可配置内核支持的调速器 | string |
    | mode | 激进级别，可配置值见下文 | string |
    | _60 | 60帧下的频率上限 | [String, String, String] |
    | _90 | 90帧下的频率上限 | [String, String, String] |
    | _120 | 120帧下的频率上限 | [String, String, String] |
    | _1444| 144帧下的频率上限 | [String, String, ...] |
    | limiters | FAS不适用时的替代辅助调速器 | [String, ...] |

> 详解

> governor: 通常来说，FAS配合performance调速器使用效果最佳，但如果FAS出错CPU频率会居高不下

> mode: 默认会根据当前档位匹配不同的值，对应关系为：<br>
> powersave->energy, balance->normal, performance->fps, fast->fps, pedestal->boost

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


- 进阶的

    | 参数 | 解释 | 类型 |
    | :- | :- | -: |
    | max_level | 最大帧率级别，可配置 `60` `90` `120` `144` | int |
    | min_level | 最小帧率级别，可配置 `60` `90` `120` `144` | int |
    | recent_frames | 用于计算平均“帧耗时”的帧数 | int |
    | big_min_freq | 大核频率下限 | int |
    | middle_min_freq | 中核频率下限 | int |
    | fast_down_rate | 高频快速下调频率的速率 | float |
    | slow_down_rate | 低频慢速下调频率的速率 | float |
    | middle_optimum_freq | 中核最佳频率 | int |


> 详解

> max_level, min_level: FAS会根据游戏实际帧率，计算`目标帧率`并匹配设定的频率上限<br>
> 如果FAS总是产生错误的判断，则可以通过这两个参数限制`目标帧率`范围。<br>
> 但它并不是设定FAS只在某个频率范围内才工作，而是让FAS认为游戏的帧数只会在某个范围<br>
> 例如：为只支持60帧的游戏设置max_level=60，当然了，这是个显得很多余的配置。

> recent_frames: FAS会根据临近几帧的平均[间隔时长]来判断游戏卡顿情况，默认为`6~8`帧<br>
> 主要影响对卡顿的敏感程度，数值过大会迟钝，数值过小则会过激，值在`6 ~ 12`之间最佳

> big_min_freq, middle_min_freq: 适当提高频率下限有助于减少频率和帧率波动，<br>
> 用极少的功耗换更平稳的帧率，有时候是值得的

> fast_down_rate: 处于较高频率时的降频速率，默认为 `5 ~ 8` 由 `mode` 决定<br>
> 假如游戏目标帧率为120，fast_down_rate为5，则需连续120/5=24帧都没有超时才会降频

> slow_down_rate: 处于较低频率时的降频速率，默认为 `2 ~ 4` 由 `mode` 决定<br>
> FAS认为的较低频率并非是某个固定的值，而是指接近或低于最近一段时间平均频率的频率<br>
> 加入游戏目标帧率为120，slow_down_rate为2，而最近一段时间平均频率为1200MHz，此时频率为1250MHz，则需连续120/2=60帧都没有超时才会继续降频<br>
> 事实上，基本没有哪个游戏可以保证完全不掉帧，所以 slow_down_rate 设置到 接近或低于 `1` 是非常鲁莽的

> middle_optimum_freq: FAS默认会使中核大核保持频率相近，尽管有MiddleOffset可以使中核比大核频率低一些，但这又会使得大核频率较低时中核频率更低导致卡顿。<br>
> middle_optimum_freq 则是以另一种形式解决中核大核同频。在中核频率低于middle_optimum_freq时，中核跟随大核一起升频，中核频率达到middle_optimum_freq之后不再继续跟随大核升频。<br>
> 直到大核频率到达上限，或者与中核频率相差超过5级，中核才允许继续升频