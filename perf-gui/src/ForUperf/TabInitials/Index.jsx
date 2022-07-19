import { MenuItem } from '@mui/material'
import { Box } from '@mui/system'
import React from 'react'
import CollapseView from '../../components/CollapseView'
import SelectX from '../../components/SelectX'
import Fields from '../Fields'


export default class TabInitials extends React.Component {
  render () {
    const { cpu, sysfs, sched } = this.props.initials

    return <>
            <CollapseView icon="#" title="CPU">
              <Box
                
                sx={{
                  '& .MuiTextField-root': { margin: '5px 0', width: '100%' },
                }}
                noValidate
                autoComplete="off"
              >
                <Fields formData={cpu} fields={[
                  'baseSampleTime',
                  'baseSlackTime',
                  'latencyTime',
                  'fastLimitPower',
                  'fastLimitCapacity',
                  'fastLimitRecoverScale',
                  'predictThd',
                  'margin',
                  'burst',
                  'guideCap',
                  'limitEfficiency',
                ]} />
              </Box>
            </CollapseView>

            <CollapseView icon="#" title="SysFs">
              <Box
                
                sx={{
                  '& .MuiTextField-root': { margin: '5px 0', width: '100%' },
                }}
                noValidate
                autoComplete="off"
              >
                <Fields formData={sysfs} fields={Object.keys(sysfs || {})} />
              </Box>
            </CollapseView>

            <CollapseView icon="#" title="Sched">
              <Box
                
                sx={{
                  '& .MuiTextField-root': { margin: '5px 0', width: '100%' },
                }}
                noValidate
                autoComplete="off"
              >
                <SelectX style={{ width: '100%' }} label="scene" value={sched.scene}
                  onChange={e => {
                    sched.scene = e.target.value
                    this.setState({})
                  }}>
                  <MenuItem value="idle">idle</MenuItem>
                  <MenuItem value="touch">touch</MenuItem>
                  <MenuItem value="boost">boost</MenuItem>
                </SelectX>
              </Box>
            </CollapseView>
          </>
  }
}
