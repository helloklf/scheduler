## 创建一个配置文件

- 如下所示，这是一个名为`profile.json`的配置文件
> `schemes` 的五个子项分别对应SCENE的5个模式

```json
{
  "schemes": {
    "powersave": {
      "call": [],
      "app": [],
      "game": []
    },
    "balance": {
      "call": [],
      "app": [],
      "game": []
    },
    "performance": {
      "call": [],
      "app": [],
      "game": []
    },
    "fast": {
      "call": [],
      "app": [],
      "game": []
    },
    "pedestal": {
      "call": [],
      "app": [],
      "game": []
    }
  }
}
```

| KEY | NAME |
| :- | :- |
| powersave | 省电模式 |
| balance | 均衡模式 |
| performance | 性能模式 |
| fast | 极速模式 |
| pedestal | 底座模式 |

- 在这里 `call` 代表的是当前模式下的公共设定
- `app` 是用于`普通APP`的额外设定
- `game` 是用于`游戏`的额外设定

- 如需配置`pedestal`模式，需先在描述文件中声明！