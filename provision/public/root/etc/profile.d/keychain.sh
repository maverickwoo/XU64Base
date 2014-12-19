case "$OSTYPE" in
    linux*)
        if which keychain &> /dev/null; then
            eval $(keychain --eval --ignore-missing ~/.ssh/* 2> /dev/null);
        fi;;
esac
