#!/bin/bash

usage=$(($(cat /sys/class/power_supply/BAT0/power_now)/1000000))
status=$(cat /sys/class/power_supply/BAT0/status)

usage=$(if [[ $status == "Discharging" ]]; then echo -$usage; else echo $usage; fi)
status=$(if [[ $status = "Discharging" ]]; then echo "discharging"; else echo "charging"; fi)

printf '{"text": "%0.1fW", "class": "%s"}\n' $usage $status