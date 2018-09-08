#!/bin/bash
set -eu

function cleanup {
  # Don't stop on failure of cleanup commands
  set +eu
  sleep 1
  umount "${mount_dir}"
  kpartx -d "${loopdev}"
  losetup -d "${loopdev}"
  rmdir "${mount_dir}"
}
trap cleanup EXIT

image="$1"
loop="${2:-loop0}"
loopdev="/dev/${loop}"

losetup "${loopdev}" "${image}"
kpartx -a "${loopdev}"

mount_dir=$(mktemp -d mount.XXXXXX)
mount "/dev/mapper/${loop}p2" "${mount_dir}"

read -rsp "Password: " key
echo

install -D -o root -g root -m 400 /dev/null "${mount_dir}/etc/secrets/key"
echo "${key}" > "${mount_dir}/etc/secrets/key"

