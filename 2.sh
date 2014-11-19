#!/bin/bash

#### SANITY CHECK ####

cd ~

#DOES IT MATTER WHO RUN THIS?

# who should run this?
if [ "vagrant" != "$USER" ]; then
    echo "Please source this script as the user 'vagrant'. Aborting..."
    exit 1
fi

#### AUTOPILOT ####

# pull docker baseimage in background (specifically leave out sudo)
docker pull phusion/baseimage:latest &

# chrome: http://www.ubuntuupdates.org/ppa/google_chrome?dist=stable
# filename is important since they try to edit this file
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | \
    sudo apt-key add -
echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' | \
    sudo tee -a /etc/apt/sources.list.d/google-chrome.list > /dev/null

# uninstall some useless stuff here
# (does not seem productive: leave empty)

# enable antialiasing
# https://github.com/achaphiv/ppa-fonts/blob/master/ppa/README.md
sudo add-apt-repository -y ppa:no1wantdthisname/ppa

# dist-upgrade (yes, I am crazy)
sudo apt-get update #must happen after inserting chrome apt
sudo apt-get dist-upgrade -y

# tier 0: my eyes
sudo apt-get install -y fontconfig-infinality
sudo ln -sfT /etc/fonts/infinality/styles.conf.avail/win7 \
     /etc/fonts/infinality/conf.d
sudo sed -i 's/^USE_STYLE="DEFAULT"/USE_STYLE="WINDOWS"/' \
     /etc/profile.d/infinality-settings.sh

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
     apt-file \
     aptitude \
     bash-doc \
     emacs24 \
     emacs24-el \
     htop \
     nmap \
     screen \
     silversearcher-ag \
     ssh \
     tig \
     tmux \
     vim-gtk

# courtesy
sudo updatedb

# make sure all background jobs are done
wait

# final step: zero out space before packaging
if [ "vagrant" = "$USER" ]; then
    echo 'Zeroing empty space... (can take minutes on a large disk image)'
    time sudo dd if=/dev/zero of=/EMPTY bs=1M
    sudo rm -f /EMPTY

    # yay
    cat <<"EOM"

Shutdown VM and take a snapshot. Then, in the host, execute these commands where
"XU64Base" is your chosen name of this VM:

  vagrant package --base XU64Base
  vagrant box add --force versioning.json

(Remember that copy-and-paste works inside this VM.)

EOM
    rm 2.sh
    history -cw
fi
