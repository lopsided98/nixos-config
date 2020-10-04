#!/bin/sh

machine="${1}"

mkdir -p "${machine}"
ssh-keygen -f "${machine}/ssh_host_rsa_key" -N '' -C "${machine}" -t rsa -b 4096
ssh-keygen -f "${machine}/ssh_host_ed25519_key" -N '' -C "${machine}" -t ed25519
rm "${machine}"/*.pub
