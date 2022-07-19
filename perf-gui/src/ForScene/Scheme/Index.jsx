import * as React from 'react';
import CollapseView from '../../components/CollapseView';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import PropTypes from 'prop-types';
import AddIcon from '@mui/icons-material/Add';
import ListItemButton from '@mui/material/ListItemButton';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogActions from '@mui/material/DialogActions';
import Button from '@mui/material/Button';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Slider from '@mui/material/Slider';
import Box from '@mui/material/Box';
import DeleteIcon from '@mui/icons-material/Delete';
import { Select, IconButton } from '@mui/material';
import alias from './alias'
import Typography from '@mui/material/Typography';

import PlaylistAddIcon from '@mui/icons-material/PlaylistAdd';
import MainContext from '../../utils/MainContext';

import './Scheme.css'


function valuetext(value) {
  return `${value}Mhz`;
}

const marks = [
  {
    value: 1300,
    label: '1300Mhz',
  },
  {
    value: 1800,
    label: '1800Mhz',
  },
  {
    value: 1900,
    label: '1900Mhz',
  },
  {
    value: 2750,
    label: '2750Mhz',
  },
  {
    value: 3000,
    label: '3000Mhz',
  },
  {
    value: 3050,
    label: '3050Mhz',
  },
];

class Scheme extends React.Component {
  constructor (props) {
    super(props)
    this.state = {
      value: [1300, 3050],
      rangeForm: {
        function: '',
        min: '',
        max: ''
      }
    }
  }

  static contextType = MainContext

  handleChange = (event, newValue) => {
    this.setState({
      value: newValue
    })
  };

  onChange = (row, field, e) => {
    row[field] = e.target.value
    this.setState({})
  }

  addCallItem = () => {
    const value = this.props.value || []
    value.push(["", ""])
    console.log(value)
    this.props.onChange && this.props.onChange(value)
    this.setState({})
  }

  onDelete (row) {
    const value = this.props.value || []
    value.splice(value.indexOf(row), 1)
    this.props.onChange && this.props.onChange(value)
    this.setState({})
  }

  onAliasClick = (aliasName) => {
    const key = aliasName && aliasName.substring(1)
    const contextAlias = this.context && this.context.alias
    if (contextAlias && contextAlias[key]) {
      alert('Custom alias ' + aliasName + " is \n\n" + contextAlias[key])
    } else if (alias[key]) {
      alert('built-in ' + aliasName + " is \n\n" + alias[key])
    } else {
      alert(aliasName + " not found!")
    }
  }

