#!/bin/bash -i

# This script should finish quickly. The goal is to have a VM with Guest
# Additions as quickly as possible.
#
# All apt adjustments should happen here since 2.sh should be idempotent.

#### SANITY CHECK ####

# don't bother updating yet
pkill -f /usr/bin/update-manager

# who should run this?
if [ vagrant != "$USER" ]; then
    echo 'Please run this script as the user "vagrant". Aborting...'
    exit 1
fi

#### INTERACTIVE ####

# NOPASSWD vagrant as the very first step to avoid future passowrd prompts
echo vagrant | sudo -S sed -i '$avagrant ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
echo '[The answer is "vagrant".]'
echo

# NOPASSWD myself
echo 'Creating your own user account: (leave empty to skip)'
read -ep 'Enter username: ' GUESTLOGIN
if [ -z "$GUESTLOGIN" ]; then
    echo '(skipped)'
else
    sudo adduser "$GUESTLOGIN"
    sudo sed -i '$a'"$GUESTLOGIN"' ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
    echo

    # force git config
    echo 'Installing git ...'
    sudo apt-get install -qq -y git
    echo
    # workaround git bug with su: `sudo -u $foo git config --global -l` shocker
    echo 'Creating your git config:'
    read -ep 'Enter git user.name (your full name): ' GITUSERNAME
    sudo su -c 'git config --global user.name "'"$GITUSERNAME"'"' "$GUESTLOGIN"
    read -ep 'Enter git user.email: ' GITUSEREMAIL
    sudo su -c 'git config --global user.email "'"$GITUSEREMAIL"'"' "$GUESTLOGIN"
fi
echo

# check Additions CD (downloading ISO is too slow)
sudo mkdir -p /media/vagrant/VBOX
sudo chown -R vagrant:vagrant /media/vagrant
sudo mount -r /dev/sr1 /media/vagrant/VBOX
if [ -z "$(find /media/vagrant -maxdepth 1 -type d -name 'VBOX*' -print \
           -quit)" ]; then
    read -ep 'Press ENTER after you have mounted the Guest Additions CD...'
fi

read -ep 'Press ENTER to start auto-pilot: '

#### AUTOPILOT ####

# add antialiasing
# https://github.com/achaphiv/ppa-fonts/blob/master/ppa/README.md
sudo add-apt-repository -s -y ppa:no1wantdthisname/ppa

# add latest ocaml + opam
# https://launchpad.net/~avsm/+archive/ubuntu/ocaml42+opam12
sudo add-apt-repository -s -y ppa:avsm/ocaml42+opam12

# add chrome
# http://www.ubuntuupdates.org/ppa/google_chrome?dist=stable
# exact filename is important since they try to edit this file
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub |
    sudo apt-key add -
echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' |
    sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

# should update anyway (curl used to have problem if we don't update)
sudo apt-get update

# install Guest Additions early to enable screen resize and copy-and-paste
sudo apt-get install -q -y dkms
sudo sh /media/vagrant/VBOX*/VBoxLinuxAdditions.run

# antialias: be nice to my eyes
sudo apt-get install -q -y fontconfig-infinality libfreetype6
sudo ln -sfT /etc/fonts/infinality/styles.conf.avail/win7 \
     /etc/fonts/infinality/conf.d
sudo sed -i 's/^USE_STYLE="DEFAULT"/USE_STYLE="WINDOWS"/' \
     /etc/profile.d/infinality-settings.sh

# docker: install in this round since we need to reboot afterwards
# http://docs.docker.com/installation/ubuntulinux/
sudo apt-get install -q -y docker.io
sudo sed -ri 's/^(DEFAULT_FORWARD_POLICY)=.*/\1="ACCEPT"/' /etc/default/ufw
sudo sed -ri \
    's/^(GRUB_CMDLINE_LINUX)=.*/\1="cgroup_enable=memory swapaccount=1"/' \
    /etc/default/grub
sudo update-grub

# adjust groups (me not in vagrant group => shared folders are read-only to me)
sudo usermod -a -G docker,sudo,vboxsf vagrant
sudo usermod -a -G docker,sudo,vboxsf $GUESTLOGIN

# vagrant: depends on ssh
sudo apt-get install -q -y ssh
mkdir ~/.ssh
chmod 700 ~/.ssh
wget -q --no-check-certificate -O ~/.ssh/authorized_keys \
    https://github.com/mitchellh/vagrant/raw/master/keys/vagrant.pub
chmod 600 ~/.ssh/authorized_keys
echo 'root:vagrant' | sudo chpasswd
sudo sed -i '$aUseDNS no' /etc/ssh/sshd_config

# ubuntu annoyance
sudo sed -ri 's/^(AVAHI_DAEMON_DETECT_LOCAL)=.*/\1=0/' /etc/default/avahi-daemon

# no more Guest Additions CD on desktop
sudo eject -v /dev/sr1
rm -rf /media/vagrant/VBOX

# yay
echo
echo 'Shutdown VM and take a snapshot. Then run the next step.'
echo
rm 1.sh
history -cw
