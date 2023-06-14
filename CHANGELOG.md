# 0.3.0

- Add flatpak support.
- Run hourly instead of daily.

# 0.2.0

Get the upgrade and clearpkgcache scripts to use sudo to run themselves as upgrade, rather than using sudo to run the individual commands as upgrade. That way you can granularize permissions more cleanly. You can allow a user to run upgrade as upgrade. Then they can simply run the upgrade command and it will work. No explicit sudo needed by the user. And you don't have to grant that user permission to execute arbitrary pacman commands. They would be restricted to just what upgrade does.

Install upgrade.sudoers at /etc/sudoers.d/ instead of editing /etc/sudoers during install scripts for easier package maintenance.
