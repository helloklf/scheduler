import React from 'react'
import { Checkbox, FormControlLabel, Switch, TextField, MenuItem } from '@mui/material'
import CollapseView from '../components/CollapseView'
import NumberInput from '../components/NumberInput'
import SelectX from '../components/SelectX'

const helpText = {
  baseSampleTime: '(0.01~0.5)秒 基础采样周期',
  baseSlackTime: '(0.01~0.5)秒 闲置采样周期，CPU 整体进入空载时生效',
  latencyTime: '(0.0~10.0)秒 CPU 整体升频最小延迟',
  slowLimitPower: '(0.05~999.0)瓦 CPU 长期功耗限制',
  fastLimitPower: '(0.05~999.0)瓦 CPU CPU 短期功耗限制，能耗缓冲池消耗完毕后进入长期功耗限制',
  fastLimitCapacity: '(0.05~999.0)瓦 CPU CPU 短期功耗限制容量',
  fastLimitRecoverScale: '(0.1~10.0) CPU 短期功耗限制容量恢复缩放因子',
  predictThd: '(0.1~1.0) CPU 集群最大负载增加量大于该阈值，则集群调频使用预测的负载值，并忽略latencyTime',
  margin: '（0.0~1.0）调频提供的性能余量',
  burst: '（0.0~1.0）调频提供的额外性能余量，非零时忽略latencyTime',
  guideCap: '启用引导 EAS 任务调度负载转移',
  limitEfficiency: '启用 CPU 整体能效限制',
}

const fieldProps = {
  baseSampleTime: {
    min: 0.01,
    max: 0.5
  },
  baseSlackTime: {
    min: 0.01,
    max: 0.5
  },
  latencyTime: {
    min: 0.0,
    max: 10
  },
  slowLimitPower: {
    min: 0.05,
    max: 999
  },
  fastLimitPower: {
    min: 0.05,
    max: 999
  },
  fastLimitCapacity: {
    min: 0.05,
    max: 999
  },
  fastLimitRecoverScale: {
    min: 0.1,
    max: 10
  },
  predictThd: {
    min: 0.1,
    max: 1
  },
  margin: {
    min: 0.1,
    max: 1
  },
  burst: {
    min: 0.1,
    max: 1
  }
}

const shortFieldName = (field) => {
  if (field && field.indexOf('.') > -1) {
    return field.substring(field.lastIndexOf('.') + 1)
  }
  return field
}

export default class Fields extends React.Component {
  renderField (formData, key) {
    const value = (formData || {})[key]
    if (key == "scene" || key.endsWith('.scene')) {
      return <SelectX style={{ width: '100%' }} label="scene" value={formData[key]}
        onChange={e => {
          formData[key] = e.target.value
          this.setState({})
        }}>
        <MenuItem value="idle">idle</MenuItem>
        <MenuItem value="touch">touch</MenuItem>
        <MenuItem value="boost">boost</MenuItem>
      </SelectX>
    } else if ((typeof value) === 'number') {
      return <NumberInput
              {...(fieldProps[key] || fieldProps[shortFieldName(key)] || {})}
              style={{ margin: '0 0 3px 0' }}
              label={key}
              value={formData[key]}
              helperText={helpText[key] || helpText[shortFieldName(key)]}
              onChange={(value) => {
                formData[key] = value
                this.setState({})
              }} />
    } else if ((typeof value) === 'boolean') {
      return <FormControlLabel
                style={{ width: '100%' }}
                control={(
                  <Checkbox
                    {...(fieldProps[key] || {})}
                    style={{ margin: '0 0 3px 0' }}
                    label={key}
                    checked={formData[key]}
                    onChange={(e) => {
                      formData[key] = e.target.checked
                      this.setState({})
                    }} />
                  )}
                label={<>
                    <small>{key}</small>
                    <small>（{helpText[key]}）</small>
                </>} />
    } else {
      return <TextField variant="filled"
              multiline
              size="small"
              style={{ margin: '0 0 3px 0' }}
              label={key}
              value={formData[key]}
              helperText={helpText[key]}
              onChange={({ target }) => {
                formData[key] = target.value
                this.setState({})
              }} />
    }
  }

  render () {
    const { fields, formData } = this.props
    return <>
      {(fields || []).map(key => this.renderField(formData, key))}
    </>
  }
}
