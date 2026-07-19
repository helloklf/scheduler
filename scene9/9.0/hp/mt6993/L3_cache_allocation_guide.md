# MT6993（OPPO Find X9）L3 缓存分配策略修改方案

> 适用源码树：`android_kernel_modules_and_devicetree_oppo-mt6993_b_16.0.0_find_x9`
> 平台：MediaTek MT6993（k6993v1_64），kernel 6.12 GKI + 设备模块
> 相关配置：`CONFIG_MTK_CPUQOS_V3=m`、`CONFIG_MTK_CPUQOS_EXT=m`、`CONFIG_OPLUS_FEATURE_SLC=m`（k6993v1_64 已启用）

---

## 1. 结论速查

| 方案               | 改什么                                    | 接口            | 需要重编内核   | 生效范围      |
| ------------------ | ----------------------------------------- | --------------- | -------------- | ------------- |
| 1. group_partition | 6 个 user group 的 L3 way 掩码            | sysfs           | 否             | 全局，立即    |
| 2. cpuqos_ioctl    | 模式 / CT 任务 / CT 组 / user group 绑定  | proc ioctl      | 否             | 全局或单任务  |
| 3. 内核 API        | 同上，内核态直接调用                      | GPL export      | 否（外挂模块） | 全局或单任务  |
| 4. FPSGO CT 控制   | 哪些游戏线程吃 L3 优待                    | sysfs           | 否             | 游戏场景      |
| 5. custpd          | 每核强制 PD + stall 闭环动态调 way        | proc + 模块参数 | 否             | 全局，闭环    |
| 6. oplus_slc       | CPU/GPU/各 master 的 cache 上限与强制份额 | proc            | 否             | 按 UID/master |
| 7. 改源码          | 默认映射表、默认模式、闭环算法、初始掩码  | 代码            | 是             | 永久          |

**改不到的部分**（提前说清，避免浪费时间）：

- PD 编号 → 具体 L3 way/份额的寄存器级映射，在联发科闭源预编译模块里
  （`vendor/mediatek/kernel_modules/sched_cus/src/cpuqos_build_utility_*.o`，LLVM bitcode，无源码）；
- CT/NCT portion、动态门限（`dnth0/1`、`upth0/1`）等策略执行主体在 **MCUPM 固件**
  （见 `mt6993.dts:3701` 的 `__MCUPM_MET_L3CTL__` 字段表），不在这棵源码树里。

内核侧能掌控的是：**谁是关键任务（CT）、全局模式、每个 user group 的 8bit way 掩码、以及 OPPO 的 stall 闭环算法**。

---

## 2. 架构背景（看懂再动手）

### 2.1 三层结构

```
┌─ 用户态 ────────────────────────────────────────────────┐
│  init / perf daemon / FPSGO middleware / 你自己的脚本     │
└──────┬──────────────────────────────────────────────────┘
       │ sysfs / proc / ioctl
┌──────┴──────────────────────────────────────────────────┐
│ cpuqos_v3.ko（开源）                                     │
│  · 按 cgroup 把任务分进 PD0~PD9（PD2=CT，PD3=默认 NCT）    │
│  · user group 1~6 → PD10~15，自带 way 掩码表             │
│  · 切换任务时把 PD 写到本 CPU（经函数指针）                 │
│  源码: kernel/kernel_device_modules-6.12/drivers/misc/    │
│        mediatek/cache-auditor/cpuqos_v3/cpuqos_v3_proto.c│
└──────┬──────────────────────────────────────────────────┘
       │ mtk_cpuqos_set(pd) / mtk_cpuqos_css_map(id)（函数指针）
┌──────┴──────────────────────────────────────────────────┐
│ cpuqos_ext（闭源 bitcode）                                │
│  · PD → 硬件寄存器/way 的实际映射                          │
└──────┬──────────────────────────────────────────────────┘
       │ L3CTL SRAM mailbox @ 0x5390620（mt6993.dts:2412）
┌──────┴──────────────────────────────────────────────────┐
│ MCUPM 固件（闭源）                                        │
│  · op_policy / ct_portion / nct_portion / dnth / upth    │
│  · 真正执行分区与动态调整                                   │
└─────────────────────────────────────────────────────────┘
```

