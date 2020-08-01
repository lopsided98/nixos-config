#!/bin/bash
set -eu

function cleanup {
  # Don't stop on failure of cleanup commands
  set +eu
  sleep 1
  umount "${block_dev}"
  if [ -n "${loop_dev:-}" ]; then
    kpartx -d "${loop_dev}"
    losetup -d "${loop_dev}"
  fi
  rmdir "${mount_dir}"
}
trap cleanup EXIT

image="$1"
key="$2"
loop="${3:-loop0}"

if [ ! -e "${image}" ]; then
  echo "${image} does not exist"
  exit
fi

if [ -b "${image}" ]; then
  block_dev="${image}"
else
  loop_dev="/dev/${loop}"

  losetup "${loop_dev}" "${image}"
  kpartx -a "${loop_dev}"
  block_dev="/dev/mapper/${loop}p2"
fi
mount_dir=$(mktemp -d --tmpdir mount.XXXXXX)
mount "${block_dev}" "${mount_dir}"

install -D -o root -g root -m 400 "${key}" "${mount_dir}/etc/secrets/key.asc"
