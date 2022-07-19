import React from "react";
import { FormControl, FormControlLabel, MenuItem, InputLabel, Select, Switch, TextField, Button } from '@mui/material'

export default class SelectX extends React.Component {
  render () {
    return (<FormControl style={this.props.style} variant="filled" size="small" sx={{ minWidth: '50%' }}>
              <InputLabel id="module-log-level">{this.props.label}</InputLabel>
              <Select
                size="small"
                labelId="module-log-level"
                value={this.props.value}
                onChange={(e) => {
                  this.props.onChange && this.props.onChange(e)
                }}
              >
                {this.props.children}
              </Select>
            </FormControl>)
  }
}