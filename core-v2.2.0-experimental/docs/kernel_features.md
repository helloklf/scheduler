## 内核特性
- 对于一些常用的内核参数修改，SCENE将其封装成了函数，如果有机会用到，可以稍微了解下
- 但事实上，你有更好的方式实现相同的目的，因此我不再喜欢这些难以利用的特性

### Utilization Clamping @uclamp
- uclamp作为schedtune的替代方案，在Linux Kernel中引入
- 因此，并非所有设备都能使用该特性
- @uclamp具有至多3个参数，用法非常简单
- 例如：
```json
["@uclamp", "0.00~max", "0.00~max", "0.00~max"]
```
- 3个参数分别对应cpuctl中background、foreground、top-app的cpu.uclamp.min和cpu.uclamp.max，两个值之间以 ~ 符号分隔

### 经典调速器 @classical
- 该函数用于降指定核心的调速器切换为`conservative`或相似的调速器，并设定相关参数
- 用法如：
```json
["@classical", "cpu0", "70", "60", "3", "1"]
```
- 5个参数分别代表 [CPU核心或丛集] [up_threshold] [down_threshold] [freq_step] [sampling_down_factor]
- 此处[CPU核心或丛集] 的表述方式与@cpufreq相同，支持 `cpu4` `policy4` `cluster1`这些格式
- 该函数会将conservative调速器的sampling_rate会统一设为8ms，ignore_nice_load 设为0
