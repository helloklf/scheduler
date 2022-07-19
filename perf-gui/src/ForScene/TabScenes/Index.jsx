import * as React from 'react';
import ListSubheader from '@mui/material/ListSubheader';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Collapse from '@mui/material/Collapse';
import ExpandLess from '@mui/icons-material/ExpandLess';
import ExpandMore from '@mui/icons-material/ExpandMore';
import StarBorder from '@mui/icons-material/StarBorder';
import GradeIcon from '@mui/icons-material/Grade';
import AddIcon from '@mui/icons-material/Add';
import SceneDetail from '../Scene/SceneDetail'

import Scheme from '../Scheme/Index';
import SceneCreate from '../Scene/SceneCreate'
import { Button, Drawer, ListItem } from '@mui/material';

import AutoStories from '@mui/icons-material/AutoStories';
import EnergySavingsLeafIcon from '@mui/icons-material/EnergySavingsLeaf';
import AcUnitIcon from '@mui/icons-material/AcUnit';
import RocketLaunchIcon from '@mui/icons-material/RocketLaunch';
import VideogameAssetIcon from '@mui/icons-material/VideogameAsset';

class TabScenes extends React.Component {
  constructor (props) {
    super(props)
    this.state = {
      list: [{
        friendly: '原神',
        scene_id: 'scene-ys'
      }, {
        friendly: '游戏/大型游戏',
        scene_id: 'scene-gaming'
      }, {
        friendly: '社交/IM/通信',
        scene_id: 'scene-im'
      }, {
        friendly: '阅读/新闻/小说',
        scene_id: 'scene-reader'
      }, {
        friendly: '短视频/娱乐视频',
        scene_id: 'scene-short-video'
      }, {
        friendly: '视频应用/电影',
        scene_id: 'scene-video'
      }, {
        friendly: '通用',
        scene_id: 'scene-common'
      }],
      current: '',
      newSceneForm: ''
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

  createScene () {
    this.setState({
      newSceneForm: {
        scene_id: '',
        friendly: '自定义场景',
        packages: '*',
        call: []
      }
    })
  }

  onSceneCreated (scene) {
    const list = this.props.value || []
    const { scene_id, packages } = scene
    if (list.find(it => {
      return it.scene_id == scene_id
    })) {
      alert('The SceneID[' + scene_id + '] already exists')
      return
    }

    let exists = []
    list.forEach(it => {
      let apps = (it.packages || [])
      packages.forEach(pkg => {
        if (apps.indexOf(pkg) > -1){
          exists.push(pkg)
        }
      })
    })
    if (exists.length > 0) {
      alert('The Packages[' + exists.join(', ') + '] already exists')
      return
    }

    if (packages.indexOf('*') > -1) {
      list.push(scene)
    } else {
      list.unshift(scene)
    }
    this.setState({
      current: '',
      newSceneForm: ''
    })
    this.props.onChange && this.props.onChange(list)
  }

  render () {
    const { current, newSceneForm } = this.state
    const list = this.props.value || []
    return <>
      {list.map(it => <div>
        <ListItemButton disableGutters onClick={this.setCurrent.bind(this, it.scene_id || it.friendly)}>
          <ListItemIcon>
            <GradeIcon />
          </ListItemIcon>
          <ListItemText primary={it.friendly || '未命名'} />
          {current === it.scene_id || current === it.friendly ? <ExpandLess /> : <ExpandMore />}
        </ListItemButton>
        <Collapse in={current === it.scene_id || current === it.friendly} timeout="auto">
          <List component="div" disablePadding>
            <SceneDetail value={it}></SceneDetail>
          </List>
        </Collapse>
      </div>)}

      {!newSceneForm && <ListItemButton onClick={this.createScene.bind(this)} style={{ marginTop: '1em' }} disableGutters>
        <ListItemIcon>
          <AddIcon />
        </ListItemIcon>
        <ListItemText primary="添加场景" />
      </ListItemButton>}

      {newSceneForm && <SceneCreate value={newSceneForm}
        onCancel={() => {this.setState({ newSceneForm: '' })}}
        onSave={this.onSceneCreated.bind(this)}
        />}
    </>
  }
}

export default TabScenes
