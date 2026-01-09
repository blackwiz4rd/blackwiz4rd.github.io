---
layout: post
title: "PUN vs PSV in Home Assistant"
description: >
  Visualizing PUN and PSV indices in Home Assistant
noindex: true
---

The following pages:

- https://luceegasitalia.it/indici-pun-e-psv/psv/  
- https://luceegasitalia.it/indici-pun-e-psv/pun/  

provide access to historical data for the **PUN** and **PSV** indices.  
Being able to visualize these values over time directly in **Home Assistant** is very useful for monitoring energy costs and trends.

For this reason, I created a script that fetches and exposes this data so it can be plotted inside Home Assistant.

## Home Assistant configuration

In your `configuration.yaml`, add:


## Automations

Add the following to your automations:


```
alias: Update Energy Indices (PSV & PUN)
description: Forces the Python scripts to run on the 1st and 10th of the month
triggers:
  - trigger: time
    at: "10:00:00"
conditions:
  - condition: template
    value_template: "{{ now().day in [1, 10] }}"
  - condition: template
    value_template: >
      {{ state_attr('automation.update_energy_indices_psv_pun',
      'last_triggered') is none or 
         (now() - state_attr('automation.update_energy_indices_psv_pun', 'last_triggered')).total_seconds() > 3600 }}
actions:
  - action: shell_command.install_python_deps
  - action: homeassistant.update_entity
    target:
      entity_id:
        - sensor.psv_gas_all_data
        - sensor.pun_luce_all_data
mode: single

```
## Python dependencies

In order to fill data for the first time, you can trigger the following automation manually.

To install the required Python dependencies at boot (or alternatively install them manually using `pip install beautifulsoup4 requests` from the Hass.io CLI -> might break during updates), use:

```
alias: Install Python Deps on Boot
description: ""
triggers:
  - event: start
    trigger: homeassistant
actions:
  - action: shell_command.install_python_deps

```

## Custom Cards

Storico Prezzi PSV Gas:
```
type: custom:apexcharts-card
header:
  show: true
  title: Storico Prezzi PSV Gas
  show_states: true
  colorize_states: true
  standard_format: false
graph_span: 72month
layout: fill
series:
  - entity: sensor.psv_gas_all_data_2
    attribute: history
    type: line
    curve: smooth
    stroke_width: 3
    unit: " €/Smc"
    float_precision: 3
    show:
      datalabels: false
    data_generator: |
      const monthMap = {
        'gennaio': 0, 'febbraio': 1, 'marzo': 2, 'aprile': 3,
        'maggio': 4, 'giugno': 5, 'luglio': 6, 'agosto': 7,
        'settembre': 8, 'ottobre': 9, 'novembre': 10, 'dicembre': 11
      };
      return entity.attributes.history.map((item) => {
        const parts = item.month.toLowerCase().split(' ');
        const monthNum = monthMap[parts[0]];
        const year = parseInt(parts[1]);
        const date = new Date(year, monthNum, 1);
        const price = typeof item.price === 'string' 
          ? parseFloat(item.price.replace(',', '.')) 
          : item.price;
        return [date.getTime(), price];
      }).sort((a, b) => a[0] - b[0]);
apex_config:
  chart:
    height: 400
    width: 100%
    toolbar:
      show: false
    zoom:
      enabled: false
  grid:
    show: true
    padding:
      left: 10
      right: 10
  yaxis:
    decimalsInFloat: 3
    forceNiceScale: false
    labels:
      minWidth: 50
      style:
        fontSize: 12px
      formatter: |
        EVAL:function(value) {
          return value.toFixed(3);
        }
  xaxis:
    type: datetime
    labels:
      style:
        fontSize: 11px
  tooltip:
    shared: true
    "y":
      formatter: |
        EVAL:function(value) {
          return value.toFixed(3) + ' €/Smc';
        }
```


Storico Prezzi PUN Luce:

