import React from 'react';
import TextField from '@mui/material/TextField';
import Box from '@mui/material/Box';
import Fields from '../Fields'

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

    return <Box
              
              sx={{
                '& .MuiTextField-root': { margin: '5px 0', width: '100%' },
              }}
              noValidate
              autoComplete="off"
            >
              <Fields fields={Object.keys(value || {})} formData={value || {}} />
            </Box>
  }
}
