## 别名
- 别名是指对面某个路径的简写，使用别名可以有效减少配置篇幅，提高配置可读性


### 内置别名
- SCENE已经预置了很多别名，具体如下：

```json
{
	"cpu_min_0": "/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq",
	"cpu_min_3": "/sys/devices/system/cpu/cpufreq/policy3/scaling_min_freq",
	"cpu_min_4": "/sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq",
	"cpu_min_6": "/sys/devices/system/cpu/cpufreq/policy6/scaling_min_freq",
	"cpu_min_7": "/sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq",

	"cpu_max_0": "/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq",
	"cpu_max_3": "/sys/devices/system/cpu/cpufreq/policy3/scaling_max_freq",
	"cpu_max_4": "/sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq",
	"cpu_max_6": "/sys/devices/system/cpu/cpufreq/policy6/scaling_max_freq",
	"cpu_max_7": "/sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq",

	"governor_cpu0": "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor",
	"governor_cpu4": "/sys/devices/system/cpu/cpufreq/policy4/scaling_governor",
	"governor_cpu7": "/sys/devices/system/cpu/cpufreq/policy7/scaling_governor",

	"msm_cpu_max": "/sys/module/msm_performance/parameters/cpu_max_freq",

	"uclamp_fg_max":  "/dev/cpuctl/foreground/cpu.uclamp.max",
	"uclamp_fg_min":  "/dev/cpuctl/foreground/cpu.uclamp.min",
	"uclamp_top_max": "/dev/cpuctl/top-app/cpu.uclamp.max",
	"uclamp_top_min": "/dev/cpuctl/top-app/cpu.uclamp.min",
	"uclamp_bg_max":  "/dev/cpuctl/background/cpu.uclamp.max",
	"uclamp_bg_min":  "/dev/cpuctl/background/cpu.uclamp.min",

	"gpu_mod_percent": "/sys/class/kgsl/kgsl-3d0/devfreq/mod_percent",

	"sched_down":       "/proc/sys/kernel/sched_downmigrate",
	"sched_up":         "/proc/sys/kernel/sched_upmigrate",
	"sched_group_down": "/proc/sys/kernel/sched_group_downmigrate",
	"sched_group_up":   "/proc/sys/kernel/sched_group_upmigrate",

	"cpuset_top":    "/dev/cpuset/top-app/cpus",
	"cpuset_fg":     "/dev/cpuset/foreground/cpus",
	"cpuset_bg":     "/dev/cpuset/background/cpus",
	"cpuset_sys_bg": "/dev/cpuset/system-background/cpus",

	"core_ctl_0": "/sys/devices/system/cpu/cpu0/core_ctl/enable",
	"core_ctl_4": "/sys/devices/system/cpu/cpu4/core_ctl/enable",
	"core_ctl_6": "/sys/devices/system/cpu/cpu6/core_ctl/enable",
	"core_ctl_7": "/sys/devices/system/cpu/cpu7/core_ctl/enable",

	"sched_boost":         "/proc/sys/kernel/sched_boost",
	"sched_boost_top_app": "/proc/sys/kernel/sched_boost_top_app",

	"stune_top_boost": "/dev/stune/top-app/schedtune.boost",
	"stune_top_perf":  "/dev/stune/top-app/schedtune.prefer_idle",

	"up_rate_limit_0": "/sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us",
	"up_rate_limit_4": "/sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us",
	"up_rate_limit_6": "/sys/devices/system/cpu/cpufreq/policy6/schedutil/up_rate_limit_us",
	"up_rate_limit_7": "/sys/devices/system/cpu/cpufreq/policy7/schedutil/up_rate_limit_us",

	"down_rate_limit_0": "/sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us",
	"down_rate_limit_4": "/sys/devices/system/cpu/cpufreq/policy4/schedutil/down_rate_limit_us",
	"down_rate_limit_6": "/sys/devices/system/cpu/cpufreq/policy6/schedutil/down_rate_limit_us",
	"down_rate_limit_7": "/sys/devices/system/cpu/cpufreq/policy7/schedutil/down_rate_limit_us",

	"mi_thermal": "/sys/class/thermal/thermal_message/sconfig",
}
```

- 现在可以通过`$`使用路径别名，就像这样

```json
{
  "schemes": {
    "powersave": {
      "call": [
        ["$mi_thermal", "10"]
      ]
    }
  }
}
```

### 自定义别名
- 除了使用预置别名，也可以自己添加别名
- 当自定义的别名与预置别名重名时，自定义的别名会覆盖预置
- 使用示例：

```json
{
  "alias": {
    "max_cpus_cpu3": "/sys/devices/system/cpu/cpu3/core_ctl/max_cpus",
    "min_cpus_cpu3": "/sys/devices/system/cpu/cpu3/core_ctl/min_cpus"
  },
  "schemes": {
    "powersave": {
      "call": [
        ["$max_cpus_cpu3", "4"]
        ["$min_cpus_cpu3", "1"]
      ]
    }
  }
}
```