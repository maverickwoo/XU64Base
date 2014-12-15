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

download_docker_ssh ()
{
    local source='/tmp/docker_ssh.tar.gz';
    wget -q -O $source \
         https://github.com/phusion/baseimage-docker/archive/master.tar.gz
}

install_docker_ssh ()
{
    local source='/tmp/docker_ssh.tar.gz';
    tar xzf $source;
    sudo baseimage-docker-master/install-tools.sh;
    rm -rf $source baseimage-docker-master
}

download_font_microsoft ()
{
    local source='/tmp/font_microsoft';
    wget -q -O $source \
         http://download.microsoft.com/download/E/6/7/E675FFFC-2A6D-4AB0-B3EB-27C9F8C8F696/PowerPointViewer.exe
}

install_font_microsoft ()
{
    local source='/tmp/font_microsoft';
    local target='/usr/share/fonts/microsoft-fonts';
    sudo apt-get install -y cabextract;
    cabextract -L -d /tmp -F ppviewer.cab $source;
    sudo cabextract -L -d $target -F \*.tt\? /tmp/ppviewer.cab
}

download_font_noto ()
{
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

download_font_powerline ()
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

install_font_powerline () { true; }

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

download_lmutil ()
{
    local source='/tmp/lmutil.tgz';
    wget -q -O $source \
         https://www.hex-rays.com/products/ida/support/flexlm/lmutil-x64_lsb-11.12.1.0v6.tar.gz
}

install_lmutil ()
{
    local source='/tmp/lmutil.tgz';
    local target='/usr/local/bin';
    sudo tar -C $target -zxvf $source
}

#### SANITY CHECK ####

# don't bother updating yet
pkill -f /usr/bin/update-manager

#### AUTOPILOT ####

# start custom downloads
download_atom &
download_docker_ssh &
download_font_microsoft &
download_font_noto &
download_font_powerline &
download_font_source_code_pro &
download_font_source_sans_pro &
download_font_source_serif_pro &
download_lmutil &

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
     llvm \
     m4                        `#ocamlfind` \
     ocaml \
     opam \
     `#end`
sudo apt-get install -y \
     libqtgui4:i386 \
     `#end`
sudo apt-get install -y \
     cmake \
     ninja-build \
     `#end`
sudo apt-get install -y \
     google-chrome-stable \
     socat \
     `#end`

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
     kdiff3-qt \
     libxml2-utils             `#xmllint` \
     lsb \                     `#lmutil` \
     mercurial \
     moreutils                 `#sponge` \
     mosh \
     ncdu \
     nmap \
     python-pip \
     realpath \
     screen \
     silversearcher-ag \
     ssh \
     subversion \
     tig \
     tmux \
     tree \
     vim-gtk \
     xml2 \
     `#end`
sudo chmod a+x $(locate git-new-workdir)
sudo ln -sf $(locate git-new-workdir) /usr/local/bin

# wait for bg downloads
wait

# install custom stuff
install_atom
install_docker_ssh
install_font_microsoft
install_font_noto
install_font_powerline
install_font_source_code_pro
install_font_source_sans_pro
install_font_source_serif_pro
install_lmutil
sudo chmod -R og=u,og-w /usr/share/fonts

# courtesy
sudo apt-get -q -y autoremove
sudo updatedb

if [ vagrant == "$USER" ]; then

    # final step: zero out empty space before packaging into a box
    echo 'Zeroing empty space to reduce box size...'
    echo '(can take several minutes on a large disk image)'
    time sudo dd if=/dev/zero of=/EMPTY bs=1M
    sudo rm -f /EMPTY

    # yay
    cat <<"EOF"

Shutdown VM and take Snapshot 2. Then, in the *host*, execute these commands
where "XU64Base" is your chosen name of this VM:

  yourself@host$ vagrant package --base XU64Base --output /tmp/package.box
  yourself@host$ vagrant box add --force versioning.json

(Remember that copy-and-paste works inside this VM.)

EOF
    rm -f 2.sh
    history -cw

fi
