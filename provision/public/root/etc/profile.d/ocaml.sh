export OCAMLPARAM='_,annot=0,bin-annot=1,g=1,short-paths=1'
export OCAMLRUNPARAM='b'
export OPAMKEEPBUILDDIR='yes'
export OPAMSOLVERTIMEOUT='160'

alias utop='utop -principal -short-paths -strict-sequence -w +a-4-44'

## stack manipulation

my_opam_init ()
{
    if [ "$(opam switch 2>/dev/null)" ]; then
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
    local CMD="opam switch install -v $TARGETSWITCH -A $TARGETCOMPILER";
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
         dum \
         merlin \
         oasis \
         ocp-indent \
         ocp-index \
         utop \
         `#bap dependencies` \
         bitstring \
         cmdliner \
         cohttp \
         core_bench \
         core_kernel \
         ezjsonm \
         faillib \
         lwt-zmq \
         uri \
         zarith \
         `#nice to have` \
         menhir \
         sqlite3 \
         `#end`;
    opam install -y \
         ocamlspot #factor this out since it's 4.01 only
}

opams ()
{
    opam switch $1 2>/dev/null | grep --color=always -e ' [CI] ' | sort;
    eval $(opam config env);
    echo;
    opam switch show
}

## helper functions

rm_if_untracked ()
{
    for x in "$@"; do
        git ls-files --error-unmatch "$x" &>/dev/null || rm -f "$x";
    done
}

oco ()
{
    rm_if_untracked \
       setup.data \
       setup.log \
       setup.ml;
    local enable_tests=$(\
        ls -F . |
            awk '/.*_test\// { print "--enable-tests"; exit }');
    oasis setup 2>&1 | grep --color -E '^W:.*|^';
    ./configure --override ocamlbuildflags "${1:--j $(num_proc 2)}" \
                --prefix=$(opam config var prefix) \
                $enable_tests "${@:2}" 2>&1 |
        grep --color -E \
             -e '^Compile tests executable and library.*' \
             -e '^Install architecture-independent files dir.*' \
             -e '^Warning.*' \
             -e '^'             #display everything else but with no highlight
}

dotmerlin ()
{
    local extras=$(cat <<"EOF"
EXT custom_printf
EXT here
EXT js
EXT lwt
EXT nonrec
EXT ounit
FLG -short-paths
FLG -strict-sequence
PKG core_kernel
REC
EOF
          );

    # To generate the regex below:
    # (princ (regexp-opt '("ml" "mli" "mll" "mly") t)) ;'
    # (princ (regexp-opt '("a" "cmi" "cmo" "cmt" "cmti" "cmx" "cmxa" "o") t)) ;'

    # note: on OSX my ~/bin/find -> /opt/local/bin/gfind
    find ${1:-.} \( -samefile ${1:-.} -printf "$extras\n" \) \
         -or \( -regex '.+\.ml[ily]?$' -printf 'S %h\n' \) \
         -or \( -regex '.+\.cm\(ti\|xa\|[iotx]\|[ao]\)$' -printf 'B %h\n' \) |
        cat .merlin - 2> /dev/null |
        sort -u
}

mkbyte ()
{
    find . -maxdepth 1 -type l -name \*.native -exec readlink {} \; |
        gawk -F'/_build/|.native$' '{print $2 ".byte"}' |
        xargs ocamlbuild -tag syntax_camlp4o "$@"
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
