import React from 'react'
import Box from '@mui/material/Box';
import PropTypes from 'prop-types';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import Typography from '@mui/material/Typography';

import TabCommon from './TabCommon/Index';
import TabSchemes from './TabSchemes/Index';
import TabScenes from './TabScenes/Index';
import MainContext from '../utils/MainContext';


function TabPanel(props) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ p: 3 }} noValidate>
          <Typography>{children}</Typography>
        </Box>
      )}
    </div>
  );
}

TabPanel.propTypes = {
  children: PropTypes.node,
  index: PropTypes.number.isRequired,
  value: PropTypes.number.isRequired,
};

export default function RangeSlider(props) {
  const [value, setValue] = React.useState(0);
  const [profile, setProfile] = React.useState(JSON.parse(
    (window.ScenePerf && window.ScenePerf.getProfile()) || '{}'
  ))

  const handleChange = (event, newValue) => {
    setValue(newValue);
  };

  const Download = () => {
    window.ScenePerf.exportProfile(JSON.stringify(profile))
  }

  const Apply = () => {
    window.ScenePerf.saveProfile(JSON.stringify(profile))
  }

  return (
    <Box sx={{ width: '100%', height: '100vh', flexDirection: 'column', display: 'flex' }}>
      <Box sx={{ borderBottom: 1, borderColor: 'divider', paddingBottom: '0px' }}>
        <Tabs value={value} onChange={handleChange} centered>
          <Tab label="Common" id={0} />
          <Tab label="Schemes" id={1} />
          <Tab label="Scenes" id={2} />
          <Tab label="Docs" id={3} />
        </Tabs>
      </Box>
      <MainContext.Provider value={{ alias: profile.alias || [] }}>
        <Box style={{ flex: 1, overflowY: 'auto' }}>
          <TabPanel value={value} index={0}>
            <TabCommon platform_name={profile.platform_name || profile.platformName}
              download={Download}
              apply={Apply} />
          </TabPanel>
          <TabPanel value={value} index={1}>
            <TabSchemes schemes={profile.schemes} />
          </TabPanel>
          <TabPanel value={value} index={2}>
            <TabScenes value={profile.apps} onChange={(apps) => {
              profile.apps = apps
              this.setState({})
            }} />
          </TabPanel>
          <TabPanel value={value} index={3} className="full-size-tab">
           {/* 
              <code style={{ fontSize: '9px', textAlign: 'justify', whiteSpace: 'pre-wrap', lineHeight: '10px' }}>{JSON.stringify(
              profile,
            null, 2)}</code>
           */}
          </TabPanel>
        </Box>
      </MainContext.Provider>
    </Box>)
}
