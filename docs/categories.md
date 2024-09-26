## 类目

## 一级分类
- SCENE将应用分App、游戏、性能测试三个大类
- 是否归类为游戏通过是否包含游戏引擎、是否横屏启动、是否集成游戏服务判定
- 一个应用是否属于游戏，将决定它是否可以开启FAS，是否使用游戏专用策略
- 而性能测试类根据内置包名识别判定。但Scene拒绝跑分优化，不提供单独参数配置


### 二级分类
- SCENE还会根据自带的`categories.json`配置区分应用子类
- 该文件也可以添加到性能调节配置中，下载配置时将覆盖Scene携带的版本
- Scene携带的`categories.json` 文件大致如下

```json
[
  {
    "friendly": "抖音、西瓜、快手",
    "packages": [
      "com.ss.android.ugc.aweme",
      "com.ss.android.ugc.aweme.lite",
      "com.ss.android.ugc.trill",
      "com.ss.android.ugc.live",
      "com.baidu.haokan",
      "com.phoenix.read",
      "com.ss.android.article.video",
      "com.kuaishou.nebula",
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
      "com.hunantv.imgo.activity",

      "cn.cntvhd",
      "com.gitvdemo.video",
      "com.hunantv.imgo.activity",
      "com.ktcp.video",
      "tv.danmaku.bilibilihd",
      "com.qiyi.video.pad"
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
      "com.kugou.android.lite",
      "com.tencent.qqmusic",
      "com.tencent.qqmusiclite",
      "com.miui.player",
      "com.luna.music",
      "cn.kuwo.player",
      "com.google.android.apps.youtube.music"
    ],
    "category": "Music"
  },
  {
    "friendly": "小说阅读",
    "packages": [
      "com.dragon.read",
      "io.legado.app.release",
      "com.duokan.free",
      "com.kmxs.reader",
      "com.duokan.reader",
      "com.ruguoapp.jike",
      "com.ruanmei.ithome",
      "com.qidian.QDReader",
      "com.ushaqi.zhuishushenqi.adfree",
      "com.bishuge.reader.xs",
      "com.qq.reader"
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
      "com.mfw.roadbook",
      "com.heytap.browser",
      "com.tencent.news"
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
      "com.bbk.launcher2",
      "com.zte.mifavor.launcher"
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
      "com.google.android.GoogleCamera",
      "com.oplus.camera",
      "com.samsung.agc.gcam84",
      "com.mediatek.expert.mtkcamhelper",
      "org.codeaurora.snapcam",
      "com.meizu.media.camera"
    ],
    "category": "Camera"
  },
  {
    "friendly": "狗屎/毒瘤",
    "packages": [
      "com.tencent.mm:appbrand",
      "com.tencent.mm:appbrand1",
      "com.tencent.mm:toolsmp",
      "com.tencent.mobileqq:mini",
      "com.tencent.mobileqq:mini1"
    ],
    "category": "MiniProgram"
  },
  {
    "friendly": "白名单应用",
    "packages": [
      "com.miui.huanji",
      "com.miui.backup",
      "com.meizu.datamigration",
      "com.android.providers.downloads.ui",
      "android.process.mediaui",
      "com.coloros.backuprestore",
      "com.rarlab.rar",
      "org.swiftapps.swiftbackup",
      "xzr.konabess",
      "com.oplus.ota",
      "com.android.updater",
      "com.termux",
      "com.termux.x11",
      "vegabobo.dsusideloader"
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
      "com.antutu.ABenchMark",
      "ioncannon.com.andspecmod",
      "ioncannon.com.anspec17"
    ],
    "category": "CPUBenchmark"
  },
  {
    "friendly": "GPU跑分",
    "packages": [
      "com.futuremark.dmandroid.application",
      "com.glbenchmark.glbenchmark27",
      "com.antutu.benchmark.full",
      " com.tellusim.GravityMark",

      "com.miui.weather2",
      "com.miui.personalassistant",
      "pro.archiemeng.waifu2x",
      "com.tumuyan.ncnn.realsr"
    ],
    "category": "GPUBenchmark"
  },
  {
    "friendly": "地图导航",
    "packages": [
      "com.autonavi.minimap",
      "com.baidu.BaiduMap",
      "com.baidu.maps.caring",
      "com.google.android.apps.maps",
      "com.tencent.map",
      "com.nhn.android.nmap",
      "com.maps.voice.navigation.traffic.gps.location.route.driving.directions",
      "com.google.android.apps.mapslite",
      "com.google.earth",
      "ru.yandex.yandexmaps",
      "com.sdu.didi.psnger",
      "com.didapinche.booking",
      "com.sdu.didi.gsui",
      "com.sankuai.meituan.dispatch.homebrew",
      "com.dada.mobile.android"
    ],
    "category": "Nav"
  },
  {
    "friendly": "All",
    "packages": ["*"],
    "category": "Apps"
  }
]
```