### 2.2 关键概念

- **PD（Partition Descriptor）**：任务身上带的缓存分区标签，范围 0~15。
  - `PD2` = CT（Critical Task，关键任务，吃 L3 优待）
  - `PD3` = 默认 NCT（非关键任务）
  - `PD10~15` = user group 1~6（= 9 + group），每个 group 有一张 8bit way 掩码
- **cgroup → PD 默认映射**：cgroup 路径表（`cpuqos_v3_proto.c:100`）：
  | group_id | 0 | 1 | 2 | 3 | 4 | 5 | 6 |
  |---|---|---|---|---|---|---|---|
  | 路径 | `/` | `/foreground` | `/background` | `/top-app` | `/rt` | `/system` | `/system-background` |
- **perf mode**：`0=AGGRESSIVE, 1=BALANCE, 2=CONSERVATIVE, 3=DISABLE`。
  开机后用户态写 `cpuqos_boot_complete=1` 才进入 `BALANCE`（`cpuqos_v3_proto.c:698`）。
- **way 掩码**：8bit，每一位对应一路（way）L3，`0xFF` = 全部可用。probe 时 6 个 group 全初始化为 `0xFF`。

---

## 3. 方案一：group_partition —— 直接改 way 掩码（最直接）

**原理**：sysfs 写入后直接 `iowrite8` 到 L3CTL SRAM 的 group 分区表
（偏移 `0xCC + (gid-1)*4`，`cpuqos_v3_proto.c:1025-1042`）。

**接口**：`/sys/devices/system/cpu/cpuqos/group_partition`（0600，root）

**格式**：

- 写：`gid,bitmap`（十进制，逗号分隔；bitmap ≤ 255）
- 读：显示 6 个 group 当前的 GID 和 bitmap（十六进制）

**实例**：

```sh
# 查看当前 6 个 user group 的 way 分配
cat /sys/devices/system/cpu/cpuqos/group_partition
# 输出示例：
# Group partition :
# GID     bitmap
# 1       ff
# 2       ff
# ...

# 让 user group 1 只能用低 4 路（bit0~3）
echo "1,15" > /sys/devices/system/cpu/cpuqos/group_partition

# 让 user group 3 独占高 4 路（bit4~7）
echo "3,240" > /sys/devices/system/cpu/cpuqos/group_partition

# 恢复全部 way
echo "1,255" > /sys/devices/system/cpu/cpuqos/group_partition
```

**配合**：把任务塞进 user group 才有意义（见方案二/三/五的 `set_task_user_group`）。

**注意**：

- 写入的是 SRAM mailbox，最终如何被 MCUPM 固件解释（是否即时生效、是否被固件周期性覆盖）取决于固件实现；建议改完后用方案 9 的观测手段确认。
- `custpd_ctl=1`（方案五）的闭环会周期性覆写 group 1~3 的掩码，两者不要同时用。

---

## 4. 方案二：cpuqos_ioctl —— 用户态全功能控制通道

**接口**：`/proc/cpuqosmgr/cpuqos_ioctl`（0660）

**命令字**（`cpuqos_v3.h:22-27`）：

| cmd                | 宏                                 | 用到的结构体字段             | 作用                                             |
| ------------------ | ---------------------------------- | ---------------------------- | ------------------------------------------------ |
| `_IOW('g',14,...)` | `CPUQOS_V3_SET_CPUQOS_MODE`        | `mode`                       | 设全局模式 0~3                                   |
| `_IOW('g',15,...)` | `CPUQOS_V3_SET_CT_TASK`            | `pid`, `set_task`            | 把 pid 设为 CT（PD2）/ 还原                      |
| `_IOW('g',16,...)` | `CPUQOS_V3_SET_CT_GROUP`           | `group_id`, `set_group`      | 把 cgroup 组设为 CT / NCT                        |
| `_IOW('g',17,...)` | `CPUQOS_V3_SET_TASK_TO_USER_GROUP` | `user_pid`, `set_user_group` | 把 pid 绑定到 user group 1~6（<0 还原）          |
| `_IOW('g',18,...)` | `CPUQOS_V3_SET_CCL_TO_USER_GROUP`  | `bitmask`, `set_user_group`  | 设 user group 的 way 掩码（同方案一）            |
| `_IOW('g',19,...)` | `CPUQOS_V3_SET_CUSTPD`             | `mode`                       | 切 custpd 预设（1=小核 group5/大核 PD2，0=清除） |

