# upgrade

Automate Arch Linux upgrades.

Finally, there is one command, `upgrade`, to upgrade your entire system with zero user input. By default, upgrade runs automatically every hour and 15 minutes after boot, so you never need to run a manual upgrade again.

Please read the [Risks](#risks) section below to understand why this functionality is not built-in to the system already, and why I have created it.

If you choose to enable AUR upgrades, `upgrade` will use either yay or paru under the hood, depending on what you have installed. It prefers yay if both are installed.

You should always keep your system up to date! But the automation can be disabled if desired. Automation is handled by a systemd timer (upgrade.timer) that is enabled by default upon install. If there are conflicts or other problems with the upgrade, you will need to manually resolve them. So it's a good idea to occasionally check `journalctl -u upgrade` for any errors.

## Running it yourself

The `upgrade`, `autoremove` and `clearpkgcache` commands start a systemd service (`upgrade.service`, `autoremove.service` or `clearpkgcache.service`) and show its output until it finishes. The work always runs inside the service, as root, and never in your own session. Only one of the three runs at a time, and running `upgrade` while the timer's upgrade is going follows that run instead of starting another.

To see the output, you need to be able to read the system journal, which root and the `wheel`, `adm` and `systemd-journal` groups can. Anyone else only sees whether the run succeeded. Pressing Ctrl-C stops showing the output, but the run carries on.

To stop a run that's in progress, stop the timer and mask the service first, so that nothing starts it again, then stop it:

```
systemctl stop upgrade.timer
systemctl mask --runtime upgrade.service
systemctl stop upgrade.service
```

Stopping it while pacman is changing packages can leave your system half upgraded. `systemctl unmask --runtime upgrade.service` and `systemctl start upgrade.timer` undo the first two steps.

To ensure that automated system upgrades do not interrupt normal system functioning, kernel-modules-hook is also a dependency.

## Installation

[upgrade](https://aur.archlinux.org/packages/upgrade) is available in the Arch User Repository.

## Configuration

### /etc/upgrade.toml

`upgrade` doesn't need this file. Create it only to change an option below, for example `upgrade_flatpak = false`. Any value other than `true` turns an option off, and `upgrade` stops with an error if the file isn't valid TOML. All the following default to true.
- `upgrade_aur`: Set to false if you are not interested in automating AUR upgrades, and only want to install packages from pacman's configured repositories.
- `upgrade_flatpak`: Set to false if you would like to prevent upgrades of system-wide flatpak packages.
- `clean_cache_on_success`: Set to false if you would like to keep every package in the cache indefinitely. When enabled, `clearpkgcache` keeps the two most recent versions of each installed package and the most recent version of each uninstalled package, so you can still roll back a bad update or reinstall a removed package.
- `autoremove`: Set to false if you would like to keep orphaned packages, which are dependencies that are no longer required or optionally required by any installed package. When enabled, `upgrade` runs `autoremove --noconfirm` after each upgrade, which keeps any of their configuration files that you modified as `.pacsave` files. See [Removing orphaned packages](#removing-orphaned-packages).

### /etc/group

Anyone in the `upgraders` group can run `upgrade`, `clearpkgcache` or `autoremove` without typing a password. A polkit rule lets them start the three services, but not stop, restart or kill them, and it doesn't give them any other privileges. Members of `wheel` can already start the services after typing their own password.

The `aur-upgrader` user is allowed to run pacman through sudo, so that yay or paru can install AUR packages. This requires /etc/sudoers to `@includedir /etc/sudoers.d`, which is already included by default in the arch linux installation of sudo. See [AUR packages](#aur-packages) for what this means for security.

## Removing orphaned packages

`autoremove` removes packages that were installed as dependencies and are no longer needed. `upgrade` runs `autoremove --noconfirm` after each upgrade when `autoremove` is enabled in /etc/upgrade.toml, and you can also run it yourself. By default it keeps packages that other packages optionally depend on, and keeps any config files you modified as `.pacsave` files.

When root runs `autoremove`, it runs directly in root's shell, has pacman show the full list of packages and ask before removing anything, and accepts any of the options below. Anyone can use `--dry-run`. Other users, such as members of `upgraders`, can only run it without options, which starts `autoremove.service` and removes the packages with the defaults and without asking.
- `--optdeps`: Also remove packages that other packages only optionally depend on.
- `--config`: Also delete config files that you modified, instead of keeping them as `.pacsave` files.
- `--noconfirm`: Remove the packages without asking.
- `--dry-run`: Only print the commands that would be run.

## Risks

Some users consider it a best practice to execute all upgrades manually. That way, you can proactively deal with any potential issues with new packages. Personally, I consider it a bigger risk to use outdated software than it is to automate upgrades.

Before installing this package, make sure you understand arch linux package management, the AUR, systemd, and how these things are used by this package to automate system upgrades. Do your own informed risk analysis.

After well over a decade of using arch linux as my primary operating system, I realized that I always use the default answers suggested by the package manager. `--noconfirm` is the obvious choice to execute the same steps that I was already executing manually. And if you're already running it with `--noconfirm`, then it actually makes zero difference on the outcome of the upgrade whether you trigger it manually or automatically on a schedule. Hence this tool was born.

I have been using this tool for a few years on several servers and personal computers without issue. It has been a huge success for me, keeping all my systems up to date at all times, something I always struggled with before creating this tool.

### AUR packages

When `upgrade_aur` is enabled, which is the default, `upgrade` builds and installs new versions of your AUR packages every hour without showing them to you first. Nobody reviews AUR packages before they're published, and malicious changes have reached the AUR before, including in packages that someone took over from their previous maintainer. Once a package is installed, its files and install scripts run as root. So you're trusting the maintainer of every AUR package you have installed, and anyone who gets into their account, with root access to your system.

The builds run as the `aur-upgrader` user, which can run pacman as root through sudo, because yay and paru need that to install packages and their build dependencies. So code that runs during a build can also get root. Building as a user without sudo wouldn't remove the risk, because the package a build produces is installed as root anyway. Only root and the upgrade services run anything as `aur-upgrader`, so no other user can use its sudo access. Keep it that way: anyone who can run commands as `aur-upgrader`, for example through a sudo rule, can get root.

If you want to read AUR changes before they're installed, set `upgrade_aur=false` in /etc/upgrade.toml, and upgrade AUR packages yourself with yay or paru, which can show you the changes first.
