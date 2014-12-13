create_sudoer ()
{
    echo 'Creating new user account ...'
    read -ep 'Enter username: ' NEWUSER
    sudo adduser "$NEWUSER"

    # NOPASSWD
    sudo sed -i '$a'"$NEWUSER"' ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
    echo

    # force git config
    echo 'Installing git ...'
    sudo apt-get install -y git
    echo

    # workaround git bug with su: `sudo -u $foo git config --global -l` shocker
    echo 'Creating git config:'
    read -ep 'Enter git user.name (Full Name): ' GITUSERNAME
    sudo su -c 'git config --global user.name "'"$GITUSERNAME"'"' "$NEWUSER"
    read -ep 'Enter git user.email: ' GITUSEREMAIL
    sudo su -c 'git config --global user.email "'"$GITUSEREMAIL"'"' "$NEWUSER"

    # NEWUSER should be in vagrant group for vagrant-controlled shared folders
    sudo usermod -a -G docker,root,sudo,vagrant,vboxsf $NEWUSER
    echo
}
