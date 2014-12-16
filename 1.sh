#!/bin/bash

# This script should finish quickly. The goal is to obtain a VM with Guest
# Additions as quickly as possible. We postpone the creation of the custom user
# account to 3.sh so that the image taken after 2.sh does not have any other
# user.
#
# 1.sh should contain all non-idempotent operations; 2.sh must be idempotent.

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
echo vagrant |
    sudo -S sed -i '$avagrant ALL=(ALL) NOPASSWD: ALL' /etc/sudoers >& /dev/null

# check Additions CD (downloading ISO is too slow)
sudo mkdir -p /media/vagrant/VBOX
sudo chown -R vagrant:vagrant /media/vagrant
sudo mount -r /dev/sr1 /media/vagrant/VBOX
if [ -z "$(find /media/vagrant -maxdepth 1 -type d -name 'VBOX*' -print \
           -quit)" ]; then
    read -ep 'Press ENTER after you have mounted the Guest Additions CD...'
fi

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
sudo apt-get install -y dkms
sudo sh /media/vagrant/VBOX*/VBoxLinuxAdditions.run

# antialias: install in this step since we need to re-login afterwards
sudo apt-get install -y fontconfig-infinality libfreetype6
sudo ln -sfT /etc/fonts/infinality/styles.conf.avail/win7 \
     /etc/fonts/infinality/conf.d
sudo sed -i 's/^USE_STYLE="DEFAULT"/USE_STYLE="WINDOWS"/' \
     /etc/profile.d/infinality-settings.sh
# bugfix: Fontconfig warning:
# "/etc/fonts/infinality/conf.d/41-repl-os-win.conf", line 148 and 160: Having
# multiple values in <test> isn't supported and may not work as expected
sudo sed -i '/<string>Bitstream Vera Sans<\/string>$/d' \
     /etc/fonts/infinality/conf.d/41-repl-os-win.conf

# docker: install in this step since we need to reboot afterwards
# http://docs.docker.com/installation/ubuntulinux/
sudo apt-get install -y docker.io
sudo sed -ri 's/^(DEFAULT_FORWARD_POLICY)=.*/\1="ACCEPT"/' /etc/default/ufw
sudo sed -ri \
    's/^(GRUB_CMDLINE_LINUX)=.*/\1="cgroup_enable=memory swapaccount=1"/' \
    /etc/default/grub
sudo update-grub

# vagrant: do this after docker and vboxsf
echo 'root:vagrant' | sudo chpasswd
sudo usermod -a -G docker,root,sudo,vboxsf vagrant
sudo apt-get install -y ssh
sudo sed -i '$aUseDNS no' /etc/ssh/sshd_config
mkdir ~/.ssh
chmod 700 ~/.ssh
wget -q --no-check-certificate -O ~/.ssh/authorized_keys \
    https://github.com/mitchellh/vagrant/raw/master/keys/vagrant.pub
chmod 600 ~/.ssh/authorized_keys

# /etc adjustments
sudo sed -ri 's/^(AVAHI_DAEMON_DETECT_LOCAL)=.*/\1=0/' /etc/default/avahi-daemon
sudo chmod g+w /etc/profile.d   #vagrant provisioning
sudo mkdir /etc/skel/bin        #everyone needs this directory

# no more Guest Additions CD on desktop
sudo eject -v /dev/sr1
rm -rf /media/vagrant/VBOX

# yay
echo
echo 'Shutdown VM and take Snapshot 1. Then run the next step.'
echo
rm -f 1.sh
history -cw
