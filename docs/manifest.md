## 描述
- 描述文件的作用将决定配置方案在Scene中的展示


### 内部配置
- 对于安装到Scene内部目录的配置，描述文件为 `manifest.json`
- 描述文件需包含以下参数

| 参数 | 描述 | 类型 |
| :-: | :- | :-: |
| version | 配置名称 | String |
| versionCode | 配置号 | Int64 |
| author | 作者 | String |
| projectUrl | 项目地址 | String |
| features | 特性声明 | Object |

- 配置示例

```json
{
  "version": "FAS Beta",
  "versionCode": 20230528001,
  "author": "SCENE6",
  "projectUrl": "http://vtools.omarea.com/",
  "features": {
    "strict": true,
    "pedestal": false
  }
}
```


### 外部配置
- 对于安装到外部(/data目录下)的配置，描述文件为 `powercfg.json`
- 常用于`uperf`及其衍生版本向Scene说明自己的配置信息
- 描述文件需包含以下参数

| 参数 | 描述 | 类型 |
| :-: | :- | :-: |
| version | 配置名称 | String |
| versionCode | 配置号 | Int64 |
| author | 作者 | String |
| projectUrl | 项目地址 | String |
| features | 特性声明 | Object |
| files | 相关文件路径 | Array |
| module | 相关(Magisk)模块ID，有多个模块ID可以用英文,分隔 | String |
| state | 初始状态存储路径 | String |

- files和module作用是让用户在Scene里`切换配置源`时，自动删除外部配置的相关文件，和自动禁用相关模块

- 配置示例

```json
{
  "version": "Uperf",
  "versionCode": 0001,
  "author": "yc9559",
  "projectUrl": "https://github.com/yc9559/uperf",
  "features": {
    "strict": true,
    "pedestal": true
  },
  "files": [
    "/data/powercfg.sh",
    "/data/powercfg.json",
    "/data/powercfg-base.sh"
  ],
  "module": "uperf,sfanalysis"
}
```

#### 特性
- 特性的声明包含以下参数

| 特性 | 描述 | 类型 |
| :-: | :- | :-: |
| strict | 是否支持严格模式 | bool |
| pedestal | 是否支持底座模式 | bool |

##### strict 严格模式
- Scene主张根据应用类型做不同的性能调节策略
- 即使一直处于`省电模式`或其它任一模式，性能也不应该是恒定的
- 因此，强烈建议在配置中对不同类型的应用做出适配，并始终声明`strict`为`true`

#### pedestal 底座模式
- 底座模式被定义为无需考虑能耗的模式，
- 如果声明`pedestal`为`true`，用户则可以在SCENE里启用底座模式
- 底座模式只会在连接充电器时自动激活，无法手动开启