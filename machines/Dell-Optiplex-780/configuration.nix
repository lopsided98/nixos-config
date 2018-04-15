# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, secrets, ... }:
let

interface = "eth0";
address = "192.168.1.4";
gateway = "192.168.1.1";

in rec {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/config/telegraf.nix
      ../../modules/config/zfs-backup.nix
      ../../modules/config/docker.nix
      
      ../../modules
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
          hostEd25519Key = secrets.getBootSecret secrets.Dell-Optiplex-780.tinyssh.hostKey;
        };
        decryptssh = {
          enable = true;
        };
      };
    };
    kernelParams = [
      "ip=${address}::${gateway}:255.255.255.0::${interface}:none"
      "console=ttyS0,115200n8" # Serial boot console
    ];
  };

  boot.secrets = secrets.mkSecret secrets.Dell-Optiplex-780.tinyssh.hostKey {};

  systemd.network = {
    enable = true;
    networks."${interface}" = {
      name = interface;
      address = [ "${address}/24" ];
      gateway = [ gateway ];
      dns = [ "192.168.1.2" "2601:18a:0:7829:ba27:ebff:fe5e:6b6e" ];
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=no
      '';
    };
  };
  networking.hostName = "Dell-Optiplex-780"; # Define your hostname.
  networking.hostId = "8e4fab4d";
  services.wakeonlan.interfaces = lib.singleton {
    interface = interface;
    method = "magicpacket";
  };
  
  # Enable telegraf metrics for this interface
  services.telegraf.inputs.net.interfaces = [ interface ];

  environment.systemPackages = with pkgs; [
  ];

  # List services that you want to enable:
  
  # Serial terminal
  systemd.services."serial-getty@ttyS0".enable = true;
  
  # Set SSH port
  services.openssh = {
    ports = [4244];
    gatewayPorts = "clientspecified";
  };

  services.sanoid = {
    datasets = {
      "root/root" = {
        useTemplate = [ "local" ];
      };
      "root/home" = {
        useTemplate = [ "local" ];
      };
    };
  };
  
  services.syncoid = let
    remote = "backup@rock64.benwolsieffer.com";
  in {
    defaultArguments = "--sshport 4246";
    commands = [ {
      source = "root/root";
      target = "${remote}:backup/backups/Dell-Optiplex-780/root";
    } {
      source = "root/home";
      target = "${remote}:backup/backups/Dell-Optiplex-780/home";
    } ];
  };
}
