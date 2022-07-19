import { TextField } from '@mui/material'
import React from 'react'

export default class NumberInput extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      value: null
    }
  }

  onChange = (e) => {
    const value = e.target.value
    this.setState({
      value: value
    })
  }

  onBlur = () => {
    const value = this.state.value || ''
    this.setState({
      value: null
    })
    const r = parseFloat(value)
    if (!isNaN(r)) {
      const { max, min } = this.props
      if (max !== undefined && r > max) {
        return
      }
      if (min !== undefined && r < min) {
        return
      }
      this.props.onChange && this.props.onChange(r)
    }
  }

  render () {
    return <TextField
              size="small"
              variant="filled"
              {...(this.props)}
              min={undefined}
              max={undefined}
              onChange={this.onChange}
              onBlur={this.onBlur}
              value={this.state.value == null ? this.props.value : this.state.value}
              inputProps={{ inputMode: 'numeric', pattern: '[0-9]*' }} />
  }
}