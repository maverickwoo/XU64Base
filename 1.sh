#!/bin/bash -i

#### SANITY CHECK ####

cd ~

# who should run this?
if [ "vagrant" != "$USER" ]; then
    echo "Please run this script as the user 'vagrant'. Aborting..."
    exit 1
fi

# manually mount CD in GUI FIRST (downloading ISO is too slow)
read -ep "Press ENTER after you have mounted the Guest Additions CD..."
if [ -z "$(find /media/vagrant -maxdepth 1 -type d -name 'VBOX*' -print \
           -quit)" ]; then
    echo "Cannot find the Guest Additions CD in '/media/vagrant'. Aborting..."
    exit 1
fi

#### INTERACTIVE ####

# NOPASSWD vagrant
echo 'vagrant' | sudo -S sed -i '$avagrant ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
echo '[the answer is "vagrant"]'
echo

# NOPASSWD myself
echo "Let's create a user account for you."
read -ep 'Enter username: ' GUESTLOGIN
sudo adduser $GUESTLOGIN
sudo sed -i '$a'$GUESTLOGIN' ALL=(ALL) NOPASSWD: ALL' /etc/sudoers

# install guest additions early to enable screen resize and copy-and-paste
sudo apt-get install -y dkms
sudo sh /media/vagrant/VBOX*/autorun.sh
sudo eject

#### AUTOPILOT ####

# install docker in this round since it needs to reboot
# http://docs.docker.com/installation/ubuntulinux/
sudo apt-get install -y docker.io
sudo sed -ri 's/^(DEFAULT_FORWARD_POLICY)=.*/\1="ACCEPT"/' /etc/default/ufw
sudo sed -ri \
    's/^(GRUB_CMDLINE_LINUX)=.*/\1="cgroup_enable=memory swapaccount=1"/' \
    /etc/default/grub
sudo update-grub

# docker-ssh and docker_ip
sudo apt-get install -y curl
curl --fail -L -O \
    https://github.com/phusion/baseimage-docker/archive/master.tar.gz
tar xzf master.tar.gz
sudo baseimage-docker-master/install-tools.sh
rm -rf master.tar.gz baseimage-docker-master
echo 'docker_ip ()
{
  docker inspect -f "{{ .NetworkSettings.IPAddress }}" $1;
}' | sudo tee -a /etc/profile.d/docker_ip.sh > /dev/null

# adjust groups (me not in vagrant group => shared folders are read-only to me)
sudo usermod -a -G docker,sudo,vboxsf vagrant
sudo usermod -a -G docker,sudo,vboxsf $GUESTLOGIN

# vagrant
sudo apt-get install -y ssh #redundant since my tier 2 contains it
mkdir ~/.ssh
chmod 700 ~/.ssh
wget -q --no-check-certificate -O ~/.ssh/authorized_keys \
    https://github.com/mitchellh/vagrant/raw/master/keys/vagrant.pub
chmod 600 ~/.ssh/authorized_keys
echo 'root:vagrant' | sudo chpasswd
sudo sed -i '$aUseDNS no' /etc/ssh/sshd_config

# ubuntu annoyance
sudo sed -ri 's/^(AVAHI_DAEMON_DETECT_LOCAL)=.*/\1=0/' /etc/default/avahi-daemon

# yay
echo
echo 'Shutdown VM and take a snapshot. Then run the next step.'
echo
rm 1.sh
