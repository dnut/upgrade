# shows upgrade's one-line summary of the notices that need attention, in the interactive login
# shells of root, wheel and upgraders. to see it in every bash or zsh, source this from ~/.bashrc or
# ~/.zshrc.
case $- in *i*)
    if [ -r /var/lib/upgrade/summary ] && { [ "$(id -u)" = 0 ] || id -Gn | grep -qwE 'wheel|upgraders'; }; then
        cat /var/lib/upgrade/summary >&2
    fi
esac
