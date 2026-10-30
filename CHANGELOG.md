# 0.4.0

This release makes `upgrade` safer. It hardens the permission model and uses lower-risk defaults for its automation. It also adds a new `autoremove` capability to clean up orphans.

- Runs in systemd services, which polkit lets users start, instead of running scripts through sudo.
  - The upgrade and cache cleanup run as root in oneshot services, so `systemctl start` waits for them to finish. The `upgrade` and `clearpkgcache` commands start the service and show its output.
  - `upgraders` can start the services without a password, and `wheel` after typing theirs.
  - Seeing the output needs access to the journal: root, `wheel`, `adm` or `systemd-journal`. Others only see whether the run succeeded.
  - Running a command while it's already running follows that run. Only one of upgrade, autoremove and clearpkgcache runs at a time.
  - Shutdown is blocked while packages are changing.
- Adds `autoremove`, which removes orphaned packages. `upgrade` runs it after each upgrade unless `autoremove = false`.
- upgrade.timer is no longer enabled on install. Enable it with `systemctl enable --now upgrade.timer`. Upgrading keeps it enabled.
- AUR packages are built by a new `aur-upgrader` user instead of `upgrade`. Copy over any yay or paru configuration. After a run on this version, the old user can be deleted with `userdel -r upgrade`.
- AUR packages are no longer upgraded by default. Set `upgrade_aur = true` to keep them upgrading.
  - `upgrade` still updates itself from the AUR on every run, unless it's in pacman.conf's `IgnorePkg`.
- Other changes:
  - Settings move from /etc/upgrade.conf to /etc/upgrade.toml, which isn't installed by default. A changed upgrade.conf is moved there on upgrade. An invalid file stops the run.
  - Missing settings use their defaults instead of being off. A changed upgrade.conf from before 0.3.0 has no `upgrade_flatpak`, so flatpak upgrades turn on.
  - A failed step no longer stops the ones after it, but the run still fails.
  - The cache cleanup keeps the two latest versions of each installed package and the latest of each removed one, instead of deleting everything. It deletes all AUR build files, not just paru's.
  - Depends on polkit, python, pyalpm, pacman-contrib, git and fakeroot.
  - The scheduled run that installs this version may fail once. The next run uses the new version.

# 0.3.0

- Add flatpak support.
- Run hourly instead of daily.

# 0.2.0

Get the upgrade and clearpkgcache scripts to use sudo to run themselves as upgrade, rather than using sudo to run the individual commands as upgrade. That way you can granularize permissions more cleanly. You can allow a user to run upgrade as upgrade. Then they can simply run the upgrade command and it will work. No explicit sudo needed by the user. And you don't have to grant that user permission to execute arbitrary pacman commands. They would be restricted to just what upgrade does.

Install upgrade.sudoers at /etc/sudoers.d/ instead of editing /etc/sudoers during install scripts for easier package maintenance.
