# shows upgrade's one-line summary of the notices that need attention, in interactive shells
if status is-interactive; and test -r /var/lib/upgrade/summary
    cat /var/lib/upgrade/summary >&2
end
