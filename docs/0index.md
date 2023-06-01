# 适用版本
- 本文档适用于 SCENE 6.2+

## 组成
- 在SCENE6中，一套完整的配置通常包含以下文件

  ```sh
  # 方案初始化脚本 可选
  powercfg.sh

  # 方案配置主文件 必需
  profile.json

  # 线程配置文件 可选
  threads.json

  # 方案描述文件 *必需
  manifest.json 
  ```
  powercfg.sh仅在scene-daemon启动后或配置更新后，首次执行调度切换前执行<br>
  对于一些每次开机后仅需执行一次的修改，可以在该脚本中完成。



# 主要功能
## [创建空配置](./empty.md)
## [基础](./basic.md)
## [场景](./apps.md)
## [类目](categories.md)
## [传感器](./sensor.md)
## [CPUSET](./cpuset.md)
## [触摸升频](./booster.md)
## [预设](./presets.md)
## [别名](./alias.md)
## [新特性](./new_features.md)
## [描述](./manifest.md)

<br />

# 附录
## [其它](./others.md)

<br />

## 重要提示
- 文档中所有示例代码，仅用于展示框架功能，并非性能优化最佳实践

- 状态缓存
> SCENE会尽可能缓存配置信息，避免重复解析配置浪费性能，<br>
> 因此在/data/data/com.omarea.vtools/files下进行修改并不会即时生效，<br>
> 你需要重启手机或杀死scene-daemon它才会重新加载配置
