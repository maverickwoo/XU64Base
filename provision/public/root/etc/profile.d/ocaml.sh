export OCAMLPARAM='_,annot=0,bin-annot=1,g=1,short-paths=1'
export OCAMLRUNPARAM='b'
export OPAMKEEPBUILDDIR='true'
export OPAMSOLVERTIMEOUT='160'

alias utop='utop -principal -short-paths -strict-sequence -w +a-4-44'

## bitstring hack
if [ -d $(opam config var prefix)/lib/bitstring ]; then
    ln -sf ../ocaml/unix.cma $(opam config var prefix)/lib/bitstring
fi

## stack manipulation

my_opam_init ()
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
    local CMD="opam switch install -v $TARGETSWITCH -A $TARGETCOMPILER";
    echo $CMD;
    echo;
    eval $CMD;
    eval $(opam config env);
    echo "Run opam_install_packages to install recommended packages."
}

opam_install_packages ()
{
    # bap dependencies
    opam install -y --deps-only bap
    # others
    opam install -y \
         `#survival` \
         dum \
         merlin \
         oasis \
         ocp-indent \
         ocp-index \
         utop \
         `#nice to have and fast to compile` \
         menhir \
         sqlite3 \
         `#end`;
    opam install -y \
         ocamlspot #factor this out since it's 4.01 only
}

opams ()
{
    opam switch $1 2> /dev/null | grep --color=always -e ' [CI] ' | sort;
    eval $(opam config env);
    echo;
    opam switch show
}

## helper functions

rm_if_untracked ()
{
    for x in "$@"; do
        git ls-files --error-unmatch "$x" &> /dev/null || rm -f "$x";
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
    # Usually we run dotmerlin at the root of a project directory and so we
    # optimize the default case for this use.

    if [ $# -eq 0 ]; then
        # no arg: this dir, with REC
        local specific=$(cat <<EOF
B ./_build/**
REC
S .
S ./_build/**
S ./lib/**
S ./src/**
EOF
              );
    else                        #we have a real $1
        if [ "$1" == "" ]; then
            # an empty arg: current stack
            local target=$(opam config var prefix);
        else
            # non-empty arg: specific stack
            local target=$1;
        fi;
        local specific=$(cat <<EOF
B $target/**
S $target/**
EOF
              );
    fi;
    # 4 fragile pattern match, e.g., wildcard; I disable this even in actual
    # 26, 27 are unused variables; very annoying inside merlin
    # 29 is unescaped eof in a string; somewhat annoying inside merlin
    # 44 open shadows already-defined identifier; I disable this even in actual
    local common=$(cat <<EOF
EXT custom_printf
EXT here
EXT js
EXT lwt
EXT nonrec
EXT ounit
FLG -short-paths
FLG -strict-formats
FLG -strict-sequence
FLG -w +a-4-26-27-29-44
PKG core_kernel
PKG dum
EOF
          );

    # To generate the regex below:
    # (princ (regexp-opt '("ml" "mli" "mll" "mly") t)) ;'
    # (princ (regexp-opt '("a" "cmi" "cmo" "cmt" "cmti" "cmx" "cmxa" "o") t)) ;'

    # Historically there was no ** and so we had to use GNU find:
    # find ${1:-.} \( -samefile ${1:-.} -printf "$specific\n$common\n" \) \
    #      -or \( -regex '.+\.ml[ily]?$' -printf 'S %h\n' \) \
    #      -or \( -regex '.+\.cm\(ti\|xa\|[iotx]\|[ao]\)$' -printf 'B %h\n' \) |

    printf "$specific\n$common\n" |
        cat .merlin - 2> /dev/null |
        sort -u
}

mkbyte ()
{
    # Given a directory with .native files, build the corresponding .byte files.
    find . -maxdepth 1 -type l -name \*.native -exec readlink {} \; |
        gawk -F'/_build/|.native$' '{print $2 ".byte"}' |
        xargs ocamlbuild -tag syntax_camlp4o "$@"
}

## bap specific

clone_github_bap ()
{
    # clone if we are not in a clone
    if [ 'bap' != $(basename `pwd`) ]; then
        git clone git@github.com:maverickwoo/bap.git;
        cd bap;
    fi;

    # upstream
    git remote add upstream git@github.com:BinaryAnalysisPlatform/bap.git;

    # forks
    for user in \
        `#CMU` \
            dbrumley \
            ddcc \
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
