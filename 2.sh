#!/bin/bash

# This script should be idempotent.

#### SANITY CHECK ####

# don't bother updating yet
pkill -f /usr/bin/update-manager

#### AUTOPILOT ####

# pull docker baseimage in background (specifically leave out sudo)
docker pull phusion/baseimage:latest &

# download atom in background
wget -nv -O /tmp/atom.deb https://atom.io/download/deb &

# download fonts in background
wget -nv -O /tmp/Noto.zip https://www.google.com/get/noto/pkgs/Noto.zip &

# uninstall some useless stuff here
# (does not seem productive: leave empty)

# dist-upgrade
sudo apt-get update
sudo apt-get dist-upgrade -y

# package management
sudo apt-get install -y \
     apt-file \
     aptitude
sudo apt-file update & #good to cache, plus will avoid update dialog

# tier 1: bap + ida + qira
sudo apt-get install -y \
     ocaml \
     opam \
     python-pip `#cdiff`
sudo apt-get install -y \
     libqtgui4:i386
sudo apt-get install -y \
     google-chrome-stable \
     socat
sudo chmod a+x $(locate git-new-workdir)
sudo ln -s $(locate git-new-workdir) /usr/local/bin

# tier 2: what I consider to be good stuff that everyone wants
sudo apt-get install -y \
     augeas-tools \
     bash-doc \
     emacs24 \
     emacs24-el \
     font-manager \
     htop \
     mosh \
     nmap \
     realpath \
     screen \
     silversearcher-ag \
     ssh \
     tig \
     tmux \
     tree \
     vim-gtk

# make sure all background jobs are done
wait

# install atom
sudo dpkg -i /tmp/atom.deb
rm /tmp/atom.deb

# install Noto
sudo unzip /tmp/Noto.zip -d /usr/share/fonts/Noto
sudo chmod -R og=u,og-w /usr/share/fonts/Noto
rm /tmp/Noto.zip

# install cdiff
pip install --user cdiff
[ -d ~/bin ] || mkdir ~/bin
ln -s ~/.local/bin/cdiff ~/bin

# courtesy
sudo apt-get autoremove
sudo updatedb

# final step: zero out empty space before packaging into a box
echo 'Zeroing empty space to reduce box size...'
echo '(can take several minutes on a large disk image)'
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
