import React from 'react'
import DrawerView from '../../components/DrawerView';
import DeviceThermostatIcon from '@mui/icons-material/DeviceThermostat';
import SensorsIcon from '@mui/icons-material/Sensors';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import AddIcon from '@mui/icons-material/Add';

import Sensor from './Sensor'

export default class Sensors extends React.Component {
  shortName (sensor) {
    if (sensor && sensor.indexOf('/') > -1) {
      return '***' + sensor.substring(sensor.lastIndexOf('/'))
    }
    return sensor
  }

  addCallItem = () => {
    const value = this.props.value || []
    value.push({
      sensor: '',
      interval: 2000,
      disable: false,
      rules: []
    })
    this.props.onChange && this.props.onChange(value)
  }

  render () {
    const { value } = this.props
    return <DrawerView icon={<SensorsIcon />} title="传感器 (sensors)">
      {(value || []).map(it => (
        <DrawerView icon={<DeviceThermostatIcon />}
          title={this.shortName(it.sensor || '') || '未完成的 / unfinished'}>
          <Sensor {...it} onChange={(field, value) => {
            it[field] = value
            this.setState({})
          }} onDelete={() => {
            value.splice(value.indexOf(it), 1)
            this.setState({})
          }} />
        </DrawerView>
      ))}
      <ListItemButton style={{ marginTop: '0em' }} onClick={this.addCallItem} disableGutters>
        <ListItemIcon>
          <AddIcon />
        </ListItemIcon>
        <ListItemText primary="添加传感器" />
      </ListItemButton>
    </DrawerView>
  }
}
