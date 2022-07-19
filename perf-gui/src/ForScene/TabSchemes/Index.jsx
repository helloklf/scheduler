import * as React from 'react';
import ListSubheader from '@mui/material/ListSubheader';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Collapse from '@mui/material/Collapse';
import InboxIcon from '@mui/icons-material/MoveToInbox';
import DraftsIcon from '@mui/icons-material/Drafts';
import SendIcon from '@mui/icons-material/Send';
import ExpandLess from '@mui/icons-material/ExpandLess';
import ExpandMore from '@mui/icons-material/ExpandMore';
import StarBorder from '@mui/icons-material/StarBorder';

import AutoStories from '@mui/icons-material/AutoStories';
import EnergySavingsLeafIcon from '@mui/icons-material/EnergySavingsLeaf';
import AcUnitIcon from '@mui/icons-material/AcUnit';
import RocketLaunchIcon from '@mui/icons-material/RocketLaunch';
import VideogameAssetIcon from '@mui/icons-material/VideogameAsset';

import Scheme from '../Scheme/Index';
import { ListItem } from '@mui/material';

class TabSchemes extends React.Component {
  constructor (props) {
    super(props)
    this.state = {
      list: [{
        friendly: '省电模式(powersave)',
        sceneId: 'powersave',
        icon: <AutoStories />
      }, {
        friendly: '均衡模式(balance)',
        sceneId: 'balance',
        icon: <EnergySavingsLeafIcon />
      }, {
        friendly: '性能模式(performance)',
        sceneId: 'performance',
        icon: <VideogameAssetIcon />
      }, {
        friendly: '极速模式(fast)',
        sceneId: 'fast',
        icon: <RocketLaunchIcon />
      }, {
        friendly: '底座模式(pedestal)',
        sceneId: 'pedestal',
        icon: <AcUnitIcon />
      }],
      current: ''
    }
    if (props.schemes) {
      this.state.list[0].call = props.schemes.powersave && props.schemes.powersave.call
      this.state.list[1].call = props.schemes.balance && props.schemes.balance.call
      this.state.list[2].call = props.schemes.performance && props.schemes.performance.call
      this.state.list[3].call = props.schemes.fast && props.schemes.fast.call
      this.state.list[4].call = props.schemes.pedestal && props.schemes.pedestal.call
    }
  }

  setCurrent (current) {
    if (this.state.current === current) {
      this.setState({
        current: ''
      })
    } else {
      this.setState({
        current: current
      })
    }
  }

  render () {
    const { list, current } = this.state
    return <>
      {list.map(it => <div key={it.sceneId}>
        <ListItemButton disableGutters onClick={this.setCurrent.bind(this, it.sceneId)}>
          <ListItemIcon>
            {it.icon}
          </ListItemIcon>
          <ListItemText primary={it.friendly || '未命名'} />
          {current === it.sceneId ? <ExpandLess /> : <ExpandMore />}
        </ListItemButton>
        <Collapse in={current === it.sceneId} timeout="auto">
          <List component="div" disablePadding>
            <Scheme parcel={false} value={it.call} onChange={call => it.call = call} />
          </List>
        </Collapse>
      </div>)}
    </>
  }
}

export default TabSchemes
