# Automatically applied settings when ZFS is enabled
{ config, lib, pkgs, ... }: with lib; mkIf (any (fs: fs == "zfs") config.boot.supportedFilesystems) (mkMerge [
  ({
    # Use a supported kernel version
    # Lower priority than mkForce to allow devices to use custom kernels
    boot.kernelPackages = mkOverride 75 pkgs.linuxPackages;
  })
  (mkIf config.virtualisation.docker.enable {
    virtualisation.docker.storageDriver = "zfs";
    # Fix container removal (https://github.com/moby/moby/issues/24403#issuecomment-272491117)
    systemd.services.docker.serviceConfig.MountFlags = "slave";
  })
])