**命令字十六进制值**（编码：`(1<<30) | (32<<16) | (0x67<<8) | nr`，sizeof=32B、`'g'=0x67`，基值 `0x40206700`；
结构体全是 `__u32`，32/64 位下命令值相同，无需区分 compat）：

| 宏                                 | nr  | 十六进制     | 十进制     |
| ---------------------------------- | --- | ------------ | ---------- |
| `CPUQOS_V3_SET_CPUQOS_MODE`        | 14  | `0x4020670E` | 1075865358 |
| `CPUQOS_V3_SET_CT_TASK`            | 15  | `0x4020670F` | 1075865359 |
| `CPUQOS_V3_SET_CT_GROUP`           | 16  | `0x40206710` | 1075865360 |
| `CPUQOS_V3_SET_TASK_TO_USER_GROUP` | 17  | `0x40206711` | 1075865361 |
| `CPUQOS_V3_SET_CCL_TO_USER_GROUP`  | 18  | `0x40206712` | 1075865362 |
| `CPUQOS_V3_SET_CUSTPD`             | 19  | `0x40206713` | 1075865363 |

全局模式有4个模式：
`AGGRESSIVE=0x0`、`BALANCE=0x1`、`CONSERVATIVE=0x2`、`DISABLE=0x3`。

> 调试提示：对未知 cmd，驱动会打 `unknown cmd %x` 日志（`cpuqos_v3_proto.c:1143`），可用 dmesg 反查发出的命令值是否正确。

**C 语言实例**：

```c
#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <stdint.h>

struct _CPUQOS_V3_PACKAGE {
    uint32_t mode;
    uint32_t pid;
    uint32_t set_task;
    uint32_t group_id;
    uint32_t set_group;
    uint32_t user_pid;
    uint32_t bitmask;
    uint32_t set_user_group;
};

#define CPUQOS_V3_SET_CPUQOS_MODE          _IOW('g', 14, struct _CPUQOS_V3_PACKAGE)
#define CPUQOS_V3_SET_CT_TASK              _IOW('g', 15, struct _CPUQOS_V3_PACKAGE)
#define CPUQOS_V3_SET_CT_GROUP             _IOW('g', 16, struct _CPUQOS_V3_PACKAGE)
#define CPUQOS_V3_SET_TASK_TO_USER_GROUP   _IOW('g', 17, struct _CPUQOS_V3_PACKAGE)
#define CPUQOS_V3_SET_CCL_TO_USER_GROUP    _IOW('g', 18, struct _CPUQOS_V3_PACKAGE)
#define CPUQOS_V3_SET_CUSTPD               _IOW('g', 19, struct _CPUQOS_V3_PACKAGE)

int main(void)
{
    int fd = open("/proc/cpuqosmgr/cpuqos_ioctl", O_RDWR);
    if (fd < 0) { perror("open"); return 1; }

    struct _CPUQOS_V3_PACKAGE pkg = {0};

    /* 1) 全局模式设为 AGGRESSIVE(0) */
    pkg.mode = 0;
    ioctl(fd, CPUQOS_V3_SET_CPUQOS_MODE, &pkg);

    /* 2) 把 /top-app(group_id=3) 整组设为 CT */
    pkg = (struct _CPUQOS_V3_PACKAGE){ .group_id = 3, .set_group = 1 };
    ioctl(fd, CPUQOS_V3_SET_CT_GROUP, &pkg);

    /* 3) 把 pid=1234 单独设为 CT（覆盖其 group 设置） */
    pkg = (struct _CPUQOS_V3_PACKAGE){ .pid = 1234, .set_task = 1 };
    ioctl(fd, CPUQOS_V3_SET_CT_TASK, &pkg);

    /* 4) user group 2 只给 4 路 way，并把 pid=1234 绑进去 */
    pkg = (struct _CPUQOS_V3_PACKAGE){ .bitmask = 0x0F, .set_user_group = 2 };
    ioctl(fd, CPUQOS_V3_SET_CCL_TO_USER_GROUP, &pkg);

    pkg = (struct _CPUQOS_V3_PACKAGE){ .user_pid = 1234, .set_user_group = 2 };
    ioctl(fd, CPUQOS_V3_SET_TASK_TO_USER_GROUP, &pkg);

    close(fd);
    return 0;
}
```

