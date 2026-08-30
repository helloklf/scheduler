## 线程CPU核心配置 `cpuset`
- 你可能发现，绝大多数Unity游戏`UnityMain`线程CPU占用极高
- 正常情况下内核会根据实际负载需要决定要不要将任务迁移到`Big`核心
- 但有些系统会为了节省电力故意降低调用`Big`核心的积极性
- 针对这种情况，Scene实现了`核心分配`主动分析负载为线程分配合适的CPU核心


### threads.json
- 支持通过`threads.json`人工指定线程使用哪些CPU核心，替代核心分配的自动分配规则

#### 针对游戏
- 通过`cpuset: { ... }`配置适用于游戏的分配规则，示例：

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
| `ni` | 需要通过修改nice值提高优先级的线程 | string[] |
| `rr` | 需要修改调度模式为SCHED_RR的线程 | string[] | 



##### ni & rr *试验性的
- `ni`会为匹配到的线程设置nice值为`-10`，提高争夺CPU资源的能力
- `rr`设置线程调度模式为SCHED_RR，priority=1
  + SCHED_RR 在工作良好的情况下，能带来极致稳定的帧率
  + 但有时会导致游戏严重卡顿甚至卡死，需谨慎使用！
- 在配置 `rr` 或 `ni` 时，可以用特定名称`HeavyThread`命中`heavy_thread`匹配的最高负载线程
  - 如下方例子，`HeavyThread`实际会匹配到，名称为`UnityGfx**`或`Thread-**`的线程中负载最高者

  ```json
  {
    "friendly": "王者荣耀/LOLM",
    "packages": ["com.tencent.tmgp.sgame", "com.tencent.tmgp.sgamece", "com.garena.game.kgtw", "com.tencent.lolm"],
    "cpuset": {
      "rr": ["UnityMain", "HeavyThread", "CoreThread"],
      "ni": ["UnityMain", "HeavyThread", "CoreThread"],
      "unity_main": "7",
      "heavy_thread": "UnityGfx;Thread-",
      "heavy_cores": "6",
      "comm": {
        "4-7": ["UnityPreload", "IL2CPP", "btm_"],
        "4-5": ["CoreThread", "Apollo-", "NativeThread", "UnityChoreo", "Worker Thread", "Job.worker"]
      },
      "other": "0-5"
    }
  }
  ```


#### 针对一般应用
- `app_cpuset: { ... }`它更适用于为普通应用，设置项更少，性能开销也更低。
- 它的设计思路为：
  > 将App中的线程分为 `主线程` `渲染线程` `其它线程`<br>
  > 用户触摸屏幕时，快速将线程迁移到指定核心，停止交互后恢复初始状态<br>
  > 从而避免在非交互状态依然长期占用高性能核心增加额外功耗<br>

  ```json
  [
    {
      "friendly": "优先大核",
      "packages": [
        "com.tencent.mobileqq",
        "com.tencent.qqlive", "tv.danmaku.bili",
        "com.taobao.taobao", "com.jingdong.app.mall",
        "com.tencent.news", "com.sina.weibo",
        "com.netease.cloudmusic", "com.miui.player",
        "com.tencent.mm",
        "com.miui.notes",
        "com.sankuai.meituan"
      ],
      "app_cpuset": {
        "main": "7",
        "render": "4-6",
        "other": "0-6",
        "webview": false,
        "children": false
      }
    }
  ]
  ```

| 参数 | 解释 | 类型 |
| :- | :- | :-: |
| `main` | 主线程使用的核心| string |
| `render` | 渲染线程使用的核心 | string |
| `other` | 其它线程使用的核心 | string |
| `webview` | 是否检测webview沙盒进程中的渲染线程 | string |
| `children` | 是否检测子进程 | string |
