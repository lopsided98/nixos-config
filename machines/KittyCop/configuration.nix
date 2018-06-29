# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ../../modules
    ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  systemd.network = {
    enable = true;
    networks.eth0 = {
      name = "eth0";
      DHCP = "v4";
      dhcpConfig.UseDNS = false;
      dns = [ "192.168.1.2" "2601:18a:0:7829:ba27:ebff:fe5e:6b6e" ];
    };
  };
  networking.hostName = "KittyCop"; # Define your hostname.

  # List services that you want to enable:

  # Set SSH port
  services.openssh.ports = [4247];

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