**注意**：任务级设置（CT task / user group）会把该任务切到 `TASK_RANK`，此后不再跟随 cgroup 组设置；
传 `set_task=0` / `set_user_group<0` 才会还原为 `GROUP_RANK`。

---

## 5. 方案三：内核模块直接调导出 API

以下函数全部 `EXPORT_SYMBOL_GPL`（`cpuqos_v3_proto.c`），外挂 GPL 模块可直接调用
（声明在 `cpuqos_sys_common.h`）：

```c
int set_cpuqos_mode(int mode);            /* 0~3 */
int set_ct_task(int pid, bool set);       /* 单任务 CT */
int set_ct_group(int group_id, bool set); /* cgroup 组 CT/NCT */
int set_group_pd(int group_id, int pd);   /* 组 → 任意 PD（-1=PD3） */
int set_task_pd(int pid, int pd);         /* 任务 → 任意 PD（-1=跟随组） */
int set_task_user_group(int pid, int group);   /* 任务 → user group 1~6 */
int set_cache_ctl_user_group(int bitmask, int group); /* group way 掩码 */
```

**模块实例**（开机把 `/background` 组压到低 way，前台关键线程设 CT）：

```c
#include <linux/module.h>
#include <linux/init.h>

extern int set_ct_group(int group_id, bool set);
extern int set_group_pd(int group_id, int pd);
extern int set_task_user_group(int pid, int group);
extern int set_cache_ctl_user_group(int bitmask, int group);

static int __init myl3_init(void)
{
    /* user group 4 只给 2 路 way，专门关后台任务 */
    set_cache_ctl_user_group(0x03, 4);

    /* /background(group_id=2) 显式设为 NCT(PD3) */
    set_group_pd(2, 3);

    /* /top-app(group_id=3) 设为 CT(PD2) */
    set_ct_group(3, true);

    /* 已知的重要系统进程 pid=567 绑进全 way 的 group 5 */
    set_cache_ctl_user_group(0xFF, 5);
    set_task_user_group(567, 5);

    return 0;
}

static void __exit myl3_exit(void) { }

module_init(myl3_init);
module_exit(myl3_exit);
MODULE_LICENSE("GPL");
```

**注意**：`set_group_pd`/`set_task_pd` 在 `plat_enable==0`（设备树 `enable=<0>`）时直接返回 -1。

---

## 6. 方案四：FPSGO —— 游戏场景的 CT 认定

FPSGO 按线程负载把游戏线程分成 HEAVY / SECOND / OTHERS 三组，
`set_l3_cache_ct` 决定哪几组被 `set_ct_task(pid, PD2)`（`fbt_cpu.c:1056-1085`）。

**接口 A（全局）**：`/sys/kernel/fpsgo/fbt/set_l3_cache_ct`（RW，取值 0~3）

| 值  | 含义                            |
| --- | ------------------------------- |
| 0   | 不给任何游戏线程 CT             |
| 1   | 只给 HEAVY 组 CT                |
| 2   | HEAVY + SECOND 给 CT            |
| 3   | HEAVY + SECOND + OTHERS 全部 CT |

```sh
# 只让重载渲染线程吃 L3 优待
echo 1 > /sys/kernel/fpsgo/fbt/set_l3_cache_ct
cat /sys/kernel/fpsgo/fbt/set_l3_cache_ct
```

**接口 B（按 pid 覆盖）**：`/sys/kernel/fpsgo/fbt/fbt_attr_by_pid`（WO）

格式：`<cmd> <action> <pid> <val>`，`action=s` 设定、`u` 还原默认（val=-1）。

