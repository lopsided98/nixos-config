#!@runtimeShell@
set -euo pipefail

export PATH="@path@"

nixos_root="@nixosRoot@"
secrets_root="@secretsRoot@"
ssh_control_path="~/.ssh/master-%r@%h:%p.sock"

usage() {
  echo "$0 [-nps] <machine>"
}

machine_toplevel_link() { echo "${1}.system"; }

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
  toplevel_drv=$(nix eval --raw --show-trace \
    "${nixos_root}#nixosConfigurations.${machine}.config.system.build.toplevel.drvPath") || return 1

  # Copy instantiated (but not realized config) to machine
  nix copy --derivation --to "ssh://${machine}" "${toplevel_drv}" 1>&2

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
    "https://hydra.benwolsieffer.com/job/localpkgs/release/machines.${machine}/latest" \
    | jq -r .buildoutputs.out.path)" || return 1

  machine_ssh "${machine}" nix-store --realize "${toplevel}" \
    --add-root "$(machine_toplevel_link "${machine}")" --indirect >/dev/null

  echo "${toplevel}"
}

realize_builder() {
  local machine="${1}"

  # Instantiate configuration on local machine.
  toplevel_drv="$(nix eval --raw --show-trace \
    "${nixos_root}#nixosConfigurations.${machine}.config.system.build.toplevel.drvPath")" || return 1

  # Copy instantiated (but not realized) config to builder
  nix copy --derivation --to "ssh://HP-Z420" "${toplevel_drv}" 1>&2

  # Build on builder
  toplevel="$(machine_ssh HP-Z420 nix-store --realize "${toplevel_drv}")"

  machine_ssh "${machine}" nix-store --realize "${toplevel}" \
    --add-root "$(machine_toplevel_link "${machine}")" --indirect >/dev/null

  echo "${toplevel}"
}

activate() {
  local machine="${1}"
  local toplevel="${2}"

  machine_ssh "${machine}" \
    sudo -Sv 2>/dev/null \&\& \
    sudo -n nix-env -p /nix/var/nix/profiles/system --set "${toplevel}" \&\& \
    sudo -n "${toplevel}/bin/switch-to-configuration" switch \
    <<< "${sudo_password}"
}

deploy=1
deploy_hydra=0
use_builder=0 # Whether to run builds locally
sync=0 # Whether to synchronize configuration to the machine

while getopts "npbs" opt; do
  case "$opt" in
    n) deploy=0; sync=1 ;;
    p) deploy_hydra=1 ;;
    b) use_builder=1 ;;
    s) sync=1 ;;
    \?) usage; exit ;;
  esac
done
shift "$(($OPTIND -1))"

nixos-secrets -c "${secrets_root}" check

machine="${1}"
shift

if [ "${deploy}" -eq 1 ]; then
  if [ "${deploy_hydra}" -eq 1 ]; then
    toplevel="$(realize_hydra "${machine}")"
  elif [ "${use_builder}" -eq 1 ]; then
    toplevel="$(realize_builder "${machine}")"
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

