import * as React from 'react';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import Box from '@mui/material/Box';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Divider from '@mui/material/Divider';
import Stack from '@mui/material/Stack';
import SaveAltIcon from '@mui/icons-material/SaveAlt';
import UploadIcon from '@mui/icons-material/Upload';
import Typography from '@mui/material/Typography';

class TabCommon extends React.Component {
  constructor (props) {
    super(props)
    this.state = {
      platform: '',
      clusters: []
    }
    try {
      const data = window.ScenePerf.getFrequencies()
      if (data) {
        const clusters = JSON.parse(data)
        this.state = {
          platform: window.ScenePerf.getPlatform(),
          clusters
        }
      }
    } catch (ex) {
    }
  }

  componentDidMount () {
  }

  onChange () {

  }

  downloadFile () {
    this.props.download()
  }

  render () {
    const { platform, platform_name } = this.props
    return (
      <Box
        
        sx={{
          '& .MuiTextField-root': { m: 1, width: '100%' },
        }}
        noValidate
        autoComplete="off"
      >
        <Alert style={{ marginBottom: '1em', fontSize: '12px' }} severity="warning">
          目前，PerfGUI是实验性的，可能会生成错误的配置信息导致性能调节工作异常。GUI所能提供的配置并非全部，详情请参阅下方文档链接。
        </Alert>

        <TextField fullWidth label="platform"
          variant="outlined"
          helperText="example: mt6983"
          style={{ marginTop: '1em' }}
          value={platform || this.state.platform} disabled onChange={this.onChange} />
        <TextField fullWidth label="platformName"
          variant="outlined"
          helperText="Just note, example: 天玑9000"
          style={{ marginTop: '1em' }}
          value={platform_name}
          onChange={this.onChange} />
        <TextField
          fullWidth
          select
          value={120}
          onChange={() => {}}
          label="framework"
          disabled
          helperText=""
          style={{ marginTop: '1em' }}
        >
          <MenuItem value={120}>SCENE 5.2 ~ 5.3</MenuItem>
        </TextField>

        <Stack direction="row" spacing={2}
          divider={<Divider orientation="vertical" flexItem />}
          style={{ marginTop: '2.5em', justifyContent: 'center', width: '100%' }}>
          <Button variant="outlined" endIcon={<SaveAltIcon />} disabled>
            Share
          </Button>
          <Button variant="contained" startIcon={<UploadIcon />} onClick={this.props.apply}>
            Apply
          </Button>
        </Stack>

        <Typography
          style={{ textAlign: 'center', marginTop: '5em', opacity: 0.3 }}
          variant="overline" display="block" gutterBottom>
          The framework was designed by Dudu Ski
        </Typography>
        <Typography
          style={{ textAlign: 'center', marginTop: '0', marginBottom: '5em', opacity: 0.3, fontSize: '9px' }}
          variant="overline" display="block" gutterBottom>
          <a href="https://github.com/helloklf/scheduler" target="_blank">DOCS: https://github.com/helloklf/scheduler</a>
        </Typography>

        <Typography
          style={{ marginTop: '5em', marginBottom: '1em', opacity: 0.3 }}
          variant="overline" display="block" gutterBottom>
          处理器基本信息
        </Typography>
        <Typography
          style={{ marginBottom: '1..5em', fontSize: '9px', opacity: 0.3 }}
          variant="overline" display="block" gutterBottom>
            platform: {this.state.platform}
        </Typography>
        {
          this.state.clusters.map((it, i) => {
            return <Typography
              style={{ marginBottom: '1.5em', fontSize: '9px', opacity: 0.3 }}
              variant="overline" display="block" gutterBottom>
              Cluster{i} cpu [ {(it.cores || []).join(' ')} ]<br/>
              <div style={{ wordBreak: 'break-all', textAlign: 'justify' }}>{(it.frequencies || []).join(' ')}</div>
            </Typography>
          })
        }
      </Box>
    )
  }
}

export default TabCommon
