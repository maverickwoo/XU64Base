#!/bin/bash

# Stable idempotent part of my config: it rarely changes, and even if it changes
# you can run the script again with no harmful side-effects.

#### HELPERS ####

download_atom ()
{
    local source='/tmp/atom.deb';
    wget -q -O $source https://atom.io/download/deb
}

install_atom ()
{
    local source='/tmp/atom.deb';
    sudo dpkg -i $source;
    rm $source
}

download_font_noto () {
    local source='/tmp/Noto.zip';
    wget -q -O $source https://www.google.com/get/noto/pkgs/Noto.zip
}

install_font_noto ()
{
    local source='/tmp/Noto.zip';
    local target='/usr/share/fonts/Noto';
    sudo rm -rf $target;
    sudo unzip $source -d $target;
    rm $source
}

install_font_powerline ()
{
    local target='/usr/share/fonts/powerline-fonts';
    if [ -d $target ]; then
        ( cd $target; sudo git pull );
    else
        sudo git clone -q --depth 1 \
             https://github.com/Lokaltog/powerline-fonts.git \
             $target;
    fi
}

download_font_source_code_pro ()
{
    local source='/tmp/source-code-pro.tgz';
    wget -q -O $source \
         https://github.com/adobe-fonts/source-code-pro/archive/1.017R.tar.gz
}

install_font_source_code_pro ()
{
    local source='/tmp/source-code-pro.tgz';
    local target='/usr/share/fonts/source-code-pro';
    sudo rm -rf $target;
    sudo mkdir -p $target;
    sudo tar --strip-components 2 --wildcards -C $target -zxvf $source '*/OTF/*.otf';
    rm $source
}

download_font_source_sans_pro ()
{
    local source='/tmp/source-sans-pro.tgz';
    wget -q -O $source \
         https://github.com/adobe-fonts/source-sans-pro/archive/2.010R-ro/1.065R-it.tar.gz
}

install_font_source_sans_pro ()
{
    local source='/tmp/source-sans-pro.tgz';
    local target='/usr/share/fonts/source-sans-pro';
    sudo rm -rf $target;
    sudo mkdir -p $target;
    sudo tar --strip-components 2 --wildcards -C $target -zxvf $source '*/OTF/*.otf';
    rm $source
}

download_font_source_serif_pro ()
{
    local source='/tmp/source-serif-pro.tgz';
    wget -q -O $source \
         https://github.com/adobe-fonts/source-serif-pro/archive/1.014R.tar.gz
}

install_font_source_serif_pro ()
{
    local source='/tmp/source-serif-pro.tgz';
    local target='/usr/share/fonts/source-serif-pro';
    sudo rm -rf $target;
    sudo mkdir -p $target;
    sudo tar --strip-components 2 --wildcards -C $target -zxvf $source '*/OTF/*.otf';
    rm $source
}

#### SANITY CHECK ####

# don't bother updating yet
pkill -f /usr/bin/update-manager

# who should run this?
if [ vagrant != "$USER" ]; then
    echo 'Please run this script as the user "vagrant". Aborting...'
    exit 1
fi

read -ep 'Press ENTER to engage auto-pilot for this step: '

#### AUTOPILOT ####

# start custom downloads
download_atom &
download_font_noto &
install_font_powerline & #no separate installer
download_font_source_code_pro &
download_font_source_sans_pro &
download_font_source_serif_pro &

# pull docker baseimage in background (specifically leave out sudo)
docker pull phusion/baseimage:latest > /dev/null &

# uninstall some useless stuff here
# (does not seem productive: leave empty)

# dist-upgrade
sudo apt-get update
sudo apt-get dist-upgrade -y

# apt-file, good to cache (do these two together to avoid dialog box)
sudo apt-get install -y apt-file
sudo apt-file update > /dev/null &

# tier 1: bap + ida + llvm (just building tools) + qira (just exo-docker)
sudo apt-get install -y \
     libgmp-dev                `#zarith` \
     libncurses5-dev           `#ocamlfind` \
     m4                        `#ocamlfind`
     ocaml \
     opam
sudo apt-get install -y \
     libqtgui4:i386
sudo apt-get install -y \
     cmake \
     ninja-build
sudo apt-get install -y \
     google-chrome-stable \
     socat

# tier 2: good stuff that everyone should want in my opinion
sudo apt-get install -y \
     aptitude \
     augeas-tools \
     bash-doc                  `#info bash` \
     curl \
     emacs24 \
     emacs24-el \
     font-manager \
     git \
     git-svn \
     htop \
     libxml2-utils             `#xmllint` \
     moreutils                 `#sponge` \
     mosh \
     nmap \
     python-pip \
     realpath \
     screen \
     silversearcher-ag \
     ssh \
     tig \
     tmux \
     tree \
     vim-gtk \
     xml2
sudo chmod a+x $(locate git-new-workdir)
sudo ln -sf $(locate git-new-workdir) /usr/local/bin

# wait for bg downloads
wait

# install custom stuff
install_atom
install_font_noto
install_font_source_code_pro
install_font_source_sans_pro
install_font_source_serif_pro
sudo chmod -R og=u,og-w /usr/share/fonts

# courtesy
sudo apt-get -q autoremove
sudo updatedb

# final step: zero out empty space before packaging into a box
echo 'Zeroing empty space to reduce box size...'
echo '(can take several minutes on a large disk image)'
time sudo dd if=/dev/zero of=/EMPTY bs=1M
sudo rm -f /EMPTY

# yay
cat <<"EOF"

Shutdown VM and take Snapshot 2. Then, in the *host*, execute these commands
where "XU64Base" is your chosen name of this VM:

  yourself@host$ vagrant package --base XU64Base
  yourself@host$ vagrant box add --force versioning.json

(Remember that copy-and-paste works inside this VM.)

EOF
rm 2.sh
history -cw
