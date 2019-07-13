# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }: let
  interface = "eth0";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../modules/config/telegraf.nix

    ../../modules
  ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelPackages = lib.mkForce pkgs.crossPackages.linuxPackages_rock64_5_2;
  };

  systemd.network = {
    enable = true;
    networks."30-${interface}" = {
      name = interface;
      address = [ "192.168.1.7/24" ];
      gateway = [ "192.168.1.1" ];
      dns = [ "192.168.1.2" "2601:18a:0:7723:ba27:ebff:fe5e:6b6e" ];
      dhcpConfig.UseDNS = false;
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=no
      '';
    };
  };
  networking = {
    hostName = "RockPro64";
    hostId = "67b35626";
  };

  environment.systemPackages = with pkgs; [
  ];

  # List services that you want to enable:

  # Use the same speed as the bootloader/early console
  services.mingetty.serialSpeed = [ 1500000 ];

  # Set SSH port
  services.openssh.ports = [4247];

  # Enable SD card TRIM
  services.fstrim.enable = true;
}