```sh
# 单独给 pid 4321 的游戏设置级别 2
echo "set_l3_cache_ct s 4321 2" > /sys/kernel/fpsgo/fbt/fbt_attr_by_pid

# 还原为全局默认
echo "set_l3_cache_ct u 4321 -1" > /sys/kernel/fpsgo/fbt/fbt_attr_by_pid

# 彻底删除该 pid 的自定义 attr（val=-2）
echo "set_l3_cache_ct u 4321 -2" > /sys/kernel/fpsgo/fbt/fbt_attr_by_pid
```

**查看当前参数**：读取 fpsgo base 目录下的 `render_attr_params` 节点（含 `set_l3_cache_ct` 列；
base_kobj 目录名以设备实际为准，可用 `ls /sys/kernel/fpsgo/` 确认）。

**适用场景**：不想全局动策略，只想调游戏/重点 App 的 L3 行为。这是改动最小、最"产品化"的方式。

---

## 7. 方案五：custpd —— 每核强制 PD + stall 闭环动态调 way

OPPO 在 `CONFIG_OPLUS_FEATURE_SLC` 下加的一套机制（`cpuqos_v3_proto.c:1168-1375`），
k6993v1_64 已启用。

### 7.1 每核强制 PD：`/proc/cpuqosmgr/custpd`（0660）

8 个十进制值对应 cpu0~7，**非 0 值会覆盖一切 cgroup/group 判定**
（`cpuqos_v3_sync_task()` 里优先检查，L304-320）。

```sh
# 查看
cat /proc/cpuqosmgr/custpd        # 输出: 0,0,0,0,0,0,0,0

# 小核 cluster(cpu0-3) 强制走 user group 5(PD=9+5=14)，大核(cpu4-7) 强制 CT(PD2)
echo "14,14,14,14,2,2,2,2" > /proc/cpuqosmgr/custpd

# 全部还原为正常调度
echo "0,0,0,0,0,0,0,0" > /proc/cpuqosmgr/custpd
```

### 7.2 stall 闭环：`/proc/cpuqosmgr/custpd_ctl`（0660）

开启后，内核线程每 `custpd_period` ms（默认 1000）做一次：

1. 读每个 CPU 的 `AMEVCNTR0_MEM_STALL` PMU 计数，算增量；
2. 归一化到最大值的百分比 `delta_pct`；
3. 每核所需 way 数 `res[i] = ((delta_pct[i] + 10) * custpd_max_bit) / 100`，转成低位掩码；
4. 取 cluster 内最大值写入 user group：
   - group 1 ← cpu0~3（小核）
   - group 2 ← cpu4~6（中核）
   - group 3 ← cpu7（超大核）

```sh
# 开启动态闭环（stall 越高的 cluster 分到越多 way）
echo 1 > /proc/cpuqosmgr/custpd_ctl

# 关闭（自动把 6 个 group 掩码全部重置为 0xFF）
echo 0 > /proc/cpuqosmgr/custpd_ctl
```

### 7.3 调参（module_param，0644）

模块名 `cpuqos_v3`，参数节点 `/sys/module/cpuqos_v3/parameters/`：

| 参数             | 默认 | 作用                                        |
| ---------------- | ---- | ------------------------------------------- |
| `custpd_period`  | 1000 | 闭环周期（ms），调小响应更快、开销更大      |
| `custpd_max_bit` | 8    | way 掩码位数上限（=最多给几路）             |
| `custpd_debug`   | 0    | 打内核日志：每核计数/增量/百分比/算出的掩码 |

```sh
# 在线调（root）
echo 500 > /sys/module/cpuqos_v3/parameters/custpd_period
echo 4   > /sys/module/cpuqos_v3/parameters/custpd_max_bit   # 封顶 4 路
echo 1   > /sys/module/cpuqos_v3/parameters/custpd_debug     # 看算法中间量
dmesg | grep custpd

# 或加载时固化：/vendor/etc/modules.load 或 modprobe.d
# options cpuqos_v3 custpd_period=500 custpd_max_bit=4
```

### 7.4 ioctl 预设

