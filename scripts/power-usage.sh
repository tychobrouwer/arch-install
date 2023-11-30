#!/bin/bash

usage=$(cat /sys/class/power_supply/BAT0/power_now)

printf '{"text": "%.1f W", "class": "%s"}\n' $(($usage/1000000)) "$(if [[ usage>=0 ]]; then echo 'charging'; else echo 'depleting'; fi)"