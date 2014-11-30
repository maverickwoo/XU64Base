#!/bin/bash

aug ()
{
    local D=$(dirname $F);
    [ -d "$D" ] || mkdir -p "$D";
    [ -r "$F" ] || touch "$F";
    echo "augtool : $F";
    # bug: should be able to pass -s to save, but it fails often, dunno why yet
    augtool -A -L -i -r /
}

# Personal -> Appearance
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
aug <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Style
defnode p \$f/channel[#attribute/name="xsettings"]/property[#attribute/name="Net"]
set \$p/property[#attribute/name="ThemeName"]/#attribute/type "string"
set \$p/property[#attribute/name="ThemeName"]/#attribute/value "Greybird"

# Icons
set \$p/property[#attribute/name="IconThemeName"]/#attribute/type "string"
set \$p/property[#attribute/name="IconThemeName"]/#attribute/value "elementary-xfce-darker"

# Fonts
defnode p \$f/channel[#attribute/name="xsettings"]/property[#attribute/name="Gtk"]
set \$p/property[#attribute/name="FontName"]/#attribute/type "string"
set \$p/property[#attribute/name="FontName"]/#attribute/value "Source Sans Pro 10"
defnode p \$f/channel[#attribute/name="xsettings"]/property[#attribute/name="Xft"]
set \$p/property[#attribute/name="Antialias"]/#attribute/type "int"
set \$p/property[#attribute/name="Antialias"]/#attribute/value "1"
set \$p/property[#attribute/name="HintStyle"]/#attribute/type "string"
set \$p/property[#attribute/name="HintStyle"]/#attribute/value "hintslight"
set \$p/property[#attribute/name="RGBA"]/#attribute/type "string"
set \$p/property[#attribute/name="RGBA"]/#attribute/value "rgb"

save
quit
EOF

# Personal -> Desktop
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
aug <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Background -> Wallpaper
defnode p \$f/channel[#attribute/name="xfce4-desktop"]/property[#attribute/name="backdrop"]/*/*/*/property[#attribute/name="last-image"]
setm \$p #attribute/value "/usr/share/xfce4/backdrops/balance.jpg"

# Icons: don't show Home and Filesystem
defnode p \$f/channel[#attribute/name="xfce4-desktop"]/property[#attribute/name="desktop-icons"]/property[#attribute/name="file-icons"]
set \$p/property[#attribute/name="show-filesystem"]/#attribute/value "false"
set \$p/property[#attribute/name="show-home"]/#attribute/value "false"

save
quit
EOF

# Personal -> Light Locker Settings
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml
aug <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F
defnode p \$f/channel[#attribute/name="xfce4-power-manager"]/property[#attribute/name="xfce4-power-manager"]

# Screensaver: never + never
set \$p/property[#attribute/name="dpms-on-ac-off"]/#attribute/value "0"
set \$p/property[#attribute/name="dpms-on-ac-sleep"]/#attribute/value "0"

# Locking: off
set \$p/property[#attribute/name="dpms-enabled"]/#attribute/value "false"

save
quit
EOF

# Personal -> Window Manager: Part 1
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
aug <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Style -> Theme
defnode p \$f/channel[#attribute/name="xfwm4"]/property[#attribute/name="general"]
set \$p/property[#attribute/name="theme"]/#attribute/type "string"
set \$p/property[#attribute/name="theme"]/#attribute/value "Albatross"

# Style -> Title font
set \$p/property[#attribute/name="title_font"]/#attribute/type "string"
set \$p/property[#attribute/name="title_font"]/#attribute/value "Source Sans Pro Semi-Bold 10"

save
quit
EOF

# Personal -> Window Manager: Part 2
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
aug <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Keyboard
defnode p \$f/channel[#attribute/name="xfce4-keyboard-shortcuts"]/property[#attribute/name="xfwm4"]/property[#attribute/name="custom"]

# Tile window to the left
rm \$p/property[#attribute/name="&lt;Super&gt;Left"]
clear \$p/property[last()+1]
set \$p/property[last()]/#attribute/name "&lt;Super&gt;Left"
set \$p/property[last()]/#attribute/type "string"
set \$p/property[last()]/#attribute/value "tile_left_key"

# Tile window to the right
rm \$p/property[#attribute/name="&lt;Super&gt;Right"]
clear \$p/property[last()+1]
set \$p/property[last()]/#attribute/name "&lt;Super&gt;Right"
set \$p/property[last()]/#attribute/type "string"
set \$p/property[last()]/#attribute/value "tile_right_key"

save
quit
EOF

# Personal -> Window Manager Tweaks
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
aug <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Compositor: disable
defnode p \$f/channel[#attribute/name="xfwm4"]/property[#attribute/name="general"]
set \$p/property[#attribute/name="use_compositing"]/#attribute/type "bool"
set \$p/property[#attribute/name="use_compositing"]/#attribute/value "false"

save
quit
EOF

# Hardware -> Keyboard
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/keyboards.xml
aug <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Behavior -> Typing Settings
defnode p \$f/channel[#attribute/name="keyboards"]/property[#attribute/name="Default"]
rm \$p/property[#attribute/name="KeyRepeat"]
clear \$p/property[last()+1]
set \$p/property[last()]/#attribute/name "KeyRepeat"
set \$p/property[last()]/#attribute/type "empty"
set \$p/property[last()]/property[1]/#attribute/name "Rate"
set \$p/property[last()]/property[1]/#attribute/type "int"
set \$p/property[last()]/property[1]/#attribute/value "25"
set \$p/property[last()]/property[2]/#attribute/name "Delay"
set \$p/property[last()]/property[2]/#attribute/type "int"
set \$p/property[last()]/property[2]/#attribute/value "250"

save
quit
EOF

# xfce4-terminal -> Edit -> Preferences
F=~/.config/xfce4/terminal/terminalrc
aug <<EOF
set /augeas/load/ini/incl "$F"
set /augeas/load/ini/lens "Puppet.lns"
load
defnode f /files/$F
defnode p \$f/Configuration

# General
set \$p/CommandLoginShell "TRUE"
set \$p/ScrollingLines "999999"

# Appearance
set \$p/FontName "Meslo LG S DZ for Powerline 9"

# Colors
set \$p/ColorForeground/#comment "A0A0A0"
set \$p/ColorBackground/#comment "000000"
set \$p/ColorCursor/#comment "179E9F"
set \$p/ColorPalette/#comment "000000;#D23361;#319A24;#FF8141;#005DAA;#7437A4;#179E9F;#CCCCC6;#505354;#FF6FCF;#CCFF66;#FFFF66;#66CCFF;#CC66FF;#66FFCC;#F8F8F2"

save
quit
EOF

# yay
echo
echo "Done. Please logout and re-login."
