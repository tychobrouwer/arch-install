#!/bin/bash

interface=org.kde.KWin.VirtualDesktopManager
object_path=/VirtualDesktopManager
member=currentChanged

dbus-monitor --profile "interface='$interface',member='$member'" |
while read -r line; do
  current_id=$(echo "$line" | grep "string" | cut -d '"' -f 2)

  if [[ $current_id == "" || $current_id =~ ":" ]]; then
    continue
  fi
  
  current_int=$(                                          \
    dbus-send                                             \
      --session --print-reply --dest=org.kde.KWin         \
      $object_path org.freedesktop.DBus.Properties.Get    \
      string:"$interface" string:"desktops"               \
    | grep "string"                                       \
    | grep -v "Desktop"                                   \
    | cut -d '"' -f 2                                     \
    | grep -n "$current_id"                               \
    | cut -c1-1)

  echo "$current_int"
done
