### Testing

`test/run`, run as your own user, tests this checkout in a throwaway VM: the official Arch cloud image in QEMU, which it downloads once to `~/.cache/upgrade-test`. It builds the package there from the checkout, uncommitted changes included, installs it, then checks the install, the services, the polkit rule, the lock, the config, a failed step, notices and a run that upgrades upgrade itself, printing PASS or FAIL for each. It needs `qemu` and access to `/dev/kvm`. When it runs in a terminal, it keeps the VM running until you press Enter, for a check by hand that it prints at the end.

GitHub Actions runs it on every push to master and every pull request, and before a release tag is published to the AUR, see `.github/workflows/test.yml`.