```
type: custom:apexcharts-card
header:
  show: true
  title: Storico Prezzi PUN Luce
  show_states: true
  colorize_states: true
  standard_format: false
graph_span: 72month
layout: fill
series:
  - entity: sensor.pun_luce_all_data
    name: F1 (Peak)
    type: line
    curve: smooth
    stroke_width: 2
    unit: " €/kWh"
    float_precision: 3
    data_generator: |
      const monthMap = {
        gen: 0, gennaio: 0,
        feb: 1, febbraio: 1,
        mar: 2, marzo: 2,
        apr: 3, aprile: 3,
        mag: 4, maggio: 4,
        giu: 5, giugno: 5,
        lug: 6, luglio: 6,
        ago: 7, agosto: 7,
        set: 8, settembre: 8,
        ott: 9, ottobre: 9,
        nov: 10, novembre: 10,
        dic: 11, dicembre: 11
      };
      return (entity.attributes.history || [])
        .map(item => {
          const [m, y] = item.month.toLowerCase().split(' ');
          const monthIndex = monthMap[m];
          if (monthIndex === undefined) return null;
          return [new Date(parseInt(y), monthIndex, 1).getTime(), item.F1];
        })
        .filter(p => p !== null)
        .sort((a, b) => a[0] - b[0]);
  - entity: sensor.pun_luce_all_data
    name: F2 (Mid)
    type: line
    curve: smooth
    stroke_width: 2
    unit: " €/kWh"
    float_precision: 3
    data_generator: |
      const monthMap = {
        gen: 0, gennaio: 0,
        feb: 1, febbraio: 1,
        mar: 2, marzo: 2,
        apr: 3, aprile: 3,
        mag: 4, maggio: 4,
        giu: 5, giugno: 5,
        lug: 6, luglio: 6,
        ago: 7, agosto: 7,
        set: 8, settembre: 8,
        ott: 9, ottobre: 9,
        nov: 10, novembre: 10,
        dic: 11, dicembre: 11
      };
      return (entity.attributes.history || [])
        .map(item => {
          const [m, y] = item.month.toLowerCase().split(' ');
          const monthIndex = monthMap[m];
          if (monthIndex === undefined) return null;
          return [new Date(parseInt(y), monthIndex, 1).getTime(), item.F2];
        })
        .filter(p => p !== null)
        .sort((a, b) => a[0] - b[0]);
  - entity: sensor.pun_luce_all_data
    name: F3 (Off-Peak)
    type: line
    curve: smooth
    stroke_width: 2
    unit: " €/kWh"
    float_precision: 3
    data_generator: |
      const monthMap = {
        gen: 0, gennaio: 0,
        feb: 1, febbraio: 1,
        mar: 2, marzo: 2,
        apr: 3, aprile: 3,
        mag: 4, maggio: 4,
        giu: 5, giugno: 5,
        lug: 6, luglio: 6,
        ago: 7, agosto: 7,
        set: 8, settembre: 8,
        ott: 9, ottobre: 9,
        nov: 10, novembre: 10,
        dic: 11, dicembre: 11
      };
      return (entity.attributes.history || [])
        .map(item => {
          const [m, y] = item.month.toLowerCase().split(' ');
          const monthIndex = monthMap[m];
          if (monthIndex === undefined) return null;
          return [new Date(parseInt(y), monthIndex, 1).getTime(), item.F3];
        })
        .filter(p => p !== null)
        .sort((a, b) => a[0] - b[0]);
apex_config:
  chart:
    height: 400
    width: 100%
    toolbar:
      show: true
    zoom:
      enabled: true
  grid:
    show: true
    padding:
      left: 10
      right: 10
  xaxis:
    type: datetime
    labels:
      style:
        fontSize: 11px
  yaxis:
    decimalsInFloat: 3
    forceNiceScale: false
    labels:
      formatter: |
        EVAL:function(value) {
          return value.toFixed(3);
        }
  tooltip:
    shared: true
    "y":
      formatter: |
        EVAL:function(value) {
          return value.toFixed(3) + ' €/kWh';
        }
```