  renderCallItem (item) {
    if (item.length > 0) {
      const key = item[0]
      if (key !== undefined) {
        if (key.indexOf('@') === 0) {
          switch (key) {
            case '@cpuset': {
              return [
                <TextField value={'Func'} label={item[0]} style={{ width: '20%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 0)} disabled />,
                <TextField value={item[1]} label="bg" style={{ width: '19%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 1)} />,
                <TextField value={item[2]} label="sys-bg" style={{ width: '19%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 2)} />,
                <TextField value={item[3]} label="fg" style={{ width: '19%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 3)} />,
                <TextField value={item[4]} label="top-app" style={{ width: '19%', marginRight: '0%' }} size="small"
                  onChange={this.onChange.bind(this, item, 4)} />
              ]
            }
            case '@cpu_freq_min': {
              return [
                <TextField value={'Func'} label={item[0]} style={{ width: '33%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 0)} disabled />,
                <TextField value={item[1]} label="target" style={{ width: '32%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 1)} />,
                <TextField value={item[2]} label="minFreq" style={{ width: '32%', marginRight: '0%' }} size="small"
                  onChange={this.onChange.bind(this, item, 2)} />
              ]
            }
            case '@cpu_freq_max': {
              return [
                <TextField value={'Func'} label={item[0]} style={{ width: '32%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 0)} disabled />,
                <TextField value={item[1]} label="target" style={{ width: '33%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 1)} />,
                <TextField value={item[2]} label="maxFreq" style={{ width: '33%', marginRight: '0%' }} size="small"
                  onChange={this.onChange.bind(this, item, 2)} />
              ]
            }
            case '@cpu_freq': {
              return [
                <TextField value={'Func'} label={item[0]} style={{ width: '25%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 0)} disabled />,
                <TextField value={item[1]} label="target" style={{ width: '24%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 1)} />,
                <TextField value={item[2]} label="minFreq" style={{ width: '24%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 2)} />,
                <TextField value={item[3]} label="maxFreq" style={{ width: '24%', marginRight: '0' }} size="small"
                  onChange={this.onChange.bind(this, item, 3)} />
              ]
            }
            case '@uclamp': {
              return [
                <TextField value={'Func'} label={item[0]} style={{ width: '25%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 0)} disabled />,
                <TextField value={item[1]} label="background" style={{ width: '24%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 1)} />,
                <TextField value={item[2]} label="foreground" style={{ width: '24%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 2)} />,
                <TextField value={item[3]} label="top-app" style={{ width: '24%', marginRight: '0' }} size="small"
                  onChange={this.onChange.bind(this, item, 3)} />
              ]
            }
            case '@gpu_freq': {
              return [
                <TextField value={'Func'} label={item[0]} style={{ width: '32%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 0)} disabled />,
                <TextField value={item[1]} label="minFreq" style={{ width: '33%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 1)} />,
                <TextField value={item[2]} label="maxFreq" style={{ width: '33%', marginRight: '0' }} size="small"
                  onChange={this.onChange.bind(this, item, 2)} />
              ]
            }
            case '@set_priority': {
              return [
                <TextField value={'Func'} label={item[0]} style={{ width: '32%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 0)} disabled />,
                <TextField value={item[1]} label="group" style={{ width: '33%', marginRight: '1%' }} size="small"
                  onChange={this.onChange.bind(this, item, 1)} />,
                <Select value={item[2]} label="level" style={{ width: '33%', marginRight: '0' }} size="small"
                  onChange={this.onChange.bind(this, item, 2)}>
                  <MenuItem value="min">Min</MenuItem>
                  <MenuItem value="low">Low</MenuItem>
                  <MenuItem value="normal">Normal</MenuItem>
                  <MenuItem value="high">Hight</MenuItem>
                  <MenuItem value="max">Max</MenuItem>
                </Select>
              ]
            }
            default: {
              const colCount = item.length
              const colWidth = (100 - colCount + 1) / colCount - 0.001
              return item.map((it, i) => {
                if (i == 0) {
                  return <TextField label={item[i]}
                    style={{ width: '' + colWidth + '%' }} size="small"
                    value={item[i]}
                    onChange={this.onChange.bind(this, item, i)}
                    disabled />
                } else {
                  return <TextField label="param"
                    style={{ width: '' + colWidth + '%', marginLeft: '1%' }} size="small"
                    value={item[i]}
                    onChange={this.onChange.bind(this, item, i)} />
                }
              })
            }
          }
        } else if (key.indexOf('$') === 0) {
          return [
            <TextField value={item[0]} label="path" style={{ width: '49.5%', marginRight: '1%' }} size="small"
              onChange={this.onChange.bind(this, item, 0)}
              onClick={() => {
                this.onAliasClick(item[0])
              }}
              disabled />,
            <TextField value={item[1]} label="value" style={{ width: '49.5%', marginRight: '0' }} size="small"
              onChange={this.onChange.bind(this, item, 1)} />
          ]
        } else {
          return [
            <TextField value={item[0]} label="path" style={{ width: '49.5%', marginRight: '1%' }} size="small"
              onChange={this.onChange.bind(this, item, 0)} />,
            <TextField value={item[1]} label="value" style={{ width: '41.5%', marginRight: '1%' }} size="small"
              onChange={this.onChange.bind(this, item, 1)} />,
            <IconButton disabled={!!item[0]} style={{ width: '7%', textAlign: 'center' }} size="small"
              onClick={this.onDelete.bind(this, item)}>
              <DeleteIcon />
            </IconButton>
          ]
        }
      }
      return (<>
        {JSON.stringify(item)}
      </>)
    } else {
      return null
    }
  }

  parcel (children) {
    const parcel = this.props.parcel
    if (parcel === false) {
      return <>{children}</>
    }
    return <CollapseView icon={<PlaylistAddIcon />} title="调用 (call)">{children}</CollapseView>
  }

  render () {
    const { value } = this.props
    const { rangeForm = {} } = this.state
    return (this.parcel(<>
      <Box className="scheme-form" sx={{ width: '100%', margin: '0', paddingTop: '0em' }}>
        {(value || []).map(it => <div style={{ margin: '10px 0 0 0' }}>{this.renderCallItem(it)}</div>)}
        <ListItemButton style={{ marginTop: '0em' }} onClick={this.addCallItem} disableGutters>
          <ListItemIcon>
            <AddIcon />
          </ListItemIcon>
          <ListItemText primary="添加调用" />
        </ListItemButton>
      </Box>

      <Dialog open={rangeForm.function} onClose={() => {}}>
        <DialogTitle>{rangeForm.function}</DialogTitle>
        <DialogContent>
          <DialogContentText>{rangeForm.min} ~ {rangeForm.max}</DialogContentText>
          <div style={{ margin: '0 5px', minWidth: '270px' }}>
            <Slider
              size="small"
              getAriaLabel={() => 'Temperature range'}
              value={this.state.value}
              onChange={this.handleChange}
              marks={marks}
              step={null}
              min={1300} max={3050}
              getAriaValueText={valuetext}
            />
          </div>
          {/* <TextField
            autoFocus
            margin="dense"
            id="name"
            label="Email Address"
            type="email"
            fullWidth
            variant="standard"
          /> */}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => {}}>Cancel</Button>
          <Button onClick={() => {}}>Commit</Button>
        </DialogActions>
      </Dialog>
    </>))
  }
}

export default Scheme
