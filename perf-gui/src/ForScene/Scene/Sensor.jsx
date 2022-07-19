import { Checkbox, FormControlLabel, TextField, Stack, InputAdornment, Alert, Button, Divider } from '@mui/material'
import { Box } from '@mui/system'
import CollapseView from '../../components/CollapseView';
import RuleIcon from '@mui/icons-material/Rule';
import AvTimerIcon from '@mui/icons-material/AvTimer';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import AddIcon from '@mui/icons-material/Add';
import DeleteIcon from '@mui/icons-material/Delete';
import IconButton from '@mui/material/IconButton';

import Scheme from '../Scheme/Index'
import React from 'react'

export default class Sensor extends React.Component {
  onChange (field, value) {
    this.props.onChange && this.props.onChange(field, value)
  }

  addRule = () => {
    const rules = this.props.rules || []
    rules.push({
      threshold: [-1, -1],
      enter: []
    })

    this.onChange('rules', rules)
  }

  deleteSensor = () => {
    if (this.props.onDelete) {
      this.props.onDelete()
    }
  }

  render () {
    const { sensor, interval, disable, rules } = this.props
    return <Box
      sx={{
        '& .MuiTextField-root': { width: '100%' },
      }}
      noValidate
      autoComplete="off"
    >
      <CollapseView icon={<AvTimerIcon />} title="定义 / definition">
        <Alert severity="info" style={{ fontSize: '11px', marginBottom: '10px' }}>sensor name or An absolute path to a file, Make sure that the sensor value you specify is a number. example: bat</Alert>
        <TextField label="sensor" size="small"
          value={sensor}
          onChange={(e) => {
            this.onChange('sensor', e.target.value)
          }} />
        <TextField label="interval(ms)" size="small"
          style={{ marginTop: '0.5em', width: '40%' }}
          value={interval}
          InputProps={{
            inputMode: 'numeric',
            pattern: '[0-9]*'
          }}
          onChange={(e) => {
            this.onChange('interval', e.target.value)
          }} />
        <FormControlLabel
          style={{ marginLeft: '-2px', marginTop: '0.5em', marginLeft: '1em' }}
          control={
            <Checkbox label="interval(ms)" size="small"
            onChange={(e) => {
              this.onChange('disable', e.target.checked)
            }}
            checked={disable} />
          }
          label="disable" />
        <IconButton onClick={this.deleteSensor} variant="outlined" size="small" color="error" style={{ marginTop: '0.5em', marginLeft: '1em' }}>
          <DeleteIcon />
        </IconButton>
      </CollapseView>

      <CollapseView icon={<RuleIcon />} title="规则 (rules)">
        <div style={{ padding: '0 0 0px 0' }}>
          {(rules || []).map((it, i) => (
            <CollapseView icon={` [ ${i+1} ] `}
              title={`threshold [${it.threshold[0]}, ${it.threshold[1]}]`}>
              <div style={{ padding: '10px 10px 0 10px', background: 'rgba(0,148,255, 0.1)', borderRadius: '5px' }}>
                <Stack direction="row" spacing={1}>
                  <div style={{ paddingTop: '10px' }}>threshold&nbsp;</div>
                  <TextField size="small"
                    value={it.threshold[0]} onChange={e => {
                      it.threshold[0] = e.target.value
                      this.onChange('rules', rules)
                    }}
                    InputProps={{
                      inputMode: 'numeric',
                      pattern: '[0-9]*',
                      startAdornment: <InputAdornment position="start">&lt;</InputAdornment>,
                    }} />
                  <div style={{ paddingTop: '10px' }}>&amp;&amp;&nbsp;</div>
                  <TextField size="small"
                    value={it.threshold[1]} onChange={e => {
                      it.threshold[1] = e.target.value
                      this.onChange('rules', rules)
                    }}
                    InputProps={{
                      inputMode: 'numeric', pattern: '[0-9]*',
                      startAdornment: <InputAdornment position="start">&gt;=</InputAdornment>
                    }} />
                </Stack>
                <Divider style={{ marginTop: '10px' }}></Divider>
                <Scheme parcel={false} value={it.enter || []} onChange={call => {
                  it.enter = call
                  this.onChange('rules', rules)
                }} />
              </div>
            </CollapseView>
          ))}
          <ListItemButton style={{ marginTop: '0em' }} onClick={this.addRule} disableGutters>
            <ListItemIcon>
              <AddIcon />
            </ListItemIcon>
            <ListItemText primary="添加规则" />
          </ListItemButton>
        </div>
      </CollapseView>
    </Box>
  }
}
