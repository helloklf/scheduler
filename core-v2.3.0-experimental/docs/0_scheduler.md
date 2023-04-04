# 适用版本
- 本文档适用于 SCENE 6.2+

## [创建空配置](./empty.md)
## [基础](./basic.md)
## [场景](./apps.md)
## [传感器](./sensor.md)
## [CPUSET](./cpuset.md)
## [触摸升频](./booster.md)
## [预设](./presets.md)
## [别名](./alias.md)
## [新特性](./new_features.md)
## [拓展函数](./kernel_features.md)

## 重要提示
- 注意，文中所有示例代码，仅用于展示框架功能，并非性能优化最佳实践
- 以上就是SCENE性能调节配置的全部内容，下面的是参考案例和经验分享

- 状态缓存
> SCENE会尽可能缓存配置信息，避免重复解析配置浪费性能，<br>
> 因此在/data/.../files下进行修改并不会即时生效，<br>
> 你需要重启手机或杀死scene-daemon它才会重新加载配置
