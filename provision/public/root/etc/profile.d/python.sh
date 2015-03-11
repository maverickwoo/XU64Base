my_pyenv_inject ()
{
    if [ -d "$HOME/.pyenv" ]; then
        export PATH="$HOME/.pyenv/bin:$PATH";
        eval "$(pyenv init -)";
        eval "$(pyenv virtualenv-init -)";
    fi
}

my_pyenv_init ()
{
    local PY27='2.7.9';
    local PY34='3.4.2';
    local url='https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer';

    # initial inject
    curl -L $url | bash
    my_pyenv_inject

    # install pre-requisites
    case "$OSTYPE" in
        linux*)
            sudo apt-get install -y \
                 libbz2-dev \
                 libreadline-dev \
                 libsqlite3-dev \
                 libssl-dev \
                 zlib1g-dev \
                 `#end`
            ;;
        darwin*) `#TBD` ;;
    esac

    # I use both
    parallel -k pyenv install ::: $PY27 $PY34

    # set up two venvs
    pyenv virtualenv $PY27 venv27
    pyenv virtualenv $PY34 venv34

    # activate both
    pyenv global $PY27 $PY34
    hash -r
    pip install \
        bpython \
        cdiff \
        pip-tools \
        `#end`

    # done
    pyenv versions
}
