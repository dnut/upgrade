# upgrade

Automate Arch Linux upgrades.

Finally, there is one command, `upgrade`, to upgrade your entire system with zero user input. By default, upgrade runs automatically every hour and 15 minutes after boot, so you never need to run a manual upgrade again.

Please read the [Risks](#risks) section below to understand why this functionality is not built-in to the system already, and why I have created it.

If you choose to enable AUR upgrades, `upgrade` will use either yay or paru under the hood, depending on what you have installed. It prefers yay if both are installed.

You should always keep your system up to date! But the automation can be disabled if desired. Automation is handled by a systemd timer (upgrade.timer) that is enabled by default upon install. If there are conflicts or other problems with the upgrade, you will need to manually resolve them. So it's a good idea to occasionally check `journalctl -u upgrade` for any errors.

To ensure that automated system upgrades do not interrupt normal system functioning, kernel-modules-hook is also a dependency.

## Installation

[upgrade](https://aur.archlinux.org/packages/upgrade) is available in the Arch User Repository.

## Configuration

### /etc/upgrade.conf

All the following default to true. Each option in the file must be set to `true` or `false`. If the file can't be read, or has any other line apart from comments, `upgrade` stops with an error.
- `upgrade_aur`: Set to false if you are not interested in automating AUR upgrades, and only want to install packages from pacman's configured repositories.
- `upgrade_flatpak`: Set to false if you would like to prevent upgrades of system-wide flatpak packages.
- `clean_cache_on_success`: Set to false if you would like to persist the package cache indefinitely.
- `autoremove`: Set to false if you would like to keep orphaned packages, which are dependencies that are no longer required or optionally required by any installed package. When enabled, `upgrade` runs `autoremove --noconfirm` after each upgrade, which keeps any of their configuration files that you modified as `.pacsave` files. See [Removing orphaned packages](#removing-orphaned-packages).

### /etc/group

Anyone in the `upgraders` group has permission to execute `upgrade`, `clearpkgcache` or `autoremove` without typing a password. This requires /etc/sudoers to `@includedir /etc/sudoers.d`, which is already included by default in the arch linux installation of sudo.

## Removing orphaned packages

`autoremove` removes packages that were installed as dependencies and are no longer needed. `upgrade` runs `autoremove --noconfirm` after each upgrade when `autoremove` is enabled in /etc/upgrade.conf, and you can also run it yourself. By default it keeps packages that other packages optionally depend on, keeps any config files you modified as `.pacsave` files, and has pacman show the full list of packages and ask before removing anything.
- `--optdeps`: Also remove packages that other packages only optionally depend on.
- `--config`: Also delete config files that you modified, instead of keeping them as `.pacsave` files.
- `--noconfirm`: Remove the packages without asking.
- `--dry-run`: Only print the commands that would be run.

## Risks

Some users consider it a best practice to execute all upgrades manually. That way, you can proactively deal with any potential issues with new packages. Personally, I consider it a bigger risk to use outdated software than it is to automate upgrades.

Before installing this package, make sure you understand arch linux package management, the AUR, systemd, and how these things are used by this package to automate system upgrades. Do your own informed risk analysis.

After well over a decade of using arch linux as my primary operating system, I realized that I always use the default answers suggested by the package manager. `--noconfirm` is the obvious choice to execute the same steps that I was already executing manually. And if you're already running it with `--noconfirm`, then it actually makes zero difference on the outcome of the upgrade whether you trigger it manually or automatically on a schedule. Hence this tool was born.

I have been using this tool for a few years on several servers and personal computers without issue. It has been a huge success for me, keeping all my systems up to date at all times, something I always struggled with before creating this tool.
