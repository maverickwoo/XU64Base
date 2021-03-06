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

# pager and other common stuff
[ -r ~/bin/z.git/z.sh ] && . ~/bin/z.git/z.sh
export EDITOR=vim
export LESS=iMRSX               #-F seems to cause problem with lessopen
export PAGER="less -$LESS"
export VISUAL=vim               #get into the habit of using vim in terminal
if [ -x ~/bin/lesspipe.git/lesspipe.sh ]; then
    export LESSOPEN='| ~/bin/lesspipe.git/lesspipe.sh %s'
fi
if [ -x ~/bin/src-hilite-lesspipe.sh ]; then
    export LESSOPEN='| ~/bin/src-hilite-lesspipe.sh %s'
fi
if command -v pygmentize > /dev/null; then
    export LESSOPEN='| pygmentize -g %s'
fi
if command -v rougify > /dev/null; then
    export LESSOPEN='| rougify highlight -t base16.dark "%s"'
fi

# common functions
num_proc () # on linux, nproc will do
{
    local extra=${1:-0};
    local ans=$(case "$OSTYPE" in
                    linux*)  grep -cF processor /proc/cpuinfo
                             ;;
                    darwin*) sysctl -n hw.logicalcpu
                             ;;
                esac);
    echo $(($ans + $extra))
}
