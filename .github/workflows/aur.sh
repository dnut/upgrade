#!/usr/bin/bash
# publishes the PKGBUILD to the AUR for the given tag. run by aur.yml as root, in an archlinux
# container, with the AUR ssh key in AUR_SSH_KEY.
set -euo pipefail

main() { local tag=$1 files
    cd "$(dirname "$0")/../.."
    check_tag "$tag"
    pacman -Syu --noconfirm --needed git openssh
    files=$(mktemp -d)
    cp PKGBUILD upgrade.install "$files"
    write_srcinfo "$files"
    push_to_aur "$files" "$tag"
}

# only publish a PKGBUILD from the release it names, which is tagged v<pkgver>
check_tag() { local tag=$1
    source PKGBUILD
    if [[ $pkgrel != 1 ]]; then
        echo "::error::pkgrel is $pkgrel, but it should be hardcoded to 1. pkgrel is not used for upgrade since the project is self-packaged."
        exit 1
    fi
    if [[ $tag != "v$pkgver" ]]; then
        echo "::error::The tag is $tag, but the PKGBUILD is version $pkgver, which is tagged v$pkgver."
        exit 1
    fi
}

# makepkg refuses to run as root, so .SRCINFO is generated as nobody, in a folder it owns
write_srcinfo() { local dir=$1
    chown -R nobody "$dir"
    (cd "$dir" && runuser -u nobody -- makepkg --printsrcinfo >.SRCINFO)
}

# commits the PKGBUILD, upgrade.install and .SRCINFO from dir to the AUR repo, and pushes them
push_to_aur() { local dir=$1 tag=$2 ssh aur
    # explicit paths, since ssh looks for ~/.ssh in root's home, which isn't $HOME in a container
    ssh=$(mktemp -d)
    (umask 077 && printf '%s\n' "$AUR_SSH_KEY" >"$ssh/key")
    # check against the fingerprints on https://aur.archlinux.org before changing this
    echo 'aur.archlinux.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuBKrPzbawxA/k2g6NcyV5jmqwJ2s+zpgZGZ7tpLIcN' >"$ssh/known_hosts"
    export GIT_SSH_COMMAND="ssh -i $ssh/key -o IdentitiesOnly=yes -o UserKnownHostsFile=$ssh/known_hosts -o StrictHostKeyChecking=yes"

    aur=$(mktemp -d)
    git clone ssh://aur@aur.archlinux.org/upgrade.git "$aur"
    cp "$dir"/{PKGBUILD,upgrade.install,.SRCINFO} "$aur"
    git -C "$aur" add PKGBUILD upgrade.install .SRCINFO
    git -C "$aur" -c user.name='Drew Nutter' -c user.email=dnut@users.noreply.github.com commit -m "upgrade to $tag"
    git -C "$aur" push
}

main "$@"