`CPUQOS_V3_SET_CUSTPD`（'g',19）mode=1 直接套用 `set_custpd()` 里的硬编码预设：
cpu0~3 → PD14(user group 5)，cpu4~7 → PD2。预设本身是写死的，要改只能动源码（方案七）。

---

## 8. 方案六：oplus_slc —— 按 UID/master 控 CPU vs GPU 的 cache

另一条独立控制路径：OPPO SLC 模块（`vendor/oplus/kernel/cpu/oplus_slc/`），
经 SLBC SDK（`slbc_ceil` / `slbc_force_cache` / …）→ IPI/SMC → SSPM 固件执行。
**维度是硬件 master/UID（CPU、GPU、VDEC、CAM、NPU…），不是任务。**

**接口目录**：`/proc/oplus_slc/`（0664）

| 节点          | 格式          | 作用                                                            |
| ------------- | ------------- | --------------------------------------------------------------- |
| `ceil`        | `uid,size`    | 设某 master 的 cache 上限；uid=1(CPU)/2(GPU)；size 0~10，0=取消 |
| `force`       | `uid,size`    | 强制某 UID 的 cache 大小（0~10）                                |
| `force_ratio` | `uid,ratio`   | 强制 CPU/GPU 占比（0~100），uid 仅 1/2                          |
| `priority`    | `uid`         | CPU/GPU 争用时谁优先（1=CPU，2=GPU）                            |
| `window`      | hex 1~1000    | 统计窗口（**注意按 %x 解析**，写 "32" 实际是 0x32=50）          |
| `disable`     | 0/1           | 整体关闭/恢复 SLBC（`slbc_sspm_slc_disable`）                   |
| `pause`       | 0/1           | 暂停用户态 SLC 服务继续下发配置（防止覆盖你的手动设置）         |
| `hitrate`     | 先写 uid 再读 | 该 UID 的 cache 命中率                                          |
| `size`        | 先写 uid 再读 | 该 UID 当前 cache 大小                                          |
| `hitbw`       | 先写 uid 再读 | 该 UID 的命中带宽（100ms 采样）                                 |
| `usage`       | 只读          | cpu/gpu/other 三方用量                                          |
| `fcfg`        | 只读          | 当前 cpu/gpu 的 force 配置回读                                  |
| `dbg`         | 0/1           | 调试日志                                                        |
| `hint`        | int           | 性能提示                                                        |
| `dis_cdwb`    | 0/1           | CDWB 开关                                                       |

UID 编号（`slbc_ops.h:124` `enum slc_ach_uid`）：
`0=ID_PD, 1=ID_CPU, 2=ID_GPU, 3=ID_GPU_W, 4=ID_OVL_R, 5=ID_VDEC_FRAME, 6=ID_VDEC_UBE, 7=ID_SMMU, 8=ID_MD, 9=ID_ADSP, 10=ID_AOV, 11=ID_IMG, 12=ID_CAM, 13=ID_MAE, 14=ID_DMR, 15=ID_OD, 16=ID_DBI, 17=ID_NPU_ADL_DC, 18=ID_NPU, 19=ID_VENC_EC, 20=ID_SMMU_H ...`

**实例**：

```sh
# 防止用户态 SLC 服务把你的设置改回去
echo 1 > /proc/oplus_slc/pause

# GPU 上限压到 4，把 cache 让给 CPU
echo "2,4" > /proc/oplus_slc/ceil

# CPU 强制拿 8
echo "1,8" > /proc/oplus_slc/force

# 或者按比例：CPU 70%
echo "1,70" > /proc/oplus_slc/force_ratio

# CPU/GPU 争用时 CPU 优先
echo 1 > /proc/oplus_slc/priority

# 验证
cat /proc/oplus_slc/usage
echo 1 > /proc/oplus_slc/size && cat /proc/oplus_slc/size      # CPU 当前大小
echo 1 > /proc/oplus_slc/hitrate && cat /proc/oplus_slc/hitrate # CPU 命中率
cat /proc/oplus_slc/fcfg

# 恢复
echo "2,0" > /proc/oplus_slc/ceil     # 取消 GPU 上限
echo "1,0" > /proc/oplus_slc/force
echo 0 > /proc/oplus_slc/pause
```

