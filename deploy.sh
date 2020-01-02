#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nixos-secrets
set -euo pipefail

# See https://gist.github.com/tvlooy/cbfbdb111a4ebad8b93e
nixos_root="$(dirname $(readlink -f "$0"))"
ssh_control_path="~/.ssh/master-%r@%h:%p.sock"

# Mapping from system name to Hydra jobset
declare -A system_jobset
system_jobset[armv6l-linux]=master-custom
system_jobset[armv7l-linux]=master-custom
system_jobset[aarch64-linux]=unstable-custom
system_jobset[x86_64-linux]=unstable-custom

usage() {
  echo "$0 [-nps] <machine>"
}

machine_toplevel_drv_link() { echo "${1}.system.drv"; }
machine_toplevel_link() { echo "${1}.system"; }

machine_system() {
  # TODO: fix system detection with cross compiling
  nix eval --raw -f "${nixos_root}/machines" "${1}.config.nixpkgs.localSystem.system"
}

machine_jobset() {
  echo "${system_jobset["$(machine_system "${1}")"]}"
}

machine_ssh() {
  local machine="${1}"
  shift
  ssh -oControlMaster=auto -oControlPath=\"${ssh_control_path}\" \
    "${machine}" -- "${@}"
}

realize_ssh() {
  local machine="${1}"

  # Instantiate configuration on local machine. This prevents underpowered
  # machines from having to perform the evaluation themselves.
  local toplevel_drv_link
  toplevel_drv_link=$(nix-instantiate "${nixos_root}/machines" \
    --add-root "$(machine_toplevel_drv_link "${machine}")" --indirect \
    --show-trace -A "${1}.config.system.build.toplevel") || return 1
  local toplevel_drv
  toplevel_drv="$(readlink "${toplevel_drv_link}")" || return 1

  # Copy instantiated (but not realized config) to machine
  nix copy --to "ssh://${machine}" "${toplevel_drv}" 1>&2

  machine_ssh "${machine}" nix-store --realize "${toplevel_drv}" \
    --add-root "$(machine_toplevel_link "${machine}")" --indirect >/dev/null

  echo "$(nix-store --query --outputs "${toplevel_drv}")"
}

realize_hydra() {
  local machine="${1}"

  # Uses a hardcoded netrc file for now because I am probably going to open up
  # my Hydra instance soon
  local toplevel
  toplevel="$(curl -sL --netrc-file /etc/nix/netrc -H 'Accept: application/json' \
    "https://hydra.benwolsieffer.com/job/localpkgs/$(machine_jobset "${machine}")/machines.${machine}/latest" \
    | jq -r .buildoutputs.out.path)" || return 1

  machine_ssh "${machine}" nix-store --realize "${toplevel}" \
    --add-root "$(machine_toplevel_link "${machine}")" --indirect >/dev/null

  echo "${toplevel}"
}

activate() {
  local machine="${1}"
  local toplevel="${2}"

  machine_ssh "${machine}" \
    sudo -Sv 2>/dev/null \; \
    sudo -n nix-env -p /nix/var/nix/profiles/system --set "${toplevel}" \; \
    sudo -n "${toplevel}/bin/switch-to-configuration" switch \
    <<< "${sudo_password}"
}

deploy=1
deploy_hydra=0
sync=0 # Whether to synchronize configuration to the machine

while getopts "nps" opt; do
  case "$opt" in
    n) deploy=0; sync=1 ;;
    p) deploy_hydra=1 ;;
    s) sync=1 ;;
    \?) usage ;;
  esac
done
shift "$(($OPTIND -1))"

nixos-secrets -c "${nixos_root}/secrets" check

machine="${1}"
shift

if [ "${deploy}" -eq 1 ]; then
  if [ "${deploy_hydra}" -eq 1 ]; then
    toplevel="$(realize_hydra "${machine}")"
  else
    toplevel="$(realize_ssh "${machine}")"
  fi
fi

read -sp "[sudo] password for ${USER}: " sudo_password
echo

if [ "${sync}" -eq 1 ]; then
  rsync -e "ssh -oControlPath=\"${ssh_control_path}\"" --rsync-path="echo \"${sudo_password}\" | sudo -Sv 2>/dev/null; sudo rsync" -rlpt --delete "${nixos_root}/" "${machine}:/etc/nixos"
fi

if [ "${deploy}" -eq 1 ]; then
  activate "${machine}" "${toplevel}"
fi

