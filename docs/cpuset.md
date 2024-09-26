## 线程CPU核心配置 `cpuset`
- 你可能发现，绝大多数Unity游戏`UnityMain`线程CPU占用极高
- 正常情况下内核会根据实际负载需要决定要不要将任务迁移到`Big`核心
- 但有些系统会为了节省电力故意降低调用`Big`核心的积极性
- 针对这种情况，Scene实现了`核心分配`主动分析负载为线程分配合适的CPU核心


### threads.json
- 支持通过`threads.json`人工指定线程使用哪些CPU核心
- 配置示例：

  ```json
  [
    {
      "friendly": "原神",
      "categories": ["GenshinImpact"],
      "cpuset": {
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
    },
    {
      "friendly": "王者荣耀",
      "packages": ["com.tencent.tmgp.sgame"],
      "cpuset": {
        "comm": {
          "7": ["UnityMain"],
          "6": ["UnityGfx", "UnityPreload", "Thread-"],
          "3-5": ["Worker Thread", "NativeThread", "Audio"]
        },
        "other": "0-6"
      }
    }
  ]
  ```

| 参数 | 解释 | 类型 |
| :- | :- | :-: |
| `unity_main` | UnityMain线程可以使用的cpu核心。如果进程中存在多个UnityMain线程，则只会命中负载最高的那一个。| string |
| `heavy_thread` | 用于指定重负载线程的名称。支持匹配多个线程名称，例如："Thread-;UnityGfx"。如果匹配到多个线程，则只会命中负载最高的那一个。 | string |
| `heavy_cores` | 需与heavy_thread配合使用，用于指定重负载线程可以使用的cpu核心 | string |
| `main_thread` | 指定运行主线程的cpu核心(通常，游戏的主线程都不是重负载线程) | string |
| `other` | 非 comm、unity_main、heavy_thead 命中的线程可使用的CPU核心 | string |
| `trashy` | 指定垃圾线程，本质上是通过cpuctl(cpu.uclamp.max)对线程进行限制，因此需要LinuxKernel 5+ | string[] |
