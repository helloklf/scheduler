## 线程CPU核心配置 `cpuset`
- 你可能听说过，绝大多数书Unity游戏，都有个叫`UnityMain`的线程CPU占用极高
- 大多数情况下，内核会根据实际负载需要决定要不要将任务迁移到`Big`核心
- 但不排除有些时候，系统会为了节省电力故意降低调用`Big`核心的积极性
- 对于这种情况，我们可能会手动改变线程的放置来提高游戏流畅性
- 阅读下面的示例，就能基本了解配置格式了

```json
{
  "friendly": "原神",
  "packages": ["com.miHoYo.Yuanshen"],
  "cpuset": {
    "repeat": 0,
    "interval": 5000,
    "unity_main": "7",
    "heavy_thread": "7",
    "heavy_cores": "4-6",
    "comm": {
      "4-6": ["UnityMultiRende", "mali-cmar-backe"],
      "0-3": ["Worker Thread", "AudioTrack", "Audio"]
    },
    "other": "0-6"
  }
}
```

- `other` 配置是可选的，为空或不配置时将略过名称未出现在`comm`配置中的线程
- `unity_main` 配置也是可选的，用于指定UnityMain线程可以使用的cpu核心。如果进程中存在多个UnityMain线程，则只会命中负载最高的那一个。
- `heavy_thread` 配置也是可选的，需与heavy_thread配合使用，用于指定重负载线程的名称。如果进程中存在多个同名线程，则只会命中负载最高的那一个。
- `heavy_cores` 需与heavy_thread配合使用，用于指定重负载线程可以使用的cpu核心。
- `repeat` 是重复检查线程亲和设置的最大次数，配置为`0`表示无限次，默认为`0`
- `interval` 是线程亲和设置检查时间间隔，最小值为`50` 默认值为`5000`，单位是毫秒

> 需要注意的是，如果用户安装了`AsoulOpt`，那`cpuset`配置将不会生效
