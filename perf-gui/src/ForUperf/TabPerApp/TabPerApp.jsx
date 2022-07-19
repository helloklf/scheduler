import { Box, Button, Divider, Stack, TextField } from "@mui/material"
import SaveAltIcon from '@mui/icons-material/SaveAlt';
import Sync from '@mui/icons-material/Sync';
import React from "react"

const prefix = `# 分应用性能模式配置
# Per-app dynamic power mode rule
# '-' means offscreen rule
# '*' means default rule

`
export default class TabPerApp extends React.Component {
  constructor(props) {
    super(props)
    this.state = {}
  }

  componentWillMount () {
    this.getCurrentConfig()
  }

  getCurrentConfig () {
    try {
      const current = window.ScenePerf && window.ScenePerf.readPerApp()
      this.setState({
        config: current
      })
    } catch(ex) {
      alert(ex.message)
    }
  }

  importSceneConfig = () => {
    const config = window.ScenePerf && window.ScenePerf.getSceneConfig()
    if (config) {
      /*
        # 分应用性能模式配置
        # Per-app dynamic power mode rule
        # '-' means offscreen rule
        # '*' means default rule

        com.miHoYo.Yuanshen fast
        - balance
        * balance
      */

      const result = JSON.parse(config)
      const apps = result.apps || []
      const global = result.global || 'balance'
      const standby = result.standby || 'powersave'
      const rows = apps.filter(it => !(it.endsWith(global) || it.endsWith('igoned'))).map(it => {
        const row = it.replace('=', ' ')
        if (row.indexOf('performance') > 0) {
          return row.replace(' performance', ' fast')
        } else {
          return row.replace(' fast', ' performance')
        }
      }).join('\n')
      this.setState({
        config: prefix + rows + `\n- ${standby}\n* ${global}`
      })
    }
  }

  saveConfig = () => {
    const result = window.ScenePerf && window.ScenePerf.savePerApp(this.state.config)
    if (result) {
      alert('OK')
    }
  }

  render () {
    return (<Box
      sx={{
        '& .MuiTextField-root': { margin: '5% 5%', width: '90%' },
      }}
      noValidate
      autoComplete="off"
    >
      <TextField multiline minRows={20} value={this.state && this.state.config} size="small" />
      <Stack direction="row" spacing={2}
        divider={<Divider orientation="vertical" flexItem />}
        style={{ paddingBottom: '20px', marginTop: '0.5em', justifyContent: 'center', width: '100%' }}>
        <Button variant="outlined" endIcon={<Sync />} onClick={this.importSceneConfig}>
          从SCENE导入
        </Button>
        <Button variant="contained" startIcon={<SaveAltIcon />} onClick={this.saveConfig}>
          保存PerApp
        </Button>
      </Stack>
    </Box>)
  }
}
