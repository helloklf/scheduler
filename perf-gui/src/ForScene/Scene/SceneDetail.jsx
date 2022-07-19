import React from 'react';
import ListSubheader from '@mui/material/ListSubheader';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import Box from '@mui/material/Box';
import OutlinedInput from '@mui/material/OutlinedInput';
import Alert from '@mui/material/Alert';
import MenuItem from '@mui/material/MenuItem';
import FormControl from '@mui/material/FormControl';
import Select, { SelectChangeEvent } from '@mui/material/Select';
import AddIcon from '@mui/icons-material/Add';
import TabSchemes from '../TabSchemes/Index.jsx';
import Affinity from '../Affinity/Affinity';
import SceneDetail from '../Scene/SceneDetail';
import CollapseView from '../../components/CollapseView';
import DrawerView from '../../components/DrawerView';
import Divider from '@mui/material/Divider';
import TuneIcon from '@mui/icons-material/Tune';
import PlaylistAddIcon from '@mui/icons-material/PlaylistAdd';

import Scheme from '../Scheme/Index';
import SceneDetailMode from './SceneDetail.Mode.jsx'
import Booster from './Booster.jsx';
import SensorsIcon from '@mui/icons-material/Sensors';
import Sensors from './Sensors'

const supportedAll = (['powersave', 'balance', 'performance', 'fast', 'pedestal'])

export default class SceneDetails extends React.Component {
  constructor (props) {
    super(props)
    this.state = {}
  }

  // 是否还缺少任意模式下的设定
  get anyDeficiency () {
    return this.optionalModes.length > 0
  }

  addMode = () => {
    this.setState({
      newModeTarget: []
    })
  }

  get optionalModes () {
    const modes = (this.props.value || {}).modes || []
    const sets = []
    modes.map(it => it.mode || []).forEach(items => {
      items.forEach(mode => {
        sets.push(mode)
      })
    })
    if (modes.indexOf('*') > -1) {
      return []
    }

    let notHint = []
    const supportedAll = (['powersave', 'balance', 'performance', 'fast', 'pedestal'])
    supportedAll.forEach(it => {
      if (sets.indexOf(it) < 0) {
        notHint.push(it)
      }
    })
    console.log(notHint, sets)

    return notHint
  }

  onSave () {
    const newModeTarget = this.state.newModeTarget
    if (newModeTarget && newModeTarget.length > 0) {
      const value = this.props.value || {}
      const modes = value.modes || []
      modes.push({
        mode: newModeTarget,
        logger: false
      })
      value.modes = modes
      this.props.onChange && this.props.onChange(value)
      this.setState({})
    }
    this.setState({
      newModeTarget: ''
    })
  }

  render () {
    const it = this.props.value || {}
    const anyDeficiency = this.anyDeficiency
    const { newModeTarget } = this.state

    return <>
      <Alert severity="info" style={{ fontSize: '11px' }}>{(it.packages || []).join(', ')}</Alert>
      <DrawerView icon={<TuneIcon />} title="公共设定 (common)">
        <Scheme value={it.call} onChange={call => {
          it.call = call
          this.setState({})
        }} />
        <Affinity value={it.affinity || {}} onChange={affinity => {
          it.affinity = affinity
          this.setState({})
        }} />
        <Sensors value={it.sensors || []} onChange={sensors => {
          it.sensors = sensors
          this.setState({})
        }} />
        <Booster value={it.booster || {}} onChange={booster => {
          it.booster = booster
          this.setState({})
        }} />
      </DrawerView>

      <DrawerView icon={<TuneIcon />} title="特定模式 (modes)">
        {(it.modes || []).map(it => (<SceneDetailMode value={it} />))}
        { !newModeTarget && anyDeficiency && <ListItemButton style={{ marginTop: '0em' }} onClick={this.addMode} disableGutters>
            <ListItemIcon>
              <AddIcon />
            </ListItemIcon>
            <ListItemText primary="添加模式设定" />
          </ListItemButton>
        }
        {newModeTarget && <Box
            
            sx={{
              '& .MuiTextField-root': { m: 1, width: '100%' },
            }}
            noValidate
            autoComplete="off"
          >
          <div>
            <Select
              style={{ width: '100%' }}
              multiple
              size="small"
              value={newModeTarget || []}
              onChange={({ target }) => {
                this.setState({ newModeTarget: target.value })
              }}
              input={<OutlinedInput label="Name" />}
              >
              {this.optionalModes.map((name) => (
                <MenuItem
                  key={name}
                  value={name}
                >
                  {name}
                </MenuItem>
              ))}
            </Select>
          </div>
          <Button onClick={() => {
            this.setState({
              newModeTarget: ''
            })
          }}>Cancel</Button>
          <Button onClick={this.onSave.bind(this)}>OK</Button>
        </Box>
        }
      </DrawerView>
    </>
  }
}
