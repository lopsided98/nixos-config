{ config, pkgs, lib, ... }: {
  boot = {
    # Enable ZFS support
    supportedFilesystems = [ "zfs" ];
    # Use a supported kernel version
    
    kernelPackages = lib.mkForce pkgs.linuxPackages_4_14;
  };

  virtualisation.docker.storageDriver = "zfs";
  # Fix container removal (https://github.com/moby/moby/issues/24403#issuecomment-272491117)
  systemd.services.docker.serviceConfig.MountFlags = "slave";
}
