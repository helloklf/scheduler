import { FormControl, FormControlLabel, MenuItem, InputLabel, Select, Switch, TextField, Button } from '@mui/material'
import { Box } from '@mui/system'
import React from 'react'
import CollapseView from '../../components/CollapseView'
import ModuleSched from './ModuleSched'
import SelectX from '../../components/SelectX'
import NumberInput from '../../components/NumberInput'

export default class Modules extends React.Component {
  onChange (form, field, value) {
    if (value && value.target) {
      form[field] = value.target.value
      this.setState({})
    } else {
      form[field] = value
      this.setState({})
    }
  }

  moduleSwitcher (params) {
    const { switchInode, perapp, hintDuration } = params
    const { idle, touch, trigger, gesture, switch: _switch, junk, swjunk } = hintDuration || {}
    const onChange = this.onChange

    return <>
      <TextField size="small" variant="filled" value={switchInode} label="switchInode"
         onChange={onChange.bind(this, params, 'switchInode')} disabled />
      <TextField size="small" variant="filled" value={perapp} label="perapp"
         onChange={onChange.bind(this, params, 'perapp')} disabled />

      <div style={{ marginTop: '0.5em' }}>hintDuration/hint最长持续时间(s)</div>
      <NumberInput onChange={onChange.bind(this, hintDuration, 'idle')} value={idle} label="idle"
        helpText="默认" min="0" max="99999" />
      <NumberInput onChange={onChange.bind(this, hintDuration, 'touch')} value={touch} label="touch"
        helpText="触摸屏幕/按下按键" min="0" max="99999" />
      <NumberInput onChange={onChange.bind(this, hintDuration, 'trigger')} value={trigger} label="trigger"
        helpText="点击操作离开屏幕/滑动操作起始" min="0" max="99999" />
      <NumberInput onChange={onChange.bind(this, hintDuration, 'gesture')} value={gesture} label="gesture"
        helpText="全面屏手势" min="0" max="99999" />
      <NumberInput onChange={onChange.bind(this, hintDuration, 'switch')} value={_switch} label="switch"
        helpText="应用切换动画/点亮屏幕" min="0" max="99999" />
      <NumberInput onChange={onChange.bind(this, hintDuration, 'junk')} value={junk} label="junk"
        helpText="touch/gesture 中 sfanalysis 检测到掉帧" min="0" max="99999" />
      <NumberInput onChange={onChange.bind(this, hintDuration, 'swjunk')} value={swjunk} label="swjunk"
        helpText="switch 中 sfanalysis 检测到掉帧" min="0" max="99999" />
    </>
  }
  moduleATrace (params) {
    
  }
  moduleLog (params) {
    const { level } = params
    return <SelectX
              label="level"
              size="small"
              labelId="module-log-level"
              value={level}
              onChange={this.onChange.bind(this, params, 'level')}
            >
              <MenuItem value="err">err</MenuItem>
              <MenuItem value="warn">warn</MenuItem>
              <MenuItem value="info">info</MenuItem>
              <MenuItem value="debug">debug</MenuItem>
              <MenuItem value="trace">trace</MenuItem>
            </SelectX>
  }
  moduleInput (params) {
    const { swipeThd, gestureThdX, gestureThdY, gestureDelayTime, holdEnterTime } = params
    return <>
      <NumberInput style={{ marginTop: '1em' }}
        value={swipeThd} label="swipeThd: 单次触摸轨迹百分比长度超过该阈值，判定为滑动操作"
        onChange={this.onChange.bind(this, params, 'swipeThd')} min="0" max="100" />

      <NumberInput value={gestureThdX} label="gestureThdX: 全面屏手势起始 X 轴百分比位置"
              onChange={this.onChange.bind(this, params, 'gestureThdX')} min="0" max="100" />

      <NumberInput value={gestureThdY} label="gestureThdY: 全面屏手势起始 Y 轴百分比位置"
              onChange={this.onChange.bind(this, params, 'gestureThdY')} min="0" max="100" />

      <TextField size="small" variant="filled"
        style={{ marginTop: '1em' }}
        value={gestureDelayTime} label="gestureDelayTime" disabled />
      <TextField size="small" variant="filled" value={holdEnterTime} label="holdEnterTime" disabled />
    </>
  }
  moduleSFAnalysis (params) {
    const { renderIdleSlackTime } = params
    return <>
      <NumberInput style={{ marginTop: '1em' }}
        value={renderIdleSlackTime} label="renderIdleSlackTime(s): 渲染结束保持一段时间，判定为渲染结束"
        min="0.001" max="9999"
        onChange={this.onChange.bind(this, params, 'swipeThd')} />
    </>
  }
  moduleCPU (params) {
    const { powerModel } = params
    return <div className="code">
      <code>{JSON.stringify(powerModel, null, 2)}</code>
    </div>
  }
  moduleSysFS (params) {
    const { knob } = params
    return <>
      <div style={{ marginTop: '0.5em' }}>knob</div>
      {Object.keys(knob || {}).map((it, index) => (<>
        <TextField size="small" variant="filled" value={knob[it]} label={it} key={index}
          onChange={this.onChange.bind(this, knob, it)} />
      </>))}
      <Button disabled>添加</Button>
    </>
  }
  moduleSched (params) {
    return <ModuleSched params={params} /> 
  }

  moduleRender = (moduleName, params) => {
    switch (moduleName) {
      case 'switcher': {
        return this.moduleSwitcher(params)
      }
      case 'atrace': {
        return this.moduleATrace(params)
      }
      case 'log': {
        return this.moduleLog(params)
      }
      case 'input': {
        return this.moduleInput(params)
      }
      case 'sfanalysis': {
        return this.moduleSFAnalysis(params)
      }
      case 'cpu': {
        return this.moduleCPU(params)
      }
      case 'sysfs': {
        return this.moduleSysFS(params)
      }
      case 'sched': {
        return this.moduleSched(params)
      }
    }
    return <div>{JSON.stringify(params)}</div>
  }

  render () {
    const { modules } = this.props
    return <Box>
      {(Object.keys(modules || {})).map(key => (<CollapseView icon={'#'} title={key} key={key}>
        <div style={{ textAlign: 'center' }}>
          { modules[key].enable !== undefined && <FormControlLabel
            control={<Switch onChange={(e) => {
              this.onChange(modules[key], 'enable', e.target.checked)
            }} checked={modules[key].enable} />} label={`Enable ${key}`} />
          }
        </div>
        {
          modules[key].enable !== false && <Box sx={{ width: '100%', flexDirection: 'column', display: 'flex' }}>
            {this.moduleRender(key, modules[key])}
          </Box>
        }
        
      </CollapseView>))}
    </Box>
  }
}