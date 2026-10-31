# `upgrade` - Automate Arch Linux upgrades.

Finally, the system can update itself.

**Install:**
```sh
yay -S upgrade
```

**Run a full system upgrade (pacman, flatpak, optionally AUR):**
```sh
upgrade
```

**Enable unattended updates:**
```sh
systemctl enable --now upgrade.timer
```

`upgrade` will then run automatically every hour and 15 minutes after boot, so you no longer need to run routine manual upgrades. The scheduled runs are skipped while the system is on battery, or on a connection that NetworkManager says is metered.

Please read the [Risks](#risks) section below to understand why this functionality is not built-in to the system already, and why I have created it.

If you choose to enable AUR upgrades, `upgrade` will use either yay or paru under the hood, depending on what you have installed. It prefers yay if both are installed, since paru has a recent history of breakages that prevented upgrades and were not fixed for several months.

If there are conflicts or other problems that make it impossible to update automatically, you will need to manually resolve them. There will also inevitably be things that need administrative maintenance after upgrades, such as pacnew files, messages from packages and Arch Linux news. `upgrade` keeps track of them and tells you about them, see [Notices](#notices).

## Running it yourself

There are three commands available to users:
- `upgrade`: Runs the full system upgrade workflow, upgrading all packages in accordance with the configuration. `upgrade status` shows the [notices](#notices) of what runs left for you, and root acknowledges them with `upgrade ack`.
- `autoremove`: Removes orphaned packages. By default it runs conservatively, but root can pass options for a more thorough pruning. See [Removing orphaned packages](#removing-orphaned-packages).
- `clearpkgcache`: Prunes pacman's package cache and clears the build caches of AUR helpers.

If the same command is already running, for example from the timer, it shows that run's output instead of starting another. Only one of the three runs at a time, so a different one waits for the first to finish.

Your user must be root or in the `upgraders` group to run any of the three commands. Members of `wheel` can also run them after typing their own password. To see the output, you need to be able to read the system journal, which root and the `wheel`, `adm` and `systemd-journal` groups can. Anyone else only sees whether the run succeeded.

Under the hood, these commands work by starting a oneshot systemd service (`upgrade.service`, `autoremove.service` or `clearpkgcache.service`) and showing the journal logs of that service until it finishes. The work always runs inside the service, as root, and never in your own session. This is for security: it isolates the execution environment completely from your user. The exception is `autoremove` when it's run as root or with options, which runs in your own shell, as described in [Removing orphaned packages](#removing-orphaned-packages).

Pressing Ctrl-C stops showing the output, but the run will continue behind the scenes.

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

### Building from this repo

The PKGBUILD builds the release tagged with its version, for example `v0.4.0`, downloaded from github. To build the checkout you're in instead, including uncommitted changes, run `./makepkg`, which takes makepkg's options, for example `./makepkg -si` to install it. The package is put in `dist/`, and the build itself happens in a temporary folder that's removed afterwards.

## Configuration

### /etc/upgrade.toml

Create this file to customize the behavior away from the defaults. It does not exist on a vanilla install, and it is not typically required. It only needs the options you change, for example `upgrade_flatpak = false`.

- `upgrade_aur`: Defaults to false. Set to true to also upgrade AUR packages with yay or paru. Read [Risks/AUR packages](#aur-packages) first.
- `upgrade_flatpak`: Defaults to true. Upgrades system-wide flatpak packages when true.
- `clean_cache_on_success`: Defaults to true. When enabled, `upgrade` runs `clearpkgcache` at the end of a run where nothing failed. Set to false if you would like to keep every package in the cache indefinitely. `clearpkgcache` keeps the two most recent versions of each installed package and the most recent version of each uninstalled package, so you can still roll back a bad update or reinstall a removed package. It also deletes the AUR build files that yay, paru and the self-update leave in `/var/lib/aur-upgrader/.cache`.
- `autoremove`: Defaults to true. When enabled, `upgrade` runs `autoremove --noconfirm` after each upgrade, to remove orphaned packages. Orphans are dependencies that are no longer required or optionally required by any installed package. Any of their configuration files that you modified are kept as `.pacsave` files. See [Removing orphaned packages](#removing-orphaned-packages).
- `noconfirm`: Defaults to true. pacman answers its own questions with their defaults, such as whether to replace one package with another, and the run's notice lists them. Set to false to have upgrades wait for you to answer them instead. See [Notices](#notices).
- `block_on_news`: Defaults to false. Set to true to stop upgrading packages while there's Arch Linux news you haven't acknowledged with `upgrade ack`. Some posts announce manual steps needed before an upgrade, but others urge everyone to upgrade right away, which this would hold back too. News is a notice either way.
- `notifications`: Defaults to `["motd", "shell", "wall", "desktop"]`. The ways you're told about notices, see [Notices](#notices). `[]` turns them all off.

Any value other than `true` turns an option off, `notifications` can only list those four, and `upgrade` stops with an error if the file isn't valid TOML.

### /etc/group

Anyone in the `upgraders` group can run `upgrade`, `clearpkgcache` or `autoremove` without typing a password. A polkit rule lets them start the three services, but not stop, restart or kill them. polkit can't see how systemd is asked to queue a start, though, so they can also pass systemctl's `--job-mode`, which can cancel other queued systemd jobs, or keep a run from being stopped until it ends. Only add users you trust with that. Members of `wheel` can already start the services after typing their own password.

The `aur-upgrader` user is allowed to run pacman through sudo, so that yay or paru can install AUR packages. This requires /etc/sudoers to `@includedir /etc/sudoers.d`, which is already included by default in the arch linux installation of sudo. See [AUR packages](#aur-packages) for what this means for security.

## Removing orphaned packages

`autoremove` removes packages that were installed as dependencies and are no longer needed. `upgrade` runs `autoremove --noconfirm` after each upgrade when `autoremove` is enabled in /etc/upgrade.toml, and you can also run it yourself. By default it keeps packages that other packages optionally depend on, and keeps any config files you modified as `.pacsave` files.

When root runs `autoremove`, it runs directly in root's shell, has pacman show the full list of packages and ask before removing anything, and accepts any of the options below. When other users, such as members of `upgraders`, run it without options, it starts `autoremove.service`, which removes the packages with the defaults and without asking. With options, it runs in their own shell instead, where only `--dry-run` and `--help` are of use, since pacman only lets root remove packages.
- `--optdeps`: Also remove packages that other packages only optionally depend on.
- `--config`: Also delete config files that you modified, instead of keeping them as `.pacsave` files.
- `--noconfirm`: Remove the packages without asking.
- `--dry-run`: Only print the commands that would be run.

## Notices

Each run records what it leaves for you to read or handle, as notices:
- Arch Linux news posts.
- pacman's questions, such as whether to replace one package with another.
- `.pacnew`, `.pacsave` and `.pacorig` files waiting to be merged.
- What install scripts printed, new optional dependencies, and pacman's warnings and errors during the upgrade.
- Steps that failed, and runs that stopped with an error.

`upgrade status` shows them, and root acknowledges them with `upgrade ack`, which shows them again as it clears them. Notices of things that `upgrade` can check again, such as pacnew files and failing steps, also clear by themselves once they're handled. An acknowledged one stays quiet until it changes, for example when a new `.pacnew` file arrives.

Some notices can block upgrades until they're acknowledged: Arch Linux news when `block_on_news = true`, and pacman's questions when `noconfirm = false`. With `noconfirm = false`, each run first asks pacman for its questions in a dry run, and if there are any, changes nothing until you answer them by running `pacman -Syu` yourself, or acknowledge them, so that the next run answers them with the defaults. While upgrades are blocked, nothing goes through pacman: not the system upgrade, the AUR packages, `upgrade`'s self-update or autoremove. flatpak packages still upgrade. Blocked runs fail, so `systemctl status upgrade` shows it too.

You're told about notices in the ways that `notifications` in /etc/upgrade.toml lists, all of them by default:
- `motd`: at console and SSH logins, through pam_motd. Everyone who logs in sees it.
- `shell`: a one-line summary in the login shells of root, `wheel` and `upgraders`, and in all their interactive fish shells. To see it in every bash or zsh, add `. /etc/profile.d/upgrade.sh` to your `~/.bashrc` or `~/.zshrc`.
- `wall`: a one-line message on the terminals of everyone logged in.
- `desktop`: a desktop notification for root, `wheel` and `upgraders`, if libnotify is installed.

`wall` and `desktop` only send for the timer's runs, when they find something new, and once a day while upgrades are blocked. A run you start yourself lists the notices at the end of its output instead.

## Risks

System upgrades may require manual intervention to ensure everything is working as you intended. For example:
- pacman asks for your confirmation before replacing one package with another, in case you specifically prefer the original package
- if you changed a config file that the new version also changes, pacman keeps yours and saves the new one next to it as a `.pacnew` file, for you to merge
- packages themselves may choose to print messages for the administrator to act on to deal with the upgrade
- some upgrades need manual steps that are only announced in the [Arch Linux news](https://archlinux.org/news/), which pacman doesn't show at all

`upgrade` tells you about each of these, and can stop for pacman's questions and the news, see [Notices](#notices).

Some users consider it a best practice to execute all upgrades manually so the administrator can deal with these things during the upgrade.

Before using this package, you must ask yourself:
- Am I willing to accept pacman's default answer to every question it asks during an upgrade?
- Am I willing to monitor the upgrade logs and the Arch Linux news, and perform compatibility fixes asynchronously, rather than performing them immediately after the upgrade?

If you answer "yes" to both questions, then it may be reasonable for you to fully automate your upgrades. If you only answer "yes" to the first question, you may still find `upgrade` useful for streaminling your manual upgrade process.

Personally, I consider it a bigger risk to use outdated software than it is to automate upgrades. Security vulnerabilities may be exploited within hours of their publication.

If an upgrade does break something, you can downgrade to an older version from pacman's cache, where `clearpkgcache` keeps the two most recent versions of each package. Snapshot tools such as snap-pac also take a snapshot of your filesystem on every pacman run, including the scheduled ones.

After well over a decade of using arch linux as my primary operating system, I realized that I always, without exception, use the default answers suggested by the package manager. `--noconfirm` is the obvious choice to execute the same steps that I was already executing manually. And if you're already running it with `--noconfirm`, then it actually makes zero difference on the outcome of the upgrade whether you trigger it manually or automatically on a schedule. Hence this tool was born.

I have been using this tool since version 0.1.0 on several servers and personal computers without issue. It has been a huge success for me, keeping all my systems up to date at all times, something I always struggled with before creating this tool.

### AUR packages

AUR packages are susceptible to supply-chain attacks, so their upgrades are disabled by default. Be very cautious when upgrading these packages.

When you enable `upgrade_aur`, `upgrade` builds and installs new versions of your AUR packages every hour without showing them to you first. Nobody reviews AUR packages before they're published, and malicious changes have reached the AUR before, including in packages that someone took over from their previous maintainer. Once a package is installed, its files and install scripts run as root. So you're trusting the maintainer of every AUR package you have installed, and anyone who gets into their account, with root access to your system.

The builds run as the `aur-upgrader` user, which can run pacman as root through sudo, because yay and paru need that to install packages and their build dependencies. So code that runs during a build can also get root. Building as a user without sudo wouldn't remove the risk, because the package a build produces is installed as root anyway. Only root and the upgrade services run anything as `aur-upgrader`, so no other user can use its sudo access. Keep it that way: anyone who can run commands as `aur-upgrader`, for example through a sudo rule, can get root.

Whether or not `upgrade_aur` is on, `upgrade` updates itself from the AUR on every run, so its own fixes always arrive, unless you add it to `IgnorePkg` in /etc/pacman.conf. It's built as `aur-upgrader` too, so you're trusting its maintainer (me) the same way you did when you installed it.

If you'd rather read AUR changes before they're installed, leave `upgrade_aur` off and upgrade AUR packages yourself with yay or paru, which can show you the changes first.
