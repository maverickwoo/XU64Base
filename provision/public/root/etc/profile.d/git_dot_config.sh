git_dot_config ()
{
    # version control ~/.config so that we know what to change in the future
    [ -d ~/.config ] || mkdir ~/.config;
    pushd ~/.config;
    [ -d .git ] || git init -q;
    cat << "EOF" >> .gitignore;
/dconf/
/font-manager/
/google-chrome/
/htop/
/pulse/
/xfce4/desktop/icons.screen*
/xfce4/xfconf/xfce-perchannel-xml/xfce4-settings-editor.xml
EOF
    sort -u .gitignore | sponge .gitignore;
    git add .;
    git commit -m 'init add';
    popd;
    # echo '(cd ~/.config; git diff)' >> ~/.bashrc
}
