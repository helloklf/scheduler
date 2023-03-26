## 线程CPU核心配置 `cpuset`
- 它的作用与affinity类似，都是用于限制或指定线程使用的CPU核心
- 而区别在于cpuset模式具有更强的约束，用于对抗系统自身对affinity的修改
- 它的配置方式与affinity非常相似，
- 它使用类似于0-7的方式表示核心，而非像affinity一样使用16进制的mask

```json
{
  "friendly": "原神",
  "packages": ["com.miHoYo.Yuanshen"],
  "cpuset": {
    "repeat": 0,
    "interval": 5000,
    "comm": {
      "7": ["UnityMain"],
      "4-6": ["UnityGfxDevice", "UnityMultiRende", "mali-cmar-backe"],
      "0-3": ["Worker Thread", "AudioTrack", "Audio"]
    },
    "other": "0-6"
  }
}
```

- `other` 配置是可选的，为空或不配置时将略过名称未出现在`comm`配置中的线程
- `unity_main` 配置也是可选的，用于指定UnityMain线程可以使用的cpu核心。如果进程中存在多个UnityMain线程，则只会命中负载最高的那一个。
- `heavy_thread` 配置也是可选的，需与heavy_thread配合使用，用于指定重负载线程的名称。如果进程中存在多个同名线程，则只会命中负载最高的那一个。
- `heavy_mask` 需与heavy_thread配合使用，用于指定重负载线程可以使用的cpu核心。
- `repeat` 是重复检查线程亲和设置的最大次数，配置为`0`表示无限次，默认为0
- `interval` 是线程亲和设置检查时间间隔，最小值为`50` 默认值为`5000`，单位是毫秒

> 需要注意的是，如果用户安装了`AsoulOpt`，那`cpuset`配置将不会生效
