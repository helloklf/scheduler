import { Checkbox, Stack, MenuItem, TextField, Box } from "@mui/material"
import CollapseView from "../../components/CollapseView"
import DrawerView from "../../components/DrawerView"
import SelectX from '../../components/SelectX'
import ModuleSchedPrioOptions from './ModuleSchedPrioOptions'
import React from "react";

let coreCount = 8
try {
  coreCount = parseInt(window.ScenePerf.getCoreCount()) || coreCount
} catch (ex) {}
const cores = []
for (let i=0; i<coreCount; i++) {
  cores.push(i)
}

export default class ModuleSched extends React.Component {
  onChange (form, field, value) {
    if (value && value.target) {
      form[field] = value.target.value
      this.setState({})
    } else {
      form[field] = value
      this.setState({})
    }
  }

  onCoreCheckedChange (maskGroup, coreIndex, coreSelected) {
    const { cpumask } = this.props.params || {}
    const currentSelected = cpumask[maskGroup]
    const state = [...currentSelected]
    if (coreSelected) {
      if (!state.indexOf(coreIndex) > -1) {
        state.push(coreIndex)
      }
    } else {
      const i = state.indexOf(coreIndex)
      if (i > -1) {
        state.splice(i, 1)
      }
    }
    cpumask[maskGroup] = state.sort()
    this.setState({})
  }

  render () {
    const { cpumask, affinity, prio, rules } = this.props.params || {}

    return <div>
      <CollapseView icon="+" title="CpuMask">
        <div>
          {Object.keys(cpumask || {}).map(key => (<Stack direction={"horizontal"}>
            <div style={{ width: '4em', textAlign: 'right', marginTop: '0.5em', color: '#888' }}>{key}:</div> 
            {cores.map(it => <>
              <Checkbox style={{ padding: '0 6px' }} size="small"
                checked={cpumask[key].indexOf(it) > -1}
                onChange={e => {
                  this.onCoreCheckedChange(key, it, e.target.checked)
                }} />
            </>)}
          </Stack>))}
        </div>
      </CollapseView>

      <CollapseView icon="+" title="Affinity">
        {
          Object.keys(affinity).map(key => (<>
            <DrawerView icon="" key={key} title={key}>
              {Object.keys(affinity[key]).map(g => (
                <SelectX value={affinity[key][g]} label={g}
                  onChange={e => {
                    affinity[key][g] = e.target.value
                    this.setState({})
                  }}>
                  <MenuItem value="">未设置</MenuItem>
                  {Object.keys(cpumask || []).map(key => (<MenuItem value={key}>{key}</MenuItem>))}
                </SelectX>)
              )}
            </DrawerView>
          </>))
        }
      </CollapseView>

      <CollapseView icon="+" title="Priority">
        {
          Object.keys(prio).map(key => (<>
            <DrawerView icon="" key={key} title={key}>
              {Object.keys(prio[key]).map(g => (
                <SelectX
                  style={{ width: '100%' }}
                  value={prio[key][g]} label={g + ' : ' + prio[key][g]}
                  onChange={e => {
                    prio[key][g] = e.target.value
                    this.setState({})
                  }}>
                  {ModuleSchedPrioOptions}
                </SelectX>)
              )}
            </DrawerView>
          </>))
        }
      </CollapseView>

      <CollapseView icon="+" title="Rules">
        {
          (rules || []).map((rule, i) => (<>
            <DrawerView icon="" key={i} title={rule.name || rule.regex}>
              {(rule.rules || []).map(rule => (<>
                <Box
                  
                  sx={{
                    '& .MuiTextField-root': { margin: '5px 0', width: '100%' },
                  }}
                  style={{ marginBottom: '10px' }}
                  noValidate
                  autoComplete="off"
                >
                  <TextField size="small" variant="filled" label="k(keyword)" value={rule.k}
                    onChange={this.onChange.bind(this, rule, 'k')}/>
                  <SelectX value={rule.ac} label="ac(affinity class)"
                    onChange={this.onChange.bind(this, rule, 'ac')}>
                    {Object.keys(affinity).map(key => (<MenuItem value={key}>{key}</MenuItem>))}
                  </SelectX>
                  <SelectX value={rule.pc} label="pc(priority class)"
                    onChange={this.onChange.bind(this, rule, 'pc')}>
                    {Object.keys(prio).map(key => (<MenuItem value={key}>{key}</MenuItem>))}
                  </SelectX>
                </Box>
              </>))}
            </DrawerView>
          </>))
        }
      </CollapseView>
    </div>
  }
}