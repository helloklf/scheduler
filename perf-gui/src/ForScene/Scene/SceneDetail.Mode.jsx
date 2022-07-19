import React from 'react'
import Scheme from '../Scheme/Index';
import CollapseView from '../../components/CollapseView';
import Booster from './Booster.jsx';
import Affinity from '../Affinity/Affinity';

import AutoStories from '@mui/icons-material/AutoStories';
import EnergySavingsLeafIcon from '@mui/icons-material/EnergySavingsLeaf';
import AcUnitIcon from '@mui/icons-material/AcUnit';
import RocketLaunchIcon from '@mui/icons-material/RocketLaunch';
import VideogameAssetIcon from '@mui/icons-material/VideogameAsset';
import WorkspacesIcon from '@mui/icons-material/Workspaces';

import Sensors from './Sensors';

const iconMap = {
  powersave: <AutoStories style={{ opacity: 0.7, marginRight: '10px' }} />,
  balance: <EnergySavingsLeafIcon style={{ opacity: 0.7, marginRight: '10px' }} />,
  performance: <VideogameAssetIcon style={{ opacity: 0.7, marginRight: '10px' }} />,
  fast: <RocketLaunchIcon style={{ opacity: 0.7, marginRight: '10px' }} />,
  pedestal: <AcUnitIcon style={{ opacity: 0.7, marginRight: '10px' }} />,
  '*': <WorkspacesIcon style={{ opacity: 0.7, marginRight: '10px' }} />
}

export default class SceneDetailMode extends React.Component {
  render () {
    const value = this.props.value || {}
    return <div>
      <CollapseView icon={<>{(value.mode || []).map(it => (iconMap[it] || null))}</>} title={(value.mode || []).join(', ')}>
        <div style={{ paddingBottom: '30px' }}>
          <Scheme value={value.call} onChange={call => {
            value.call = call
            this.setState({})
          }} />
          <Affinity value={value.affinity || []} onChange={affinity => {
            value.affinity = affinity
            this.setState({})
          }} />
          <Sensors value={value.sensors || []} onChange={sensors => {
            value.sensors = sensors
            this.setState({})
          }} />
          <Booster value={value.booster || {}} onChange={booster => {
            value.booster = booster
            this.setState({})
          }} />
        </div>
      </CollapseView>
    </div>
  }
}
