#!/bin/bash

#### SANITY CHECK ####

# don't bother updating yet
pkill -f /usr/bin/update-manager

#### AUTOPILOT ####

# pull docker baseimage in background (specifically leave out sudo)
docker pull phusion/baseimage:latest &

# download atom in background
wget -q -O /tmp/atom.deb https://atom.io/download/deb &

# chrome: http://www.ubuntuupdates.org/ppa/google_chrome?dist=stable
# filename is important since they try to edit this file
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | \
    sudo apt-key add -
echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' | \
    sudo tee -a /etc/apt/sources.list.d/google-chrome.list > /dev/null

# uninstall some useless stuff here
# (does not seem productive: leave empty)

# dist-upgrade
sudo apt-get update #must happen after inserting apt
sudo apt-get dist-upgrade -y

# tier 1: bap + ida + qira
sudo apt-get install -y \
     opam       `#obviously` \
     python-pip `#git-review`
sudo apt-get install -y \
     libqtgui4:i386
sudo apt-get install -y \
     google-chrome-stable \
     socat
sudo chmod a+x $(locate git-new-workdir)
sudo ln -s $(locate git-new-workdir) /usr/local/bin

# tier 2: what I consider to be good stuff that everyone wants
sudo apt-get install -y \
     bash-doc \
     emacs24 \
     emacs24-el \
     htop \
     mosh \
     nmap \
     screen \
     silversearcher-ag \
     ssh \
     tig \
     tmux \
     vim-gtk

# make sure all background jobs are done
wait

# install atom
sudo dpkg -i /tmp/atom.deb
rm /tmp/atom.deb

# courtesy
sudo updatedb

# final step: zero out space before packaging
echo 'Zeroing empty space to reduce box size...'
echo '(can take minutes on a large disk image)'
time sudo dd if=/dev/zero of=/EMPTY bs=1M
sudo rm -f /EMPTY

# yay
cat <<"EOM"

Shutdown VM and take a snapshot. Then, in the host, execute these commands where
"XU64Base" is your chosen name of this VM:

yourself@host$ vagrant package --base XU64Base
yourself@host$ vagrant box add --force versioning.json

(Remember that copy-and-paste works inside this VM.)

EOM
rm 2.sh
history -cw
