if [ -d "$HOME/.pyenv" ]; then
    export PATH="$HOME/.pyenv/bin:$PATH";
    eval "$(pyenv init -)";
    eval "$(pyenv virtualenv-init -)";
fi

my_pyenv_init ()
{
    local script=/etc/profile.d/pyenv.sh
    local PY27=2.7.9
    local PY34=3.4.2
    curl -L \
         https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer \
        | bash
    source $script

    sudo apt-get install -y \
         libbz2-dev \
         libreadline-dev \
         libsqlite3-dev \
         libssl-dev \
         zlib1g-dev \
         `#end`

    pyenv install $PY27 &
    pyenv install $PY34 &
    wait

    pyenv virtualenv $PY27 venv27
    pyenv virtualenv $PY34 venv34

    pyenv global $PY34              #I prefer python 3
    hash -r
    pip install \
        bpython \
        cdiff \
        pip-tools \
        `#end`

    pyenv versions
}
