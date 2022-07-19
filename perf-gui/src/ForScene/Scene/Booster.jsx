import React from 'react';
import DrawerView from '../../components/DrawerView';
import CollapseView from '../../components/CollapseView';
import TouchAppIcon from '@mui/icons-material/TouchApp';
import DeviceHubIcon from '@mui/icons-material/DeviceHub';
import CallMadeIcon from '@mui/icons-material/CallMade';
import CallReceivedIcon from '@mui/icons-material/CallReceived';
import Scheme from '../Scheme/Index';
import { Alert, TextField } from '@mui/material';
import { Box } from '@mui/system';

export default class Booster extends React.Component {
  onChange (field, value) {
    const values = this.props.value || {}
    values[field] = value
    this.props.onChange && this.props.onChange(values)
  }

  render () {
    const { enter, exit, duration, events } = this.props.value || {}
    return <Box
            
            sx={{
              '& .MuiTextField-root': { margin: '5px 0', width: '100%' },
            }}
            noValidate
            autoComplete="off"
          >
            <DrawerView icon={<TouchAppIcon />} title="加速器 (booster)">
              <CollapseView icon={<DeviceHubIcon />} title="定义 (definition)">
                <Box
                  
                  sx={{
                    '& .MuiTextField-root': { margin: '5px 0', width: '100%' },
                  }}
                  noValidate
                  autoComplete="off"
                >
                  <TextField label="duration(ms)" size="small"
                    value={duration || 20} onChange={(e) => {
                      this.onChange('duration', e.target.value)
                    }} />
                    <TextField size="small" label="events" variant="filled"
                      multiline
                      value={(events || []).join(', ')}
                      helperText="example: touch, buttons, gpio-keys"
                      onChange={(e) => {
                        this.onChange('events', e.target.value.split(',').map(it => it.trim()).filter(it => !!it))
                      }} />
                </Box>
              </CollapseView>
              <CollapseView icon={<CallMadeIcon />} title="进入加速状态 (enter)">
                <Scheme parcel={false} value={enter} onChange={(value) => {
                  this.onChange('enter', value)
                }} />
              </CollapseView>
              <CollapseView icon={<CallReceivedIcon />} title="退出加速状态 (exit)">
                <Alert severity="info" style={{ fontSize: '10px' }}>Booster会尽量备份和还原Enter中修改的属性，但并不完全可靠。建议在Exit中添加与Enter对称的调用。</Alert>
                <Scheme parcel={false} value={exit} onChange={(value) => {
                  this.onChange('exit', value)
                }} />
              </CollapseView>
            </DrawerView>
          </Box>
  }
}
