{ config, pkgs, lib, ... }: {
  boot = {
    # Enable ZFS support
    supportedFilesystems = [ "zfs" ];
    # Use a supported kernel version
    kernelPackages = lib.mkForce pkgs.linuxPackages_4_13;
  };

  virtualisation.docker.storageDriver = "zfs";
}
