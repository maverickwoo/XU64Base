num_proc ()
{
    local extra=${1:-0};
    local ans=$(
        if [ -r /proc/cpuinfo ]; then
            # linux
            grep -cF processor /proc/cpuinfo;
        else
            # darwin
            sysctl -n hw.logicalcpu;
        fi);
    echo $(($ans + $extra))
}
