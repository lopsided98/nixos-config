#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nixos-secrets
set -eu

usage() {
  echo "$0 [-ns] <machine>"
}

deploy=1
sync=0 # Whether to synchronize configuration to the machine

while getopts "ns" opt; do
    case "$opt" in
        n) deploy=0; sync=1 ;;
        s) sync=1 ;;
        \?) usage ;;
    esac
done
shift "$(($OPTIND -1))"

# See https://gist.github.com/tvlooy/cbfbdb111a4ebad8b93e
nixos_root="$(dirname $(readlink -f "$0"))"
ssh_control_path="~/.ssh/master-%r@%h:%p.sock"

nixos-secrets check "${nixos_root}/secrets"

ssh_host="${1}"
shift

if [ "${deploy}" -eq 1 ]; then
    toplevel_drv_link="${ssh_host}.system.drv"
    toplevel_link="${ssh_host}.system"

    toplevel_drv_link=$(nix-instantiate --add-root "${toplevel_drv_link}" --indirect --show-trace \
        "${nixos_root}/machines" -A "${ssh_host}.config.system.build.toplevel")

    toplevel_drv="$(readlink "${toplevel_drv_link}")"

    nix copy --to "ssh://${ssh_host}" "${toplevel_drv}"

    toplevel_link=$(ssh -oControlMaster=auto -oControlPath=\"${ssh_control_path}\" "${ssh_host}" -- \
        nix-store -r --add-root "${toplevel_link}" --indirect "${toplevel_drv}")
fi

read -sp "[sudo] password for ${USER}: " sudo_password
echo

if [ "${sync}" -eq 1 ]; then
    rsync -e "ssh -oControlPath=\"${ssh_control_path}\"" --rsync-path="echo \"${sudo_password}\" | sudo -Sv 2>/dev/null; sudo rsync" -rlpt --delete "${nixos_root}/" "${ssh_host}:/etc/nixos"
fi

if [ "${deploy}" -eq 1 ]; then
    ssh -oControlMaster=auto -oControlPath=\"${ssh_control_path}\" "${ssh_host}" -- \
        sudo -Sv 2>/dev/null \; \
        sudo -n nix-env -p /nix/var/nix/profiles/system --set "${toplevel_drv}" \; \
        sudo -n "${toplevel_link}/bin/switch-to-configuration" switch \; \
        rm -f "${toplevel_link}" \
        <<< "${sudo_password}"

    rm -f "${toplevel_drv_link}"
fi
