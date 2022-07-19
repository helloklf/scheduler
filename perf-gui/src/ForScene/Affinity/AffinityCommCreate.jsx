import { Button, TextField } from '@mui/material';
import { Box } from '@mui/system';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogTitle from '@mui/material/DialogTitle';
import * as React from 'react';

class SceneCreate extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      ...(this.props.value || {}),
      inputInvalid: false
    }
  }

  onFiledChange (filed, e) {
    if (filed) {
      this.setState({
        [filed]: e.target.value
      })
    }
  }

  onSave () {
    const { group, threads } = this.state
    if (group && threads) {
      this.props.onSave({
        group,
        threads: threads.split(',').map(it => it.trim())
      })
    } else {
      this.setState({
        inputInvalid: true
      })
    }
  }

  render () {
    const { group, threads, inputInvalid } = this.state
    return (<Box
        
        sx={{
          '& .MuiTextField-root': { m: 1, width: '100%' },
        }}
        noValidate
        autoComplete="off"
      >
      <TextField label="Cpus(Mask)" variant="outlined" size="small"
        value={group} onChange={this.onFiledChange.bind(this, 'group')} />
      <TextField label="Threads" variant="outlined" size="small"
        value={threads} onChange={this.onFiledChange.bind(this, 'threads')} />
      <Button onClick={this.props.onCancel}>Cancel</Button>
      <Button onClick={this.onSave.bind(this)}>OK</Button>

      <Dialog
        open={inputInvalid}
        onClose={() => { this.setState({ inputInvalid: false }) }}>
        <DialogTitle>The input is invalid</DialogTitle>
        <DialogContent>
          <DialogContentText id="alert-dialog-description">
            Cpus(Mask) and Threads are required. And Cpus(Mask) cannot be repeated.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { this.setState({ inputInvalid: false }) }} autoFocus>OK</Button>
        </DialogActions>
      </Dialog>
    </Box>)
  }
}

export default SceneCreate
