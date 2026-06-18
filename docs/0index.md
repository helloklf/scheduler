# 适用版本
- 本文档根据Scene9.0框架特性编写

## 组成
- 在SCENE中，一套完整的性能调节配置通常包含以下文件

  ```sh
  # 方案配置主文件 *必需
  profile.json

  # 方案描述文件 *必需
  manifest.json

  # 方案初始化脚本 可选
  powercfg.sh

  # 线程配置文件 可选
  threads.json
  ```
  powercfg.sh仅在scene-daemon启动或配置更新后，首次进行性能调节档位切换前执行一次


# 主要功能
## [空配置](./empty.md)
## [基础](./basic.md)
## [场景](./apps.md)
## [类目](./categories.md)
## [传感器](./sensor.md)
## [核心分配](./cpuset.md)
## [交互状态](./state.md)
## [预设](./presets.md)
## [别名](./alias.md)
## [特性](./features.md)
## [描述](./manifest.md)
## [静态配置](./conf.md)

<br />

# 附录
## [其它](./others.md)

<br />

## 重要提示
- 文档中所有示例代码，仅用于展示框架功能，并非性能优化最佳实践
