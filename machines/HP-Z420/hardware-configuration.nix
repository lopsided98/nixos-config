# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules = [
    # USB
    "ehci_pci"
    "xhci_pci"
    "usb_storage"
    "usbhid"
    # Keyboard
    "hid_generic"
    # Disks
    "ahci"
    "sd_mod"
    "sr_mod"
    # SSD
    "isci"
    # Ethernet
    "e1000e"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems = {
    "/" = {
      device = "root/root";
      fsType = "zfs";
    };

    "/var/lib/docker" = {
      device = "root/root/docker";
      fsType = "zfs";
    };

    "/home" = {
      device = "root/home";
      fsType = "zfs";
    };

    "/mnt/ssd" = {
      device = "/dev/disk/by-uuid/85ed6ea7-de86-4fbd-9dfb-f2f7d83e1539";
      fsType = "ext4";
    };

    "/tmp" = {
      device = "/mnt/ssd/tmp";
      options = [ "bind" ];
    };

    "/boot/esp" = {
      device = "/dev/disk/by-uuid/BAA5-3E52";
      fsType = "vfat";
      # Prevent unprivileged users from being able to read secrets in the initrd
      options = [ "fmask=0137" ];
    };
  };

  nix.maxJobs = lib.mkDefault 8;
  nix.buildCores = lib.mkDefault 8;
}
