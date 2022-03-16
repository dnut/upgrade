# upgrade

Simplify arch linux upgrades.

Now there is one command, `upgrade`, to upgrade your entire arch linux system with zero required user input unless there are conflicts. It also runs automatically every day at 5:30 am and 15 minutes after boot.

This package currently uses paru under the hood, but will adapt as necessary, always using the most reliable aur helper currently available.

You should always keep your system up to date! But the automation can be disabled if desired. Automation is handled by a systemd timer (upgrade.timer) that is enabled by default upon install. If there are conflicts or other problems with the upgrade, you will need to manually resolve them. So it's a good idea to check occasionally that upgrade.service is succeeding.

To ensure that automated system upgrades do not interrupt normal system functioning, kernel-modules-hook is also a dependency.

## Configuration

### /etc/upgrade.conf

- `upgrade_aur`: Set to false if you are not interested in automating AUR upgrades.
- `clean_cache_on_success`: Set to false if you would like to persist the package cache indefinitely.

### /etc/group

Anyone in the `upgraders` group has permission to execute the upgrade command.
