# 完整 ioctl 命令表

| 命令名                                            | 十六进制   | 方向 | 参数/大小                                      | 说明                               |
| ------------------------------------------------- | ---------- | ---- | ---------------------------------------------- | ---------------------------------- |
| EAS_SYNC_SET                                      | 0x40046701 | W    | unsigned int                                   | 设置 wake sync                     |
| EAS_SYNC_GET                                      | 0x40046702 | W    | unsigned int                                   | 获取 wake sync（源码定义为 \_IOW） |
| EAS_PERTASK_LS_SET                                | 0x40046703 | W    | unsigned int                                   | 设置 per-task LS                   |
| EAS_PERTASK_LS_GET                                | 0x80046704 | R    | unsigned int                                   | 获取 per-task LS                   |
| EAS_ACTIVE_MASK_GET                               | 0x80046705 | R    | unsigned int                                   | 获取 CPU active mask               |
| EAS_NEWLY_IDLE_BALANCE_INTERVAL_SET               | 0x40046706 | W    | unsigned int                                   | 设置 newidle balance 间隔          |
| EAS_NEWLY_IDLE_BALANCE_INTERVAL_GET               | 0x80046707 | R    | unsigned int                                   | 获取 newidle balance 间隔          |
| EAS_GET_THERMAL_HEADROOM_INTERVAL_SET             | 0x40046708 | W    | unsigned int                                   | 设置 thermal headroom 间隔         |
| EAS_GET_THERMAL_HEADROOM_INTERVAL_GET             | 0x80046709 | R    | unsigned int                                   | 获取 thermal headroom 间隔         |
| EAS_SBB_ALL_SET                                   | 0x4004670c | W    | unsigned int                                   | 设置所有 SBB                       |
| EAS_SBB_ALL_UNSET                                 | 0x4004670d | W    | unsigned int                                   | 取消所有 SBB                       |
| EAS_SBB_GROUP_SET                                 | 0x4004670e | W    | unsigned int                                   | 设置 group SBB                     |
| EAS_SBB_GROUP_UNSET                               | 0x4004670f | W    | unsigned int                                   | 取消 group SBB                     |
| EAS_SBB_TASK_SET                                  | 0x40046710 | W    | unsigned int                                   | 设置 task SBB                      |
| EAS_SBB_TASK_UNSET                                | 0x40046711 | W    | unsigned int                                   | 取消 task SBB                      |
| EAS_SBB_ACTIVE_RATIO                              | 0x40046712 | W    | unsigned int                                   | 设置 SBB active ratio              |
| EAS_UTIL_EST_CONTROL                              | 0x40046714 | W    | unsigned int                                   | 控制 util_est                      |
| EAS_TURN_POINT_UTIL_C0                            | 0x40046715 | W    | unsigned int                                   | 设置 cluster0 turn point           |
| EAS_TARGET_MARGIN_C0                              | 0x40046716 | W    | unsigned int                                   | 设置 cluster0 target margin        |
| EAS_TURN_POINT_UTIL_C1                            | 0x40046717 | W    | unsigned int                                   | 设置 cluster1 turn point           |
| EAS_TARGET_MARGIN_C1                              | 0x40046718 | W    | unsigned int                                   | 设置 cluster1 target margin        |
| EAS_TURN_POINT_UTIL_C2                            | 0x40046719 | W    | unsigned int                                   | 设置 cluster2 turn point           |
| EAS_TARGET_MARGIN_C2                              | 0x4004671a | W    | unsigned int                                   | 设置 cluster2 target margin        |
| EAS_SET_CPUMASK_TA                                | 0x4004671b | W    | unsigned int                                   | 设置 top-app cpumask               |
| EAS_SET_CPUMASK_BACKGROUND                        | 0x4004671c | W    | unsigned int                                   | 设置 background cpumask            |
| EAS_SET_CPUMASK_FOREGROUND                        | 0x4004671d | W    | unsigned int                                   | 设置 foreground cpumask            |
| EAS_SET_TASK_LS                                   | 0x4004671e | W    | unsigned int                                   | 设置 task LS                       |
| EAS_UNSET_TASK_LS                                 | 0x4004671f | W    | unsigned int                                   | 取消 task LS                       |
| EAS_SET_TASK_LS_PREFER_CPUS                       | 0x40086720 | W    | struct SA_task (8)                             | 设置 LS task 偏好 CPU              |
| EAS_IGNORE_IDLE_UTIL_CTRL                         | 0x40046721 | W    | unsigned int                                   | 设置忽略 idle util                 |
| EAS_SET_TASK_VIP                                  | 0x40046722 | W    | unsigned int                                   | 设置 task VIP                      |
| EAS_UNSET_TASK_VIP                                | 0x40046723 | W    | unsigned int                                   | 取消 task VIP                      |
| EAS_SET_TA_VIP                                    | 0x40046724 | W    | unsigned int                                   | 设置 top-app VIP                   |
| EAS_UNSET_TA_VIP                                  | 0x40046725 | W    | unsigned int                                   | 取消 top-app VIP                   |
| EAS_SET_FG_VIP                                    | 0x40046726 | W    | unsigned int                                   | 设置 foreground VIP                |
| EAS_UNSET_FG_VIP                                  | 0x40046727 | W    | unsigned int                                   | 取消 foreground VIP                |
| EAS_SET_BG_VIP                                    | 0x40046728 | W    | unsigned int                                   | 设置 background VIP                |
| EAS_UNSET_BG_VIP                                  | 0x40046729 | W    | unsigned int                                   | 取消 background VIP                |
| EAS_SET_LS_VIP                                    | 0x4004672a | W    | unsigned int                                   | 设置 LS task VIP                   |
| EAS_UNSET_LS_VIP                                  | 0x4004672b | W    | unsigned int                                   | 取消 LS task VIP                   |
| EAS_GEAR_MIGR_DN_PCT                              | 0x4004672c | W    | unsigned int                                   | 设置 gear down 迁移百分比          |
| EAS_GEAR_MIGR_UP_PCT                              | 0x4004672d | W    | unsigned int                                   | 设置 gear up 迁移百分比            |
| EAS_GEAR_MIGR_SET                                 | 0x4004672e | W    | unsigned int                                   | 应用 gear 迁移百分比               |
| EAS_GEAR_MIGR_UNSET                               | 0x4004672f | W    | unsigned int                                   | 取消 gear 迁移百分比               |
| EAS_TASK_GEAR_HINTS_START                         | 0x40046730 | W    | unsigned int                                   | 设置 gear hints 起始               |
| EAS_TASK_GEAR_HINTS_NUM                           | 0x40046731 | W    | unsigned int                                   | 设置 gear hints 数量               |
| EAS_TASK_GEAR_HINTS_REVERSE                       | 0x40046732 | W    | unsigned int                                   | 设置 gear hints 反向               |
| EAS_TASK_GEAR_HINTS_SET                           | 0x40046733 | W    | unsigned int                                   | 应用 gear hints                    |
| EAS_TASK_GEAR_HINTS_UNSET                         | 0x40046734 | W    | unsigned int                                   | 取消 gear hints                    |
| EAS_SET_GAS_CTRL                                  | 0x40086735 | W    | struct gas_ctrl (8)                            | 设置 GAS 控制                      |
| EAS_SET_GAS_THR                                   | 0x40086736 | W    | struct gas_thr (8)                             | 设置 group 阈值                    |
| EAS_RESET_GAS_THR                                 | 0x40046737 | W    | int                                            | 重置 group 阈值                    |
| EAS_SET_GAS_MARG_THR                              | 0x40106738 | W    | struct gas_margin_thr (16)                     | 设置 GAS margin 阈值               |
| EAS_RESET_GAS_MARG_THR                            | 0x40046739 | W    | int                                            | 重置 GAS margin 阈值               |
| EAS_RT_AGGRE_PREEMPT_SET                          | 0x4004673a | W    | unsigned int                                   | 设置 RT 聚合抢占                   |
| EAS_RT_AGGRE_PREEMPT_RESET                        | 0x4004673b | W    | unsigned int                                   | 重置 RT 聚合抢占                   |
| EAS_DPT_CTRL                                      | 0x4004673c | W    | int                                            | DPT 控制                           |
| EAS_RUNNABLE_BOOST_SET                            | 0x4004673d | W    | unsigned int                                   | 设置 runnable boost                |
| EAS_RUNNABLE_BOOST_UNSET                          | 0x4004673e | W    | unsigned int                                   | 取消 runnable boost                |
| EAS_SET_DSU_IDLE                                  | 0x4004673f | W    | unsigned int                                   | 设置 DSU idle                      |
| EAS_UNSET_DSU_IDLE                                | 0x40046740 | W    | unsigned int                                   | 取消 DSU idle                      |
| EAS_SET_CURR_TASK_UCLAMP                          | 0x40046741 | W    | unsigned int                                   | 设置当前 task uclamp               |
| EAS_UNSET_CURR_TASK_UCLAMP                        | 0x40046742 | W    | unsigned int                                   | 取消当前 task uclamp               |
| EAS_TARGET_MARGIN_LOW_C0                          | 0x40046743 | W    | unsigned int                                   | 设置 cluster0 target margin low    |
| EAS_TARGET_MARGIN_LOW_C1                          | 0x40046744 | W    | unsigned int                                   | 设置 cluster1 target margin low    |
| EAS_TARGET_MARGIN_LOW_C2                          | 0x40046745 | W    | unsigned int                                   | 设置 cluster2 target margin low    |
| EAS_UNSET_TARGET_MARGIN_C0                        | 0x40046746 | W    | unsigned int                                   | 取消 cluster0 target margin        |
| EAS_UNSET_TARGET_MARGIN_C1                        | 0x40046747 | W    | unsigned int                                   | 取消 cluster1 target margin        |
| EAS_UNSET_TARGET_MARGIN_C2                        | 0x40046748 | W    | unsigned int                                   | 取消 cluster2 target margin        |
| EAS_UNSET_TARGET_MARGIN_LOW_C0                    | 0x40046749 | W    | unsigned int                                   | 取消 cluster0 target margin low    |
| EAS_UNSET_TARGET_MARGIN_LOW_C1                    | 0x4004674a | W    | unsigned int                                   | 取消 cluster1 target margin low    |
| EAS_UNSET_TARGET_MARGIN_LOW_C2                    | 0x4004674b | W    | unsigned int                                   | 取消 cluster2 target margin low    |
| EAS_SET_SHORTCUT_COMPRESS_RATE                    | 0x4004674c | W    | int                                            | 设置 shortcut compress 比率        |
| EAS_RESET_SHORTCUT_COMPRESS_RATE                  | 0x4004674d | W    | int                                            | 重置 shortcut compress 比率        |
| EAS_SET_SHORTCUT_COMPRESS_RELAX_ENOUGH_CPU_UTIL   | 0x4008674e | W    | struct shortcut_compress_relax_enough_args (8) | 设置 CPU util relax 阈值           |
| EAS_RESET_SHORTCUT_COMPRESS_RELAX_ENOUGH_CPU_UTIL | 0x4004674f | W    | int                                            | 重置 CPU util relax 阈值           |
| EAS_SET_SHORTCUT_COMPRESS_RELAX_ENOUGH_TSK_UTIL   | 0x40086750 | W    | struct shortcut_compress_relax_enough_args (8) | 设置 task util relax 阈值          |
| EAS_RESET_SHORTCUT_COMPRESS_RELAX_ENOUGH_TSK_UTIL | 0x40046751 | W    | int                                            | 重置 task util relax 阈值          |
| EAS_SET_GH_GATHERING_TH                           | 0x40046752 | W    | int                                            | 设置 gear hints gathering 阈值     |
| EAS_RESET_GH_GATHERING_TH                         | 0x40046753 | W    | int                                            | 重置 gear hints gathering 阈值     |
| EAS_RUNNABLE_BOOST_UTIL_EST_SET                   | 0x40046754 | W    | int                                            | 设置 runnable boost util_est       |
| EAS_RUNNABLE_BOOST_UTIL_EST_UNSET                 | 0x40046755 | W    | int                                            | 取消 runnable boost util_est       |


## 在scene中的调用案例

["@ioctl", "/proc/easmgr/eas_ioctl",
    "0x4004672c", "50", "0x4004672d", "70", "0x4004672e", "0",
    "0x4004672c", "75", "0x4004672d", "90", "0x4004672e", "1",
    "0x40046706", "5000"
]

顺序	ioctl 命令  参数    含义
1	    0x4004672c	50      EAS_GEAR_MIGR_DN_PCT：把 down 迁移百分比 dn_pct 设为 50
2	    0x4004672d	70	    EAS_GEAR_MIGR_UP_PCT：把 up 迁移百分比 up_pct 设为 70
3	    0x4004672e	0	    EAS_GEAR_MIGR_SET：把上面的百分比应用到 gear 0
4	    0x4004672c	75	    EAS_GEAR_MIGR_DN_PCT：把 dn_pct 设为 75
5	    0x4004672d	90	    EAS_GEAR_MIGR_UP_PCT：把 up_pct 设为 90
6	    0x4004672e	1	    EAS_GEAR_MIGR_SET：把上面的百分比应用到 gear 1
7	    0x40046706	5000	EAS_NEWLY_IDLE_BALANCE_INTERVAL_SET：设置 newidle balance 间隔为 5000 微秒