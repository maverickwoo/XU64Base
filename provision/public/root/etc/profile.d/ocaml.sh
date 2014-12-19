export OCAMLPARAM='_,annot=0,bin-annot=1,g=1,short-paths=1'
export OCAMLRUNPARAM='b'
export OPAMKEEPBUILDDIR='yes'
export OPAMSOLVERTIMEOUT=160

alias utop='utop -principal -short-paths -strict-sequence -w +a-4-44'

## stack manipulation

opam_init ()
{
    if [ "$(opam switch 2> /dev/null)" ]; then
        echo 'opam switch already exists.';
    else
        opam init -a;
        sed -ri 's/^(jobs:).*/\1 '$(num_proc 2)'/' ~/.opam/config;
        eval $(opam config env)
    fi;
    opam_new_stack
}

opam_new_stack ()
{
    local TARGETSWITCH=${1:-$(date +%m%d)};
    local TARGETCOMPILER=${2:-4.02.1+PIC};
    local CMD="opam switch install $TARGETSWITCH -A $TARGETCOMPILER";
    echo $CMD;
    echo;
    eval $CMD;
    eval $(opam config env);
    opam_install_packages
}

opam_install_packages ()
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

## helper functions

oco ()
{
    rm -f \
       myocamlbuild.ml \
       setup.data \
       setup.log \
       setup.ml;
    oasis setup 2>&1 | grep --color -E '^|^W:.*';
    ./configure --override ocamlbuildflags "${1:--j $(num_proc 2)}" \
                --prefix=$(opam config var prefix) \
                `#enable test by default` \
                ${2:-"--enable-tests"} 2>&1 |
        grep --color -E \
             '^|^Warning.*|^Compile tests executable and library.*'
}

dotmerlin ()
{
    local extras=$(cat << "EOF"
EXT here
EXT nonrec
EXT ounit
FLG -short-paths
FLG -strict-sequence
PKG core_kernel
sREC
EOF
          );

    # To generate the regex below:
    # (princ (regexp-opt '("a" "cmi" "cmo" "cmt" "cmti" "cmx" "cmxa" "o") t)) ;'

    # note: on OSX my ~/bin/find -> /opt/local/bin/gfind
    find ${1:-.} \( -samefile ${1:-.} -printf "$extras\n" \) \
         -or \( -regex '.+\.mli?$' -printf 'S %h\n' \) \
         -or \( -regex '.+\.cm\(ti\|xa\|[iotx]\|[ao]\)$' -printf 'B %h\n' \) |
        sort -u
}

mkbyte ()
{
    find . -maxdepth 1 -type l -name \*.native -exec readlink {} \; |
        gawk -F'/_build/|.native$' '{print $2 ".byte"}' |
        xargs ocamlbuild $*
}

## bap specific

clone_github_bap ()
{
    git clone git@github.com:maverickwoo/bap.git;
    cd bap;

    # upstream
    git remote add upstream git@github.com:BinaryAnalysisPlatform/bap.git;

    # forks
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
