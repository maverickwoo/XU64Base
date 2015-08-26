#!/bin/bash

# Stable idempotent part of my config: it rarely changes, and even if it changes
# you can run the script again with no harmful side-effects.

#### HELPERS ####

calm_down ()
{
    echo 'Calming down...'
    # use awk (gawk may not be installed yet)
    while [ $(uptime | awk -F':|,| ' '{print int($(NF-4))}') -ge ${1:-10} ]; do
        uptime
        sleep ${2:-5}
    done
}

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
    sudo cabextract -L -d $target -F \*.tt\? /tmp/ppviewer.cab;
    rm $source /tmp/ppviewer.cab
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
    local url='https://github.com/powerline/fonts.git';
    if [ -d $target ]; then
        ( cd $target; sudo git remote set-url origin $url; sudo git pull );
    else
        sudo git clone -q --depth 1 $url $target;
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
    sudo tar -C $target -zxvf $source;
    rm $source
}

download_sublime ()
{
    local source='/tmp/sublime3.tgz';
    wget -q -O $source \
         http://c758482.r82.cf2.rackcdn.com/sublime-text_build-3065_amd64.deb
}

install_sublime ()
{
    local source='/tmp/sublime3.tgz';
    sudo dpkg -i $source;
    rm $source
}

#### SANITY CHECK ####

# don't bother updating yet
pkill -f /usr/bin/update-manager

#### AUTOPILOT ####

# start custom downloads
if [ vagrant == "$USER" ]; then
    download_atom &
    download_docker_ssh &
    download_font_microsoft &
    download_font_noto &
    download_font_powerline &
    download_font_source_code_pro &
    download_font_source_sans_pro &
    download_font_source_serif_pro &
    download_lmutil &
    download_sublime &
fi

# pull docker baseimage in background (specifically leave out sudo)
docker pull phusion/baseimage:latest >/dev/null &

# uninstall some unneeded stuff to save time and space
sudo apt-get purge -y --auto-remove \
     abiword-common \
     gmusicbrowser \
     gnumeric-common \
     gnumeric-doc \
     libabiword-3.0 \
     parole \
     pidgin-data \
     pidgin-otr \
     simple-scan \
     software-center-aptdaemon-plugins \
     thunderbird \
     transmission-common \
     xfburn \
     `#end`

# dist-upgrade
sudo apt-get update
sudo apt-get dist-upgrade -y

# apt-file, good to cache (do these two together to avoid dialog box)
sudo apt-get install -y apt-file
sudo apt-file update >/dev/null &

# tier 1: BAP + IDA + LLVM (building tools) + qira (exo-docker) + cross compiler
sudo apt-get install -y \
     `#BAP` \
     binutils-multiarch-dev    `#ocamlobjinfo cmxs` \
     clang \
     libgmp-dev                `#zarith` \
     libiberty-dev             `#ocamlobjinfo cmxs` \
     libncurses5-dev           `#ocamlfind` \
     libzmq3-dev \
     llvm \
     m4                        `#ocamlfind` \
     ocaml \
     opam \
     `#IDA` \
     libqtgui4:i386 \
     lsb-core                  `#lmutil` \
     `#LLVM` \
     cmake \
     ninja-build \
     `#qira` \
     binfmt-support \
     google-chrome-stable \
     qemu-user-static \
     qemu-utils \
     socat \
     `#cross` \
     g++-4.8-multilib \
     g++-aarch64-linux-gnu \
     g++-arm-linux-gnueabihf \
     g++-powerpc-linux-gnu \
     g++-powerpc64le-linux-gnu \
     gcc-arm-linux-gnueabi \
     gdb-multiarch \
     linux-libc-dev:i386 \
     `#end`

# tier 2: good stuff that everyone should want in my opinion
sudo apt-get install -y \
     aptitude \
     augeas-tools \
     bash-doc                  `#info` \
     binutils-doc              `#info` \
     bison \
     curl \
     dos2unix \
     emacs24 \
     emacs24-el \
     flex \
     font-manager \
     gawk \
     gcc-doc                   `#info` \
     git \
     git-svn \
     htop \
     kdiff3-qt \
     keychain \
     libxml2-utils             `#xmllint` \
     mercurial \
     moreutils                 `#sponge` \
     mosh \
     most \
     ncdu \
     nmap \
     pigz \
     python-pip \
     realpath \
     renameutils \
     rlwrap \
     screen \
     silversearcher-ag \
     sqlite \
     ssh \
     subversion \
     terminator \
     texinfo \
     tig \
     tmux \
     tree \
     vim-gtk \
     xml2 \
     `#end`
sudo apt-get -o Dpkg::Options::="--force-conflicts" install -y \
     parallel                  `#niceload, parallel`
sudo chmod a+x $(locate git-new-workdir)
sudo ln -sf $(locate git-new-workdir) /usr/local/bin

# tier 3: CMU specific
sudo apt-get install -y debconf-utils
cat << "EOF" | sudo debconf-set-selections
krb5-config krb5-config/add_servers boolean false
krb5-config krb5-config/add_servers_realm string AEGIS.CYLAB.CMU.EDU
krb5-config krb5-config/admin_server string
krb5-config krb5-config/default_realm string AEGIS.CYLAB.CMU.EDU
krb5-config krb5-config/kerberos_servers string
krb5-config krb5-config/read_conf boolean true
EOF
sudo apt-get install -y \
     krb5-user \
     `#end`

# tier 4: postgresql
sudo apt-get install -y \
     postgresql \
     postgresql-client \
     postgresql-contrib \
     `#end`

# wait for bg downloads
echo 'Waiting for background downloads to finish...'
wait

# install custom stuff
if [ vagrant == "$USER" ]; then
    install_atom
    install_docker_ssh
    install_font_microsoft
    install_font_noto
    install_font_powerline
    install_font_source_code_pro
    install_font_source_sans_pro
    install_font_source_serif_pro
    install_lmutil
    install_sublime
    sudo chmod -R og=u,og-w /usr/share/fonts
fi

# courtesy
sudo apt-get -y autoremove
sudo updatedb

if [ vagrant == "$USER" ]; then

    sleep 15                    #trigger xfsettingsd bug
    calm_down

    # final step: zero out empty space before packaging into a box
    echo 'Zeroing empty space to reduce box size...'
    echo '(can take several minutes on a large disk image)'
    time sudo nice dd if=/dev/zero of=/EMPTY bs=1M
    sudo rm -f /EMPTY

    # yay
    cat << "EOF"

Shutdown VM and take Snapshot 2. Then, in the *host*, execute these commands
by substituting "XU64Base" with the name of this VM:

  yourself@host$ vagrant package --base XU64Base --output /tmp/package.box
  yourself@host$ vagrant box add --force versioning.json

(Remember that copy-and-paste works inside this VM.)

EOF
    rm -f 2.sh
    history -cw

fi
