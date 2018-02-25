{ config, pkgs, lib, ... }: {
  boot = {
    # Enable ZFS support
    supportedFilesystems = [ "zfs" ];
    # Use a supported kernel version
    
    # Uncomment when ZFS does not support the latest kernel
    # Lower priority than mkForce to allow devices to use custom kernels
    # kernelPackages = lib.mkOverride 100 pkgs.linuxPackages_latest;
  };

  virtualisation.docker.storageDriver = "zfs";
  # Fix container removal (https://github.com/moby/moby/issues/24403#issuecomment-272491117)
  systemd.services.docker.serviceConfig.MountFlags = "slave";
}
