# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/common.nix
      ../../modules/ssh.nix
    ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelPackages = lib.mkForce pkgs.linuxPackages_rpi;
  };

  systemd.network = {
    enable = true;
    networks.eth0 = {
      name = "eth0";
      DHCP = "v4";
      dhcpConfig.UseDNS = false;
      dns = ["192.168.1.2"];
    };
  };
  networking.hostName = "KittyCop"; # Define your hostname.

  # Use correct binary cache
  nix.binaryCaches = lib.mkForce [ "http://nixos-arm.dezgeg.me/channel" ];
  nix.binaryCachePublicKeys = [ "nixos-arm.dezgeg.me-1:xBaUKS3n17BZPKeyxL4JfbTqECsT+ysbDJz29kLFRW0=%" ];
  
  # List services that you want to enable:

  # Set SSH port
  services.openssh.ports = [4246];
  
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };
  
  # Enable SD card TRIM
  services.fstrim.enable = true;
}
