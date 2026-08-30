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
    "pedestal": false
  }
}
```

#### 特性
- 特性的声明包含以下参数

| 特性 | 描述 | 类型 |
| :-: | :- | :-: |
| pedestal | 是否支持底座模式 | bool |
| reboot | 切换配置后是否需要重启 | bool |
| fas | 是否支持FAS | bool |

#### pedestal 底座模式
- 底座模式被定义为无需考虑能耗的模式，
- 如果声明`pedestal`为`true`，用户则可以在SCENE里启用底座模式
- 底座模式只会在连接充电器时自动激活，无法手动开启


### 外部配置（第三方调度）对接
- 首先，你需要创建 `/data/powercfg.sh` 用于响应场景切换，做出性能调节
- 在 `powercfg.sh` 中你可以使用以下变量

  | 参数 | 描述 | 可能的值 |
  | :-: | :- | :-: |
  | $scene | 场景 | 可能是应用 `packageName`、`activity` |
  | $top_app | 值同`$scene`变量 | |
  | $mode | 模式 | `powersave`、`balance` 等 |
  | $1 | 值同`$mode` | |
  | $category | 应用主类别 | `app` 、`game`|

  > powercfg.sh 内容示例
    ```sh
    if [[ "$mode" = "init" ]]; then
      echo "TODO: 初始化" # 在首次触发性能调节前出现一次
    elif [[ "$scene" = "standby" ]]; then
      echo "TODO: 进入待机场景" # standby 在新版scene中可能已被废弃！
    elif [[ "$mode" = "powersave" ]]; then
      echo "TODO: 切换省电模式"
    elif [[ "$mode" = "balance" ]]; then
      echo "TODO: 切换均衡模式"
    elif [[ "$mode" = "performance" ]]; then
      echo "TODO: 切换性能模式"
    elif [[ "$mode" = "fast" ]]; then
      echo "TODO: 切换极速模式"
    elif [[ "$mode" = "pedestal" ]]; then
      echo "TODO: 切换底座模式"
    fi
    ```

- 另外还需要创建描述文件 `/data/powercfg.json`
- 描述文件可包含以下信息

  | 参数 | 描述 | 类型 |
  | :-: | :- | :-: |
  | version | 配置名称 | String |
  | versionCode | 配置号 | Int64 |
  | author | 作者 | String |
  | projectUrl | 可选，通常指向git仓库 | String |
  | features | 特性声明 | Object |
  | module | 相关(Magisk)模块ID，多个模块ID用英文,分隔 | String |
  | state | 可选，初始状态存储路径 | String |

  > **module** 的作用是当用户在Scene里`切换配置源`时，自动禁用外部配置相关模块

  > **state** 的作用是向Scene暴露当前`mode`。比如uperf本身具有模式切换功能，指定状态存储路径，可以让Scene启动时能从该位置获取初始状态

  > powercfg.json 配置示例

  ```json
  {
    "version": "Uperf",
    "versionCode": 0001,
    "author": "yc9559",
    "projectUrl": "https://github.com/yc9559/uperf",
    "features": {
      "pedestal": true
    },
    "module": "uperf,sfanalysis",
    "state": "/storage/emulated/0/Android/yc/uperf/cur_powermode.txt"
  }
  ```
