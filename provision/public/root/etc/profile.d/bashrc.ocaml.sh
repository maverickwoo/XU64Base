# -*- mode: shell-script -*-

opam_init ()
{
    if [ "$(opam switch 2> /dev/null)" ]; then
        echo 'opam switch already exists.';
    else
        local NUMPROC=$(if [ -r /proc/cpuinfo ]; then
                            grep -cF processor /proc/cpuinfo;
                        else
                            sysctl -n hw.logicalcpu; #darwin
                        fi);
        local S=$(cat <<"EOF"
export OPAMKEEPBUILDDIR="yes";
export OCAMLPARAM='_,annot=0,bin-annot=1,short-paths=1'
EOF
              );
        eval "$S";
        echo "$S" >> ~/.bashrc;
        opam init -a;
        sed -ri 's/^(jobs:).*/\1 '$((1 + $NUMPROC))'/' ~/.opam/config;
        eval $(opam config env)
    fi;
}

opam_create_stack ()
{
    local TARGETSWITCH=${1:-$(date +%m%d)};
    local TARGETCOMPILER=${2:-4.02.1+PIC};
    local CMD="opam switch install $TARGETSWITCH -A $TARGETCOMPILER";
    echo $CMD;
    echo;
    eval $CMD;
    eval $(opam config env);
    opam_install_stack
}

opam_install_stack ()
{
    opam install -y \
         `#survival` \
         merlin \
         oasis \
         ocp-indent \
         ocp-index \
         utop \
         `#bap dependencies` \
         bitstring \
         cmdliner \
         core_bench \
         core_kernel \
         piqi \
         zarith \
         `#end`;
    opam install -y \
         ocamlspot #factor this out since it's 4.01 only
}

opams ()
{
    sh -c "opam switch $1 $(($# == 1 ? 1 : 0))> /dev/null" |
        grep --color=always -e ' [CI] ' |
        sort;
    eval $(opam config env);
    echo;
    opam switch show
}

clone_github_bap ()
{
    git clone git@github.com:maverickwoo/bap.git;
    cd bap;

    # upstream
    git remote add upstream git@github.com:BinaryAnalysisPlatform/bap.git;

    # fetch other forks
    for user in \
        `#CMU` \
            dbrumley \
            ivg \
            rvantonder \
            tiffanyb \
        ; do
        echo $user;
        git remote add $user 'git@github.com:'$user'/bap.git';
    done;

    git fetch --all -p --progress;
    git fetch --all --tags;
    git status
}

oco ()
{
    rm -f \
       myocamlbuild.ml \
       setup.data \
       setup.log \
       setup.ml;
    oasis setup 2>&1 | grep --color -E '^|^W:.*';
    ./configure --override ocamlbuildflags "-j ${1:-6}" \
                --prefix=$(opam config var prefix) \
                `# enable test by default` \
                ${2:-"--enable-tests"} 2>&1 |
        grep --color -E \
             '^|^Warning.*|^Compile tests executable and library.*'
}
