# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/974bb90b-5049-4846-bc6f-4d7950842b26";
      fsType = "ext4";
    };

  nix.maxJobs = lib.mkDefault 2;
  nix.buildCores = lib.mkDefault 4;
}
