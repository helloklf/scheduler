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


import CollapseView from '../../components/CollapseView';

import AutoStories from '@mui/icons-material/AutoStories';
import EnergySavingsLeafIcon from '@mui/icons-material/EnergySavingsLeaf';
import AcUnitIcon from '@mui/icons-material/AcUnit';
import RocketLaunchIcon from '@mui/icons-material/RocketLaunch';
import VideogameAssetIcon from '@mui/icons-material/VideogameAsset';

import Preset from './Preset'

import { Alert, ListItem } from '@mui/material';

const stateMap = {
  '*': '默认值',
  'idle': '一般状态时',
  'touch': '触摸屏幕/按下按键时',
  'trigger': '点击操作离开屏幕/滑动操作起始时',
  'gesture': '全面屏手势时',
  'switch': '应用切换动画/点亮屏幕时',
  'junk': 'touch/gesture中sfanalysis检测到掉帧时',
  'swjunk': 'switch中sfanalysis检测到掉帧时'
}

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
      }],
      current: ''
    }
    if (props.presets) {
      this.state.list[0].fields = props.presets.powersave && props.presets.powersave || {}
      this.state.list[1].fields = props.presets.balance && props.presets.balance || {}
      this.state.list[2].fields = props.presets.performance && props.presets.performance || {}
      this.state.list[3].fields = props.presets.fast && props.presets.fast || {}
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
        <Collapse in={current === it.sceneId} timeout="auto" unmountOnExit>
          <List component="div" disablePadding>
            {Object.keys(it.fields).map(state => (
              <CollapseView icon={'#'} title={state} key={state}>
                <Alert severity="info" style={{ marginBottom: '1em' }}>{stateMap[state]}</Alert>
                <Preset value={(it.fields || {})[state]} />
              </CollapseView>)
            )}
          </List>
        </Collapse>
      </div>)}
      <Alert severity="info" style={{ marginBottom: '1em', marginTop: '2em', fontSize: '10px' }}>
        Uperf中没有单独的pedestal设定档，如果配合SCENE使用，pedestal实际对应performance设定档
      </Alert>
    </>
  }
}

export default TabSchemes
