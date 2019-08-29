# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }: let
  interface = "eth0";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../modules/config/zfs-backup.nix
    ../../modules/config/telegraf.nix

    ../../modules
  ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelParams = [ "earlycon=uart8250,mmio32,0xff130000 coherent_pool=1M ethaddr=\${ethaddr} eth1addr=\${eth1addr} serial=\${serial#}" ];
    kernelPackages = lib.mkForce pkgs.crossPackages.linuxPackages_rock64_4_19;
  };

  systemd.network = {
    enable = true;
    networks."30-${interface}" = {
      name = interface;
      address = [ "192.168.1.6/24" ];
      gateway = [ "192.168.1.1" ];
      dns = [ "192.168.1.2" "2601:18a:0:7723:ba27:ebff:fe5e:6b6e" ];
      dhcpConfig.UseDNS = false;
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=no
      '';
    };
  };
  networking.hostName = "Rock64"; # Define your hostname.
  networking.hostId = "566a7fd8";

  environment.systemPackages = with pkgs; [
  ];

  # List services that you want to enable:

  # Use the same speed as the bootloader/early console
  services.mingetty.serialSpeed = [ 1500000 ];

  # Set SSH port
  services.openssh.ports = [4246];

  services.sanoid = {
    datasets = {
      # Each backup node takes its own snapshots of data
      "backup/data" = {
        useTemplate = [ "backup" ];
        autosnap = true;
        recursive = true;
        processChildrenOnly = true;
      };
      # Prune all backups with one rule
      "backup/backups" = {
        useTemplate = [ "backup" ];
        recursive = true;
        processChildrenOnly = true;
      };

      # Snapshots of non-ZFS devices that backup to this node
      "backup/backups/P-3400" = {
        useTemplate = [ "backup" ];
        autosnap = true;
        recursive = true;
      };
    };
  };

  services.syncoid = let
    remote = "backup@hp-z420.benwolsieffer.com";
  in {
    defaultArguments = "--sshport 4245";
    commands = [ {
      source = "backup/backups/Dell-Optiplex-780";
      target = "${remote}:backup/backups/Dell-Optiplex-780";
      recursive = true;
    } {
      source = "backup/backups/P-3400";
      target = "${remote}:backup/backups/P-3400";
      recursive = true;
    } ];
  };

  modules.syncthingBackup = {
    enable = true;
    virtualHost = "syncthing.rock64.benwolsieffer.com";
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;
}