另有 `/proc/oplus_cl/cl_multi_enq`（multi-enqueue 开关）和 OSML 采样节点
（`/proc/.../osml_setting/`），与策略采样相关，一般不需要动。

---

## 9. 方案七：改源码 —— 固化自己的策略

适合要长期改默认行为的场景。所有点位都在**开源**的 `cpuqos_v3_proto.c`：

### 7.1 改 cgroup → PD 默认映射思路

cgroup 路径表（`cpuqos_v3_proto.c:100-108`）只决定"哪些路径会被识别"，
真正的 路径→PD 值由闭源 `mtk_cpuqos_css_map()` 返回；但你可以：

- 在 `css_map()`（L208）/`__map_css_pd()`（L795）之后用 `set_group_pd()` 覆写任意组的 PD；
- 或新增路径让自定义 cgroup 也被纳管（需与 `cpu_cgrp` 层级一致）。

### 7.2 改默认模式 / 启动时机

```c
/* cpuqos_v3_proto.c:707  set_boot_complete() 里 */
set_cpuqos_mode(BALANCE);     /* 改成 AGGRESSIVE，或改成你自己的默认 */

/* L1444  init 时 */
cpuqos_perf_mode = DISABLE;   /* 开机到 boot_complete 之间的模式 */
```

### 7.3 改初始 way 掩码

```c
/* cpuqos_v3_proto.c:908-910  probe 里 */
for (i = 1; i <= GRP_NUM; i++)
    set_cache_ctl_user_group(MAX_BITMASK, i);   /* 默认全 0xFF，可改成差异化初值 */
```

### 7.4 改闭环算法

`custpd_calculate()`（L1248-1317）整个算法是开源的。例如把"线性映射 + cluster 取 max"
换成"按 stall 平方加权"、"保留保底 way 数"、"分组更细（8 核 8 组）"等都只需要动这一个函数。
预设表 `set_custpd()`（L1169-1191）同理。

### 7.5 改任务分类逻辑

`cpuqos_v3_map_task_pd()`（L263）是 task→PD 的唯一入口，注释里明说
"This is the place to add special logic for a task-specific PD"。
例如按 `p->comm` 白名单强制 PD，加在这里。

### 7.6 设备树

```dts
/* mt6993.dts:2412 */
cpuqos_v3: cpuqos-v3@5390620 {
    compatible = "mediatek,cpuqos-v3";
    reg = <0 0x05390620 0 0x400>;
    enable = <1>;      /* 0 = 整个 cpuqos 失效，所有 set_xxx 返回 -1 */
    ram-base = <2>;    /* 0:SLC 1:SYSRAM 2:TCM；≠0 时 mode 才会写入 SRAM */
};
```

### 7.7 重新编译

模块目标：`cpuqos_v3.ko`（`drivers/misc/mediatek/cache-auditor/cpuqos_v3/`），
按项目 bazel/Kbuild 流程出模块后替换，或用 `modules.load` 配置加载参数。

---

## 10. 观测与验证（改完必须做）

| 手段            | 命令                                                                                    | 看什么                                                       |
| --------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| 组掩码回读      | `cat /sys/devices/system/cpu/cpuqos/group_partition`                                    | 写入是否生效                                                 |
| CT 状态         | `echo <pid> > /sys/devices/system/cpu/cpuqos/l3m_status_info && cat ...l3m_status_info` | 模式、哪些组是 CT、指定 pid 是否 CT                          |
| CT/NCT 资源占比 | `cat /sys/devices/system/cpu/cpuqos/resource_percentage`                                | 固件汇报的 CT:NCT 份额比                                     |
| 全任务 PD 快照  | `cat /proc/cpuqosmgr/dump`                                                              | 每个线程的 rank/css/tpd/gpd                                  |
| ftrace          | `echo 1 > /sys/kernel/tracing/events/cpuqos_v3/enable`                                  | `cpuqos_cpu_pd`（每次切任务的 PD 切换）、`cpuqos_set_*` 系列 |
| 周期性 tracer   | `echo 1 > /sys/devices/system/cpu/cpuqos/cpuqos_trace_enable`                           | 每 25ms 读 SIZE_USAGE 打 trace                               |
| SLC 侧          | `cat /proc/oplus_slc/usage`、`hitrate`、`size`                                          | CPU/GPU 实际用量与命中率                                     |
| MET/MCUPM       | dts `__MCUPM_MET_L3CTL__` 通道                                                          | 固件侧 hit/miss、portion、mode（需 MET 工具）                |

