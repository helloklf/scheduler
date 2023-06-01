## 类目

## 一级分类
- Scene将应用分为三个大类: `app`, `game`, `benchmark`
- 是否归类为游戏通过是否包含游戏引擎、是否横屏启动、是否集成游戏服务判定
- 一个应用是否属于游戏，将决定它是否可以开启FAS，是否使用游戏专用策略
- 而benchmark类则是根据内置包名识别判定，但Scene拒绝跑分优化，不提供此类目的配置


### 二级分类
- 除此以外，还会根据Scene携带的`categories.json`文件区分应用二级分类
- 该文件也可以添加到性能调节配置中，下载配置时将覆盖Scene携带的版本
- Scene携带的`categories.json` 文件大致如下

```json
[
  {
    "friendly": "抖音、西瓜、快手",
    "packages": [
      "com.ss.android.ugc.aweme",
      "com.ss.android.ugc.aweme.lite",
      "com.ss.android.article.video",
      "com.smile.gifmaker"
    ],
    "category": "ShortVideo"
  },
  {
    "friendly": "视频应用",
    "packages": [
      "tv.danmaku.bili", "com.bilibili.app.in",
      "com.google.android.youtube",
      "com.tencent.qqlive",
      "com.ss.android.article.video",
      "com.qiyi.video",
      "com.qiyi.video.lite",
      "com.qiyi.video.sdkplayer",
      "com.dianshijia.newlive",
      "com.duowan.kiwi",
      "air.tv.douyu.android",
      "com.douyu.rush",
      "com.youku.phone",
      "org.telegram.messenger",
      "com.hunantv.imgo.activity"
    ],
    "category": "Video"
  },
  {
    "friendly": "社交APP",
    "packages": [
      "com.tencent.mobileqq",
      "com.tencent.mm",
      "com.tencent.tim",
      "org.telegram.messenger"
    ],
    "category": "IM"
  },
  {
    "friendly": "音乐APP",
    "packages": [
      "com.netease.cloudmusic",
      "com.kugou.android",
      "com.kugou.android.lite"
    ],
    "category": "Music"
  },
  {
    "friendly": "小说阅读",
    "packages": [
      "io.legado.app.release",
      "com.duokan.reader",
      "com.ruguoapp.jike",
      "com.ruanmei.ithome"
    ],
    "category": "Reader"
  },
  {
    "friendly": "提高滑动性能",
    "packages": [
      "com.taobao.idlefish",
      "com.taobao.taobao",
      "com.android.browser",
      "com.baidu.tieba_mini",
      "com.baidu.tieba",
      "com.jingdong.app.mall",
      "com.tmall.wireless",
      "com.sankuai.meituan",
      "com.pupumall.customer",
      "com.eg.android.AlipayGphone",
      "com.android.vending",
      "cn.xiaochuankeji.tieba",
      "com.mfw.roadbook"
    ],
    "category": "ScrollOpt"
  },
  {
    "friendly": "极速响应",
    "packages": [
      "com.miui.home",
      "com.meizu.flyme.launcher",
      "net.oneplus.launcher",
      "com.oppo.launcher",
      "ch.deletescape.lawnchair.ci",
      "com.mi.android.globallauncher",
      "com.teslacoilsw.launcher",
      "com.android.quicksearchbox",
      "net.oneplus.h2launcher",
      "com.oneplus.hydrogen.launcher",
      "com.microsoft.launcher",
      "org.lineageos.trebuchet",
      "org.mokee.lawnchair",
      "com.google.android.apps.nexuslauncher",
      "ch.deletescape.lawnchair.plah",
      "com.android.launcher",
      "com.tencent.mm.plugin.appbrand.ui.AppBrandLauncherUI",
      "com.bbk.launcher2"
    ],
    "category": "Launcher"
  },
  {
    "friendly": "扫码",
    "packages": [
      "com.tencent.mm.plugin.scanner.ui.BaseScanUI",
      "com.tencent.mobileqq.olympic.activity.ScanTorchActivity",
      "com.tencent.mobileqq.olympic.activity.ScanTorchActivity",
      "com.alipay.mobile.scan.as.main.MainCaptureActivity",
      "com.jd.lib.scan.lib.zxing.client.android.CaptureActivity",
      "com.etao.feimagesearch.capture.CaptureActivity"
    ],
    "category": "Scanner"
  },
  {
    "friendly": "相机",
    "packages": [
      "com.tencent.mm.plugin.recordvideo.activity.MMRecordUI",
      "com.tencent.aelight.camera.aebase.QIMCameraCaptureActivity",
      "dov.com.qq.im.QIMCameraCaptureActivity",
      "com.googleCamera.Wichaya8",
      "com.accordion.analogcam.cn",
      "org.codeaurora.snapcam",
      "com.android.camera",
      "com.xiaomi.scanner",
      "com.blink.academy.protake",
      "com.benqu.wuta",
      "com.gorgeous.lite",
      "com.kwai.m2u",
      "com.meitu.meiyancamera",
      "com.yiruike.sodacn.android",
      "com.lemon.faceu",
      "com.mt.mtxx.mtxx",
      "com.oneplus.camera",
      "com.google.android.GoogleCamera"
    ],
    "category": "Camera"
  },
  {
    "friendly": "狗屎/毒瘤",
    "packages": [
      "com.tencent.mm:appbrand",
      "com.tencent.mm:toolsmp"
    ],
    "category": "MiniProgram"
  },
  {
    "friendly": "白名单应用",
    "packages": [
      "com.miui.huanji",
      "com.miui.backup",
      "com.android.providers.downloads.ui",
      "android.process.mediaui"
    ],
    "category": "WhiteList"
  },
  {
    "friendly": "原神",
    "packages": [
      "com.miHoYo.Yuanshen",
      "com.miHoYo.ys.mi",
      "com.miHoYo.ys.bilibili",
      "com.miHoYo.GenshinImpact"
    ],
    "category": "GenshinImpact"
  },
  {
    "friendly": "游戏",
    "packages": [
      "xyz.aethersx2.android",
      "org.ppsspp.ppsspp",
      "org.ppsspp.ppssppgold",
      "skyline.emu",
      "com.xiaoji.gamesirnsemulator"
    ],
    "category": "Game"
  },
  {
    "friendly": "CPU跑分",
    "packages": [
      "com.ioncannon.cpuburn.gpugflops",
      "com.ioncannon.memlatency",
      "com.primatelabs.geekbench5",
      "com.primatelabs.geekbench6",
      "com.andromeda.androbench2",
      "com.antutu.ABenchMark"
    ],
    "category": "CPUBenchmark"
  },
  {
    "friendly": "GPU跑分",
    "packages": [
      "com.futuremark.dmandroid.application",
      "com.glbenchmark.glbenchmark27",
      "com.antutu.benchmark.full"
    ],
    "category": "GPUBenchmark"
  },
  {
    "friendly": "All",
    "packages": ["*"],
    "category": "Apps"
  }
]
```