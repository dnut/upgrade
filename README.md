# upgrade

Simplify arch linux upgrades.

Now there is one command, `upgrade`, to upgrade your entire arch linux system with zero required user input unless there are conflicts. This package currently uses paru under the hood, but will always remain up to date, using the most reliable aur helper currently available.

This package also includes a systemd timer that runs upgrade every day at 5:30 am and 15 minutes after boot. There is no reason not to keep your system always up to date! If there are conflicts or other problems with the upgrade, you will need to manually resolve them. So it's a good idea to check occasionally that upgrade.service is succeeding.

To ensure that system upgrades do not interrupt normal system functioning, kernel-modules-hook is also a dependency.

## Configuration: /etc/upgrade.conf

`upgrade_aur`: Set to false if you are not interested in automating AUR upgrades.
`clean_cache_on_success`: Set to false if you would like to persist the package cache indefinitely.
