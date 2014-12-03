#!/bin/bash
# automate my xfce4 settings idempotently

init_file ()
{
    local F="$1"
    if [ ! -r "$F" ]; then
        local D=$(dirname $F);
        [ -d "$D" ] || mkdir -p "$D";
        cat >| "$F";
    fi
}

aug_file ()
{
    local F="$1";
    local D=$(dirname $F);
    [ -d "$D" ] || mkdir -p "$D";
    [ -r "$F" ] || touch "$F";
    echo
    echo "augtool : $F";
    # bug: should be able to pass -s to save, but it fails often, dunno why yet
    augtool -A -L -i -r /
}

xml_clean ()
{
    local F="$1";
    xmllint --format "$F" | sponge "$F"
}

# Personal -> Appearance
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
init_file $F <<"EOF"
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
  </property>
  <property name="Xft" type="empty">
  </property>
  <property name="Gtk" type="empty">
  </property>
</channel>
EOF
aug_file $F <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Style
defnode p \$f/channel[#attribute/name="xsettings"]/property[#attribute/name="Net"]
rm \$p/property[#attribute/name="ThemeName"]
set \$p/property[last()+1]/#attribute/name "ThemeName"
set \$p/property[#attribute/name="ThemeName"]/#attribute/type "string"
set \$p/property[#attribute/name="ThemeName"]/#attribute/value "Greybird"

# Icons
rm \$p/property[#attribute/name="IconThemeName"]
set \$p/property[last()+1]/#attribute/name "IconThemeName"
set \$p/property[#attribute/name="IconThemeName"]/#attribute/type "string"
set \$p/property[#attribute/name="IconThemeName"]/#attribute/value "elementary-xfce-darker"

# Fonts
defnode p \$f/channel[#attribute/name="xsettings"]/property[#attribute/name="Gtk"]

rm \$p/property[#attribute/name="FontName"]
set \$p/property[last()+1]/#attribute/name "FontName"
set \$p/property[#attribute/name="FontName"]/#attribute/type "string"
set \$p/property[#attribute/name="FontName"]/#attribute/value "Source Sans Pro 10"
defnode p \$f/channel[#attribute/name="xsettings"]/property[#attribute/name="Xft"]

rm \$p/property[#attribute/name="Antialias"]
set \$p/property[last()+1]/#attribute/name "Antialias"
set \$p/property[#attribute/name="Antialias"]/#attribute/type "int"
set \$p/property[#attribute/name="Antialias"]/#attribute/value "1"

rm \$p/property[#attribute/name="HintStyle"]
set \$p/property[last()+1]/#attribute/name "HintStyle"
set \$p/property[#attribute/name="HintStyle"]/#attribute/type "string"
set \$p/property[#attribute/name="HintStyle"]/#attribute/value "hintslight"

rm \$p/property[#attribute/name="RGBA"]
set \$p/property[last()+1]/#attribute/name "RGBA"
set \$p/property[#attribute/name="RGBA"]/#attribute/type "string"
set \$p/property[#attribute/name="RGBA"]/#attribute/value "rgb"

save
print /augeas//error
quit
EOF
xml_clean $F

# Personal -> Desktop
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
aug_file $F <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Background -> Wallpaper
defnode p \$f/channel[#attribute/name="xfce4-desktop"]/property[#attribute/name="backdrop"]/*/*/*/property[#attribute/name="last-image"]
setm \$p #attribute/value "/usr/share/xfce4/backdrops/balance.jpg"

# Icons: don't show Home and Filesystem
defnode p \$f/channel[#attribute/name="xfce4-desktop"]/property[#attribute/name="desktop-icons"]/property[#attribute/name="file-icons"]
set \$p/property[#attribute/name="show-filesystem"]/#attribute/type "bool"
set \$p/property[#attribute/name="show-filesystem"]/#attribute/value "false"
set \$p/property[#attribute/name="show-home"]/#attribute/type "bool"
set \$p/property[#attribute/name="show-home"]/#attribute/value "false"

save
print /augeas//error
quit
EOF
xml_clean $F

# Personal -> Light Locker Settings
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml
init_file $F <<"EOF"
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-power-manager" version="1.0">
  <property name="xfce4-power-manager" type="empty">
  </property>
</channel>
EOF
aug_file $F <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Screensaver: never + never
defnode p \$f/channel[#attribute/name="xfce4-power-manager"]/property[#attribute/name="xfce4-power-manager"]
rm \$p/property[#attribute/name="dpms-on-ac-off"]
set \$p/property[last()+1]/#attribute/name "dpms-on-ac-off"
set \$p/property[#attribute/name="dpms-on-ac-off"]/#attribute/type "int"
set \$p/property[#attribute/name="dpms-on-ac-off"]/#attribute/value "0"

rm \$p/property[#attribute/name="dpms-on-ac-sleep"]
set \$p/property[last()+1]/#attribute/name "dpms-on-ac-sleep"
set \$p/property[#attribute/name="dpms-on-ac-sleep"]/#attribute/type "int"
set \$p/property[#attribute/name="dpms-on-ac-sleep"]/#attribute/value "0"

save
print /augeas//error
quit
EOF
xml_clean $F

F=~/.config/autostart/light-locker.desktop
init_file $F <<EOF
[Desktop Entry]
Type=Application
Name=Screen Locker
Exec=light-locker --lock-after-screensaver=1 --lock-on-suspend --no-late-locking
EOF
aug_file $F <<EOF
set /augeas/load/ini/incl "$F"
set /augeas/load/ini/lens "Puppet.lns"
load
defnode f /files/$F
defnode p \$f/"Desktop Entry"

# Locking: Off, When the screensaver is activated, 1 second, Lock on suspend
set \$p/Exec "light-locker --lock-after-screensaver=1 --lock-on-suspend --no-late-locking"

save
print /augeas//error
quit
EOF

# Personal -> Window Manager: Part 1
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
aug_file $F <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Style -> Theme
defnode p \$f/channel[#attribute/name="xfwm4"]/property[#attribute/name="general"]
set \$p/property[#attribute/name="theme"]/#attribute/type "string"
set \$p/property[#attribute/name="theme"]/#attribute/value "Albatross"

# Style -> Title font, Left alignment
set \$p/property[#attribute/name="title_font"]/#attribute/type "string"
set \$p/property[#attribute/name="title_font"]/#attribute/value "Source Sans Pro Semi-Bold 10"
set \$p/property[#attribute/name="title_alignment"]/#attribute/type "string"
set \$p/property[#attribute/name="title_alignment"]/#attribute/value "left"

# Advanced -> Windows snapping: both
set \$p/property[#attribute/name="snap_to_border"]/#attribute/type "bool"
set \$p/property[#attribute/name="snap_to_border"]/#attribute/value "true"
set \$p/property[#attribute/name="snap_to_windows"]/#attribute/type "bool"
set \$p/property[#attribute/name="snap_to_windows"]/#attribute/value "true"

save
print /augeas//error
quit
EOF
xml_clean $F

# Personal -> Window Manager: Part 2
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
aug_file $F <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Keyboard
defnode p \$f/channel[#attribute/name="xfce4-keyboard-shortcuts"]/property[#attribute/name="xfwm4"]/property[#attribute/name="custom"]

# Switch window for same application: Alt \`
rm \$p/property[#attribute/value="switch_window_key"]
clear \$p/property[last()+1]
set \$p/property[last()]/#attribute/name "&lt;Alt&gt;grave"
set \$p/property[last()]/#attribute/type "string"
set \$p/property[last()]/#attribute/value "switch_window_key"

# Maximize Window: Alt F10
rm \$p/property[#attribute/value="maximize_window_key"]
clear \$p/property[last()+1]
set \$p/property[last()]/#attribute/name "&lt;Alt&gt;F10"
set \$p/property[last()]/#attribute/type "string"
set \$p/property[last()]/#attribute/value "maximize_window_key"

# Tile window to the left: Super Left
rm \$p/property[#attribute/value="tile_left_key"]
clear \$p/property[last()+1]
set \$p/property[last()]/#attribute/name "&lt;Super&gt;Left"
set \$p/property[last()]/#attribute/type "string"
set \$p/property[last()]/#attribute/value "tile_left_key"

# Tile window to the right: Super Right
rm \$p/property[#attribute/value="tile_right_key"]
clear \$p/property[last()+1]
set \$p/property[last()]/#attribute/name "&lt;Super&gt;Right"
set \$p/property[last()]/#attribute/type "string"
set \$p/property[last()]/#attribute/value "tile_right_key"

save
print /augeas//error
quit
EOF
xml_clean $F

# Personal -> Window Manager Tweaks
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
aug_file $F <<EOF
set /augeas/load/xml/incl "$F"
set /augeas/load/xml/lens "Xml.lns"
load
defnode f /files/$F

# Compositor: disable
defnode p \$f/channel[#attribute/name="xfwm4"]/property[#attribute/name="general"]
set \$p/property[#attribute/name="use_compositing"]/#attribute/type "bool"
set \$p/property[#attribute/name="use_compositing"]/#attribute/value "false"

save
print /augeas//error
quit
EOF
xml_clean $F

# Hardware -> Keyboard
F=~/.config/xfce4/xfconf/xfce-perchannel-xml/keyboards.xml
init_file $F <<"EOF"
<?xml version="1.0" encoding="UTF-8"?>
<channel name="keyboards" version="1.0">
  <property name="Default" type="empty">
    <property name="Numlock" type="bool" value="false"/>
    <property name="KeyRepeat" type="empty">
      <property name="Rate" type="int" value="25"/>
      <property name="Delay" type="int" value="250"/>
    </property>
  </property>
</channel>
EOF
aug_file $F <<EOF
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
print /augeas//error
quit
EOF
xml_clean $F

# xfce4-terminal -> Edit -> Preferences
F=~/.config/xfce4/terminal/terminalrc
aug_file $F <<EOF
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
print /augeas//error
quit
EOF

# yay
echo
echo "Done. Please logout and re-login."
echo
