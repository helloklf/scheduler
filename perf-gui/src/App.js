import * as React from 'react';

import ForScene from './ForScene/Index'
import ForUperf from './ForUperf/Index'

import './App.css'

export default function RangeSlider() {
  const [value, setValue] = React.useState(0);
  const [profile, setProfile] = React.useState(JSON.parse(
    (window.ScenePerf && window.ScenePerf.getProfile()) || '{}'
  ))

  const handleChange = (event, newValue) => {
    setValue(newValue);
  };

  const isScene = window.ScenePerf && window.ScenePerf.getFramework().toLowerCase().indexOf('scene') > -1

  return (isScene ? <ForScene /> : <ForUperf />);
}