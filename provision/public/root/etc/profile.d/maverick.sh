num_proc ()
{
    local extra=${1:-0};
    local ans=$(case "$OSTYPE" in
                    linux*)  grep -cF processor /proc/cpuinfo;;
                    darwin*) sysctl -n hw.logicalcpu;;
                esac);
    echo $(($ans + $extra))
}
