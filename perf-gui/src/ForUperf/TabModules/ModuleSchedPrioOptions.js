import React from 'react'
import { MenuItem } from "@mui/material"

const items = []
items.push(<MenuItem key={0} value={0}>跳过 SCHED 类别设置</MenuItem>)
for (let i=1; i<98; i++) {
  items.push(<MenuItem key={i} value={i}>SCHED_FIFO 优先级{i}</MenuItem>)
}
for (let i=100; i<139; i++) {
  items.push(<MenuItem key={i} value={i}>SCHED_NORMAL 优先级{i}</MenuItem>)
}
items.push(<MenuItem key={-1}value={-1}>SCHED_NORMAL</MenuItem>)
items.push(<MenuItem key={-2} value={-2}>SCHED_BATCH</MenuItem>)
items.push(<MenuItem key={-3} value={-3}>SCHED_IDLE</MenuItem>)

export default items
