#!/bin/bash

interface=org.kde.KWin.VirtualDesktopManager
object_path=/VirtualDesktopManager
member=currentChanged

dbus-monitor --profile "interface='$interface',member='$member'" |
while read -r line; do
  current_id=$(                                           \
    dbus-send                                             \
      --session --print-reply --dest=org.kde.KWin         \
      $object_path org.freedesktop.DBus.Properties.Get    \
      string:"$interface" string:"current"                \
    | grep "string"                                       \
    | cut -d '"' -f 2)
  
  current_int=$(                                          \
    dbus-send                                             \
      --session --print-reply --dest=org.kde.KWin         \
      $object_path org.freedesktop.DBus.Properties.Get    \
      string:"$interface" string:"desktops"               \
    | grep "string"                                       \
    | grep -v "Desktop"                                   \
    | cut -d '"' -f 2                                     \
    | grep -n -2 "$current"                               \
    | cut -c1-1)



  printf "$current_id : $current_int"
done
