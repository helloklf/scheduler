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
    const { scene_id, friendly, packages } = this.state
    if (scene_id && packages) {
      this.props.onSave({
        scene_id,
        packages: packages.split(',').map(it => it.trim()),
        friendly
      })
    } else {
      this.setState({
        inputInvalid: true
      })
    }
  }

  render () {
    const { scene_id, friendly, packages, inputInvalid } = this.state
    return (<Box
        
        sx={{
          '& .MuiTextField-root': { m: 1, width: '100%' },
        }}
        noValidate
        autoComplete="off"
      >
      <TextField label="SceneID" variant="outlined"
        value={scene_id} onChange={this.onFiledChange.bind(this, 'scene_id')} />
      <TextField label="Friendly Name" variant="outlined"
        value={friendly} onChange={this.onFiledChange.bind(this, 'friendly')} />
      <TextField label="Packages" variant="outlined"
        value={packages} onChange={this.onFiledChange.bind(this, 'packages')}
        helperText="example: com.google.chrome,com.google.search" />
      <Button onClick={this.props.onCancel}>Cancel</Button>
      <Button onClick={this.onSave.bind(this)}>OK</Button>

      <Dialog
        open={inputInvalid}
        onClose={() => { this.setState({ inputInvalid: false }) }}>
        <DialogTitle>The input is invalid</DialogTitle>
        <DialogContent>
          <DialogContentText id="alert-dialog-description">
            SceneID and Packages are required. And sceneID cannot be repeated.
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
