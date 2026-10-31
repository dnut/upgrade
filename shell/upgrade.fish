# shows upgrade's one-line summary of the notices that need attention, in the interactive shells of
# root, wheel and upgraders
if status is-interactive; and test -r /var/lib/upgrade/summary
    if test (id -u) = 0; or id -Gn | string split ' ' | string match -qr '^(wheel|upgraders)$'
        cat /var/lib/upgrade/summary >&2
    end
end
