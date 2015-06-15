# maverick's own setting: I like these, but ymmv

# things that I don't want to live without
export LANG=en_US.utf-8         #I hate utf-8 in terminal, but it's everywhere
export LC_COLLATE=C             #I want sorting by C
set -o ignoreeof                #ignore Ctrl-d
export IGNOREEOF=1000           #... this number of times
set -o noclobber                #use >| to force overwrite
shopt -s checkwinsize           #auto set LINES and COLUMNS
[[ $- == *i* ]] && stty -ixon   #enable C-s in interactive shells

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
