# 0.4.0

- Run the upgrade, autoremove and package cache cleanup as root inside systemd services, instead of through sudo in the session of whoever runs them. The `upgrade`, `autoremove` and `clearpkgcache` commands now start these services and show their output.
- Members of `upgraders` are allowed to start the services by a polkit rule, instead of sudo. Apart from `--dry-run`, only root can pass options to `autoremove`.
- Add `autoremove`, which removes orphaned packages after each upgrade.
- Keep the two most recent versions of each package in the cache, using paccache, instead of deleting the whole cache.
- Stop with an error if /etc/upgrade.conf can't be read or has an invalid line, instead of guessing.
- Fix AUR upgrades, which were skipped because of an unsupported `command -q` option.
- Depends on polkit, python, pyalpm and pacman-contrib.
- Build AUR packages as a new `aur-upgrader` user, with its home in /var/lib/aur-upgrader, instead of the `upgrade` user. It starts with empty caches, so if you configured yay or paru for `upgrade`, copy that configuration over. Once a run with this version has finished, delete the old user with `userdel -r upgrade`.
- The scheduled run that installs this version may fail once, because the old version is still running. The next run uses the new version.

# 0.3.0

- Add flatpak support.
- Run hourly instead of daily.

# 0.2.0

Get the upgrade and clearpkgcache scripts to use sudo to run themselves as upgrade, rather than using sudo to run the individual commands as upgrade. That way you can granularize permissions more cleanly. You can allow a user to run upgrade as upgrade. Then they can simply run the upgrade command and it will work. No explicit sudo needed by the user. And you don't have to grant that user permission to execute arbitrary pacman commands. They would be restricted to just what upgrade does.

Install upgrade.sudoers at /etc/sudoers.d/ instead of editing /etc/sudoers during install scripts for easier package maintenance.
