# NixOS Configuration

## Packages, modules and configurations for my [NixOS](https://nixos.org) machines

The files in this repository are used to build all my NixOS machines, across
4 different architectures (armv6l, armv7l, aarch64, and x86_64). Everything
is built with my private Hydra instance, and each device has its own channel
(see [machines/default.nix](machines/default.nix)).

My [fork of nixpkgs](https://github.com/lopsided98/nixpkgs/tree/custom-unstable)
is required to build my machine configurations. Machines can be deployed
manually to test changes using the `deploy.sh` script.

Some interesting bits:
* [Machine specific channels](machines/default.nix)
* [A pragmatic way of handling secrets in the Nix store](https://github.com/lopsided98/nixos-secrets)
