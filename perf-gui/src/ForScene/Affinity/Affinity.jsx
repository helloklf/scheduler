import React from 'react';
import TextField from '@mui/material/TextField';
import Box from '@mui/material/Box';
import CollapseView from '../../components/CollapseView';
import Card from '@mui/material/Card';
import CardActions from '@mui/material/CardActions';
import CardContent from '@mui/material/CardContent';
import Button from '@mui/material/Button';
import Typography from '@mui/material/Typography';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import AddIcon from '@mui/icons-material/Add';
import TagIcon from '@mui/icons-material/Tag';
import MemoryIcon from '@mui/icons-material/Memory';

import AffinityCommCreate from './AffinityCommCreate'

let coreCount = 8
try {
  coreCount = parseInt(window.ScenePerf.getCoreCount()) || coreCount
} catch (ex) {}

export default class Affinity extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      newCommForm: ''
    }
  }

  addRule = () => {
    this.setState({
      newCommForm: {
        group: '',
        threads: []
      }
    })
  }

  onCreated = ({ group, threads }) => {
    const value = this.props.value || {}
    const comm = value.comm || {}
    if (comm[group]) {
      const current = comm[group]
      threads.forEach(thread => {
        if (current.indexOf(thread) < 0) {
          current.push(thread)
        }
      })
    } else {
      comm[group] = threads || []
    }
    value.comm = comm

    this.props.onChange && this.props.onChange(value)
    this.setState({
      newCommForm: ''
    })
  }

  onChange (field, value) {
    const values = this.props.value || {}
    values[field] = value
    this.props.onChange && this.props.onChange(values)
  }

  mask2Str (mask) {
    const str = Number.parseInt(mask, 16).toString(2).padStart(coreCount, 0)

    const cores = str.split('').reverse().map(it => parseInt(it))

    return str
  }

  render () {
    const { value } = this.props
    const { newCommForm } = this.state

    return <CollapseView icon={<MemoryIcon />} title="CPU亲和 (affinity)">
      <Box
        
        sx={{
          '& .MuiTextField-root': { margin: '5px 0', width: '100%' },
        }}
        noValidate
        autoComplete="off"
      >
        {value && <>
          <TextField size="small" label="interval(ms)" value={value.interval} onChange={(e) => {
            this.onChange('interval', e.target.value)
          }} inputProps={{ inputMode: 'numeric', pattern: '[0-9]{,6}' }} type="number" />
          <TextField size="small" label="unity_main(mask, hex)" value={value.unity_main} onChange={(e) => {
            this.onChange('unity_main', e.target.value)
          }} inputProps={{ inputMode: 'numeric', pattern: '[0-9a-f]{,3}' }} />
          <TextField size="small" label="other(mask, hex)" value={value.other} onChange={(e) => {
            this.onChange('other', e.target.value)
          }} inputProps={{ inputMode: 'numeric', pattern: '[0-9a-f]{,3}' }} />
          <CollapseView icon={<TagIcon />} title="Customized">
            <div style={{ margin: '0 0 0 55px' }}>
              {
                value.comm && Object.keys(value.comm).map(key => <div>
                  <CollapseView
                    icon={'0x' + (key).toUpperCase()}
                    title={<font style={{ fontFamily: 'monospace' }}>
                      {this.mask2Str(key)}
                    </font>}>
                    {(value.comm[key] || []).map((it, i) => (
                      <TextField variant="filled" multiline size="small" style={{ margin: '0 0 3px 0' }} label="ThreadName(comm)"
                        value={it}
                        onChange={({ target }) => {
                          value.comm[key][i] = target.value
                          this.setState({})
                        }} />
                    ))}
                  </CollapseView>
                </div>)
              }
              {!newCommForm && <ListItemButton style={{ marginTop: '0em' }} onClick={this.addRule} disableGutters>
                <ListItemIcon>
                  <AddIcon />
                </ListItemIcon>
                <ListItemText primary="添加亲和设定" />
              </ListItemButton>}

              {newCommForm && <AffinityCommCreate value={newCommForm}
                onCancel={() => {this.setState({ newCommForm: '' })}}
                onSave={this.onCreated}
                />}
            </div>
          </CollapseView>
        </>}
      </Box>
    </CollapseView>
  }
}
