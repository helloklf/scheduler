## Cpuset for App
- 它更适用于为普通应用，设置项更少，性能开销也更低。
- 它被设计为：
  > 将App中的线程分为 `主线程` `渲染线程` `其它线程`<br>
  > 用户触摸屏幕时，快速将线程迁移到指定核心，停止交互后恢复初始状态。<br>
  > 从而避免在非交互状态依然长期占用高性能核心增加额外功耗

### threads.json
- 支持通过`threads.json`人工指定线程使用哪些CPU核心
- 配置示例：

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
      "other": "0-6"
    }
  }
]
```