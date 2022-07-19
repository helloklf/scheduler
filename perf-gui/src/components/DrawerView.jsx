import React from 'react';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Collapse from '@mui/material/Collapse';
import ExpandLess from '@mui/icons-material/ExpandLess';
import ExpandMore from '@mui/icons-material/ExpandMore';
import CloseIcon from '@mui/icons-material/Close';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import { Divider, Drawer } from '@mui/material';

export default class DrawerView extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      visible: false
    }
  }

  render () {
    const { title, children, icon } = this.props
    const { visible } = this.state
    return (<>
      <ListItemButton disableGutters onClick={() => {
        this.setState({
          visible: !this.state.visible
        })
      }}>
        <ListItemIcon>
          {icon}
        </ListItemIcon>
        <ListItemText primary={title} />
        {visible ? <MoreVertIcon /> : <MoreVertIcon />}
      </ListItemButton>

      <Drawer
        open={visible}
        onClose={() => {
          this.setState({
            visible: false
          })
        }}
        anchor="bottom" timeout="auto">
        <div style={{ padding: '10px 30px 20px 30px', minHeight: '270px' }}>
          <ListItemButton
            disableGutters
            style={{ opacity: '0.4' }}
            onClick={() => {
              this.setState({
                visible: false
              })
            }}>
            <ListItemIcon>{icon}</ListItemIcon>
            <ListItemText primary={title} />
            <CloseIcon />
          </ListItemButton>
          <Divider></Divider>

          {children}
        </div>
      </Drawer>
    </>)
  }
}
