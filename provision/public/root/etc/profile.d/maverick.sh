# things that I don't want to live without
export LANG=en_US.utf-8         #I hate utf-8 in terminal, but it's everywhere
export LC_COLLATE=C             #I want sorting by C
stty -ixon <&2                  #enable C-s & avoid "stdin isn't a terminal"
set -o ignoreeof                #ignore Ctrl-d
set -o noclobber                #use >| to overwrite files
shopt -s checkwinsize

# share history across shells
shopt -s histappend
HISTCONTROL=ignoreboth
HISTFILESIZE=9999999
HISTSIZE=$HISTFILESIZE
HISTTIMEFORMAT='%F %T '
PROMPT_COMMAND="$PROMPT_COMMAND history -a; echo '#$(date +%s);' >> ~/.bash_history; history -n;"

# common functions
num_proc ()
{
    local extra=${1:-0};
    local ans=$(case "$OSTYPE" in
                    linux*)  grep -cF processor /proc/cpuinfo;;
                    darwin*) sysctl -n hw.logicalcpu;;
                esac);
    echo $(($ans + $extra))
}
