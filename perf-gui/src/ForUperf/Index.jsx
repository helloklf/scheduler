import React from 'react'
import Box from '@mui/material/Box';
import PropTypes from 'prop-types';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import Typography from '@mui/material/Typography';

import TabCommon from './TabCommon/Index';
import TabPresets from './TabPresets/Index';
import MainContext from '../utils/MainContext';
import TabModules from './TabModules/Index'
import TabInitials from './TabInitials/Index'
import TabPerApp from './TabPerApp/TabPerApp'

import template from './template.json'

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
    (window.ScenePerf && window.ScenePerf.getProfile()) || 'null'
  ) || template)

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
        <Tabs value={value} onChange={handleChange} 
          variant="scrollable"
          scrollButtons="auto">
          <Tab label="Common" id={0} />
          <Tab label="Modules" id={1} />
          <Tab label="Initials" id={2} />
          <Tab label="Presets" id={3} />
          <Tab label="Per-App" id={4} />
        </Tabs>
      </Box>
      <MainContext.Provider value={{ alias: profile.initials || [] }}>
        <Box style={{ flex: 1, overflowY: 'auto' }}>
          <TabPanel value={value} index={0}>
            <TabCommon
              {...(profile.meta || {})}
              download={Download}
              apply={Apply} />
          </TabPanel>
          <TabPanel value={value} index={1}>
            <TabModules modules={profile.modules} />
          </TabPanel>
          <TabPanel value={value} index={2}>
            <TabInitials initials={profile.initials} />
          </TabPanel>
          <TabPanel value={value} index={3}>
            <TabPresets presets={profile.presets} />
          </TabPanel>
          <TabPanel value={value} index={4} className="full-size-tab">
            <TabPerApp />
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
