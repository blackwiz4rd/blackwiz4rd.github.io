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
```
shell_command:
  install_python_deps: "pip install beautifulsoup4 requests"

command_line:
  - sensor:
      name: PSV Gas All Data
      unique_id: psv_gas_all_data
      command: "python3 /config/scripts/psv_scraper.py"
      # The main state becomes the 'latest' value from our JSON
      value_template: "{{ value_json.latest }}"
      unit_of_measurement: "€/Smc"
      # This moves the 'history' array into an attribute
      json_attributes:
        - history
      scan_interval: 31536000
  - sensor:
      name: PUN Luce All Data
      unique_id: pun_luce_all_data
      command: "python3 /config/scripts/pun_scraper.py"
      value_template: "{{ value_json.latest }}"
      unit_of_measurement: "€/kWh"
      json_attributes:
        - history
      scan_interval: 31536000

template:
  - sensor:
      - name: "PSV Gas Prices for Chart"
        unique_id: psv_gas_chart_data
        state: "{{ state_attr('sensor.psv_gas_all_data', 'history') | length if state_attr('sensor.psv_gas_all_data', 'history') else 0 }}"
        unit_of_measurement: "months"
        attributes:
          chart_data: >
            {% set items = state_attr('sensor.psv_gas_all_data', 'history') %}
            {% if items %}
              {{ items }}
            {% else %}
              []
            {% endif %}
  - sensor:
      - name: "PUN Luce Prices for Chart"
        unique_id: pun_luce_chart_data
        state: "{{ state_attr('sensor.pun_luce_all_data', 'history') | length if state_attr('sensor.pun_luce_all_data', 'history') else 0 }}"
        unit_of_measurement: "months"
        attributes:
          chart_data: >
            {{ state_attr('sensor.pun_luce_all_data', 'history') or [] }}
```


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