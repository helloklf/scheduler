* 值得注意的是，尽管SCENE6依然兼容`affinity`配置，但并不推荐继续使用。
* 因为 `affinity` 通过 mask 指定核心，非常不利于阅读。
* 目前 `affinity` 和 `cpuset` 配置的作用是完全相同的，因此推荐配置 `cpuset`。

## 线程CPU亲和 `affinity`
- 你可能听说过，绝大多数书Unity游戏，都有个叫`UnityMain`的线程CPU占用极高
- 大多数情况下，内核会根据实际负载需要决定要不要将任务迁移到`Big`核心
- 但不排除有些时候，系统会为了节省电力故意降低调用`Big`核心的积极性
- 对于这种情况，我们可能会手动改变线程的放置来提高游戏流畅性
- Scene提供的CPU亲和设置配置格式如下：

```json
{
  "friendly": "原神",
  "packages": ["com.miHoYo.Yuanshen"],
  "affinity": {
    "repeat": 0,
    "interval": 5000,
    "cpuset_mode": "off",
    "unity_main": "80",
    "heavy_thread": "UnityGfx",
    "heavy_mask": "70",
    "comm": {
      "70": ["UnityMultiRende", "mali-cmar-backe"],
      "F": ["Worker Thread", "AudioTrack", "Audio"]
    },
    "other": "7f"
  }
}
```

- `other` 配置是可选的，为空或不配置时将略过名称未出现在`comm`配置中的线程
- `unity_main` 配置也是可选的，用于指定UnityMain线程的Affinity mask。如果进程中存在多个UnityMain线程，则只会命中负载最高的那一个。
- `heavy_thread` 配置也是可选的，需与heavy_thread配合使用，用于指定重负载线程的名称。如果进程中存在多个同名线程，则只会命中负载最高的那一个。
- `heavy_mask` 需与heavy_thread配合使用，用于指定重负载线程的Affinity mask。
- `repeat` 是重复检查线程亲和设置的最大次数，配置为`0`表示无限次，默认为0
- `interval` 是线程亲和设置检查时间间隔，最小值为`50` 默认值为`5000`，单位是毫秒
- `cpuset_mode` 是framework 130中新增的属性，可设为 coexist | always | off
> coexist 使用affinity设置的同时，同时使用cpuset加强约束，二者协同让线程放置更加稳固 <br>
> always 使用cpuset代替affinity，相当于自动翻译成cpuset配置 <br>
> off 默认

- 你没看懂上面这些 `80`、`70`、`F`、`7f` 是什么意思？
  > 这是一个16进制数，表示的是用哪些核心，比如<br>
  > 把`80`转成2进制，就是 `10000000`，8位数字，这下是否明白了呢？<br>
  > 把`70`转成2进制，就是 `1110000`，7位数，补1个0，补够8位即`01110000`<br>
  > 把`f`转成2进制，就是 `1111`，4位数，补4个0，补够8位即`00001111`<br>

- 想必这下你已经看明白了，它其实是用`0`和`1`来表示是否使用某个核心<br>
  > `80`即`10000000`，表示`CPU7`<br>
  > `70`即`01110000`，表示`CPU6~4`<br>
  > `f`即`00001111`，表示`CPU3~0`

