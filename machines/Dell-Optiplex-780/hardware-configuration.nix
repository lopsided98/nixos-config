# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "root/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "root/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/0615d7a2-db24-4798-977c-f32b933690c2";
      fsType = "ext4";
    };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 2;
}
