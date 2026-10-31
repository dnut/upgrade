# shows upgrade's one-line summary of the notices that need attention, in interactive login shells.
# to see it in every bash or zsh, source this from ~/.bashrc or ~/.zshrc.
case $- in *i*)
    if [ -r /var/lib/upgrade/summary ]; then
        cat /var/lib/upgrade/summary >&2
    fi
esac
