# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:

rec {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/common.nix
      ../../modules/ssh.nix
      ../../modules/telegraf.nix
      ../../modules/system/boot/initrd-tinyssh.nix
      ../../modules/system/boot/initrd-decryptssh.nix
      ../../modules/zfs-backup.nix
    ];
  
  boot = {
    # Use the GRUB 2 boot loader.
    loader.grub = {
      enable = true;
      version = 2;
      # Define on which hard drive you want to install Grub.
      device = "/dev/disk/by-id/ata-WDC_WD2500AAKS-60L9A0_WD-WMAV21585765";
    };
    initrd = {
      availableKernelModules = [ "e1000e" ];
      luks.devices.root.device = "/dev/disk/by-uuid/3a1628e7-401f-4668-a605-d5d09854303a";
      network = {
        enable = true;
        tinyssh = {
          port = lib.head services.openssh.ports;
          authorizedKeys = config.users.extraUsers.ben.openssh.authorizedKeys.keys;
          hostEd25519Key = /var/tinyssh.key;
        };
        decryptssh = {
          enable = true;
        };
      };
    };
    kernelParams = [ "ip=192.168.1.4::192.168.1.1:255.255.255.0::eth0:none" ];
  };

  environment.systemPackages = with pkgs; [
  ];

  systemd.network = {
    enable = true;
    networks.eth0 = {
      name = "eth0";
      address = ["192.168.1.4/24"];
      gateway = ["192.168.1.1"];
      dns = ["192.168.1.2"];
    };
  };
  networking.hostName = "Dell-Optiplex-780"; # Define your hostname.
  networking.hostId = "8e4fab4d";
  # Enable telegraf metrics for this interface
  services.telegraf-fixed.extraConfig.inputs.net.interfaces = [ "eth0" ];

  # List services that you want to enable:
  
  # Set SSH port
  services.openssh.ports = [4244];
}
