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
  "call": [],
  "cpuset": {
    "interval": 5000,
    "unity_main": "7",
    "heavy_thread": "UnityGfx",
    "heavy_cores": "4-6",
    "comm": {
      "4-6": ["UnityMultiRende", "mali-cmar-backe"],
      "0-3": ["Worker Thread", "AudioTrack", "Audio"]
    },
    "trashy": ["Async"],
    "other": "0-6"
  }
}
```

- `other` 为空或不配置时将略过名称未出现在`comm`配置中的线程
- `unity_main` 用于指定UnityMain线程可以使用的cpu核心。如果进程中存在多个UnityMain线程，则只会命中负载最高的那一个。
- `heavy_thread` 用于指定重负载线程的名称。支持匹配多个线程名称，例如："Thread-,UnityGfx"。如果匹配到多个线程，则只会命中负载最高的那一个。
- `heavy_cores` 需与heavy_thread配合使用，用于指定重负载线程可以使用的cpu核心。
- `main_thread` Scene 7.2新增，用于指定运行主线程的cpu(更适用于一般应用，许多游戏的主线程都不是高负载线程)
- `interval` 是线程亲和设置检查时间间隔，最小值为`50` 默认值为`5000`，单位是毫秒
- `trashy` Scene 7.0.17新增，用于指定垃圾线程，本质上是通过cpuctl(cpu.uclamp.max)对线程进行限制，因此需要LinuxKernel 5+


## threads.json
- Scene允许单独创建一个`threads.json`文件来配置各个应用的线程放置
- 这降低了在不同处理器共用线程放置设定的难度
- 配置示例：

```json
[
  {
    "friendly": "原神",
    "categories": ["GenshinImpact"],
    "cpuset": {
      "comm": {
        "6-7": ["UnityMain"],
        "6": ["UnityGfx", "UnityMultiRende"],
        "0-5": ["Timer"]
      },
      "other": "0-5"
    }
  },
  {
    "friendly": "王者荣耀",
    "packages": ["com.tencent.tmgp.sgame"],
    "cpuset": {
      "comm": {
        "7": ["UnityMain"],
        "6": ["UnityGfx", "UnityPreload", "Thread-"],
        "3-5": ["Worker Thread", "NativeThread", "Audio", "NDK Media", "GVoice", "FMOD mixer", "FMOD stream", "ff_read"]
      },
      "other": "0-6"
    }
  }
]
```


## 高优先级任务
- `mvp_thread` 基于高通MVP实现，改变指定线程的优先级，仅支持Linux Kernel 5.15+的高通处理器机型
- 建议指定只需要运行在中核的线程，需要强制运行在超大核的线程不建议加入
- 并且，该特性不同设备下表现不同，并不总是能带来好的结果！
- 配置例如：
```json
{
  "friendly": "鸣潮",
  "packages": ["com.kurogame.mingchao", "com.kurogame.wutheringwaves.global"],
  "cpuset": {
    "mvp": ["RenderThread", "RHIThread"],
    "main_thread": "3-6",
    "comm": {
      "7": ["GameThread"],
      "3-6": ["TaskGraphHP", "NativeThread", "RenderThread", "AsyncLoading", "FChunk", "RHIThread"]
    },
    "other": "0-6"
  }
}
```

- `heavy_mvp`与`heavy_thread`配合使用，设置是否提高重负载线程的优先级
```
{
  "friendly": "王者荣耀",
  "packages": ["com.tencent.tmgp.sgame", "com.tencent.tmgp.sgamece"],
  "cpuset": {
    "unity_main": "7",
    "heavy_thread": "Thread-,UnityGfx",
    "heavy_cores": "3-6",
    "heavy_mvp": true,
    "comm": {
      "3-6": ["UnityPreload", "NativeThread", "CoreThread", "Worker Thread", "Apollo-"]
    },
    "other": "0-6"
  }
}
```
