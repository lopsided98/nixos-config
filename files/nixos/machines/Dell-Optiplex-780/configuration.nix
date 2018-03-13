# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:
let

interface = "eth0";
address = "192.168.1.4";
gateway = "192.168.1.1";

in rec {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/common.nix
      ../../modules/telegraf.nix
      ../../modules/system/boot/initrd-tinyssh.nix
      ../../modules/system/boot/initrd-decryptssh.nix
      ../../modules/zfs-backup.nix
      ../../modules/services/continuous-integration/aur-buildbot/worker.nix
      ../../modules/docker.nix
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
          hostEd25519Key = ./tinyssh.id_ed25519;
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

  systemd.network = {
    enable = true;
    networks."${interface}" = {
      name = interface;
      address = [ "${address}/24" ];
      gateway = [ gateway ];
      dns = [ "192.168.1.2" "2601:18a:0:7829:a0ad:20ff:fe40:7a1c" ];
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
  services.telegraf-fixed.inputs.net.interfaces = [ interface ];

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
  
  # Quassel core (IRC)
  services.quassel = {
    enable = true;
    portNumber = 4600;
    interfaces = [ "0.0.0.0" ];
    dataDir = "/var/lib/quassel";
  };
  
  services.aur-buildbot-worker = {
    enable = true;
    workerPass = "VKK4scBAqYuRmtuDUXZDz0E65voAOaj31UIoLH7t";
    masterHost = "hp-z420.benwolsieffer.com";
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
    remote = "backup@hp-z420.benwolsieffer.com";
  in {
    defaultArguments = "--sshport 4245";
    commands = [ {
      source = "root/root";
      target = "backup/backups/Dell-Optiplex-780/root";
    } {
      source = "root/home";
      target = "backup/backups/Dell-Optiplex-780/home";
    } {
      source = "backup/backups/Dell-Optiplex-780";
      target = "${remote}:backup/backups/Dell-Optiplex-780";
      recursive = true;
    } ];
  };
  
  services.syncthing = {
    enable = true;
    user = "backup";
    group = "backup";
    openDefaultPorts = true;
    dataDir = "/mnt/backup/syncthing";
  };
  systemd.services.syncthing.unitConfig.RequiresMountsFor = "/mnt/backup";
  
  networking.firewall.allowedTCPPorts = [ 1313 4600 ];
  networking.firewall.allowedUDPPorts = [ 4600 ];
}