ftrace 实例：

```sh
cd /sys/kernel/tracing
echo nop > current_tracer
echo 1 > events/cpuqos_v3/cpuqos_cpu_pd/enable
echo 1 > events/cpuqos_v3/cpuqos_set_task_pd/enable
cat trace_pipe   # 另开一个 shell 做你的改动，观察 PD 是否如预期切换
```

---

## 11. 权限、持久化与风险

- **权限**：sysfs 节点 0600、proc 节点 0660/0664，需要 root（或 system/特定 SELinux 域）。
  量产机上 SELinux 可能拦截新增访问，需配套 sepolicy。
- **持久化**：上述所有运行时接口都是**内存态**，重启丢失。固化方式：
  init rc 脚本 / `vendor.init.*.rc` 里加 `write` 命令，或做成模块参数/源码默认值（方案七）。
- **风险**：
  - way 给太少会直接拉低对应任务的性能并可能增加功耗（miss 变多、内存流量变大）；
  - `custpd_ctl` 闭环与手动 `group_partition` 会互相覆盖，二选一；
  - `oplus_slc/disable` 会把整个 SLBC 停掉，影响面超出 CPU（GPU、显示、编解码都在用），谨慎；
  - 改动 MCUPM 看到的 SRAM 值属于"建议"，固件可能有自己的兜底/覆盖逻辑，务必用第 10 节手段实测确认。

---

## 附录 A：关键源码索引

| 内容                                 | 位置                                                                                                             |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| 主驱动（PD 分类/sysfs/ioctl/custpd） | `kernel/kernel_device_modules-6.12/drivers/misc/mediatek/cache-auditor/cpuqos_v3/cpuqos_v3_proto.c`              |
| ioctl 命令字与结构体                 | 同目录 `cpuqos_v3.h`                                                                                             |
| 内核 API 声明                        | 同目录 `cpuqos_sys_common.h`                                                                                     |
| sysfs kobj 创建                      | 同目录 `cpuqos_sys_common.c`                                                                                     |
| task 内嵌 PD 字段                    | `drivers/misc/mediatek/sched/common.h:237`（`struct cpuqos_task_struct`）                                        |
| 闭源 PD→硬件映射                     | `vendor/mediatek/kernel_modules/sched_cus/src/cpuqos_build_utility_*.o`（bitcode）                               |
| FPSGO CT 判定                        | `drivers/misc/mediatek/performance/fpsgo_v8/fbt/src/fbt_cpu.c:1056`                                              |
| FPSGO per-pid attr                   | 同文件 `fbt_attr_by_pid_store()`（L7643 起）                                                                     |
| OPPO SLC                             | `vendor/oplus/kernel/cpu/oplus_slc/oplus_slc_main.c`                                                             |
| SLBC UID 枚举                        | `drivers/misc/mediatek/slbc/slbc_ops.h:124`                                                                      |
| 设备树节点                           | `arch/arm64/boot/dts/mediatek/mt6993.dts:2412`（cpuqos）、`:3701`（MCUPM L3CTL）                                 |
| 开关配置                             | `arch/arm64/configs/mgk_64_k612_defconfig:658`、`vendor/oplus/kernel/cpu/build/defconfig/k6993v1_64/slc_configs` |

## 附录 B：术语

- **CT / NCT**：Critical / Non-Critical Task，cpuqos 对任务的关键性二分（PD2 vs PD3）。
- **PD**：Partition Descriptor，任务携带的缓存分区标签（0~15）。
- **way 掩码**：8bit，每 bit 一路 L3 way，决定某 user group 可用哪些 way。
- **L3CTL / MCUPM**：L3 控制器与其上的微控制器固件，策略实际执行者。
- **SLBC**：System Level Buffer Controller，联发科 SLC（系统级缓存）管理单元，oplus_slc 经它下发配置。
