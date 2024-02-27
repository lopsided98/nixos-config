# Automatically applied settings when ZFS is enabled
{ config, lib, pkgs, ... }: with lib; mkIf (config.boot.supportedFilesystems.zfs or false) (mkMerge [
  ({
    boot = {
      # Lower priority than mkForce to allow devices to use custom kernels
      kernelPackages = mkOverride 75 config.boot.zfs.package.latestCompatibleLinuxPackages;
      zfs = {
        # Recommended to be disabled to avoid potential corruption
        forceImportRoot = false;
        # Don't export kernel_neon_* symbols as GPL only
        # This is still WIP, so disable for now
        # removeLinuxDRM = true;
      };
    };
  })
  (mkIf config.virtualisation.docker.enable {
    virtualisation.docker.storageDriver = "zfs";
    # Fix container removal (https://github.com/moby/moby/issues/24403#issuecomment-272491117)
    systemd.services.docker.serviceConfig.MountFlags = "slave";
  })
])

