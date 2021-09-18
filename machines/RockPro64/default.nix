{ lib, config, pkgs, secrets, ... }:

with lib;

let
  interface = "eth0";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules
  ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelPackages = lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
  };

  systemd.network = {
    enable = true;
    networks = {
      "30-${interface}" = {
        name = interface;
        address = [ "192.168.1.7/24" ];
        gateway = [ "192.168.1.1" ];
        dns = [ "192.168.1.2" "2601:18a:0:85e0:ba27:ebff:fe5e:6b6e" ];
        dhcpConfig.UseDNS = false;
        extraConfig = ''
          [IPv6AcceptRA]
          UseDNS=no
        '';
      };
    };
  };
  networking = {
    hostName = "RockPro64";
    hostId = "67b35626";

    # Work around checksumming bug
    localCommands = ''
      ${pkgs.ethtool}/bin/ethtool -K eth0 rx off tx off
    '';
  };

  # List services that you want to enable:

  # Power usage logging
  local.services.rtlamr.enable = true;
  boot.blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];

  # Deluge torrent client
  local.services.deluge.enable = true;

  # Use the same speed as the bootloader/early console
  services.getty.serialSpeed = [ 1500000 ];

  services.openssh = {
    ports = [ 4247 ];
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSecret secrets.RockPro64.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSecret secrets.RockPro64.ssh.hostEd25519Key; }
    ];
  };

  # System metrics logging
  local.services.telegraf = {
    enable = true;
    influxdb = {
      tlsCertificate = ./telegraf/influxdb.pem;
      tlsKeySecret = secrets.RockPro64.telegraf.influxdbTlsKey;
    };
  };

  local.services.backup = {
    server = {
      enable = true;
      device = "/dev/disk/by-uuid/fea46c86-192a-40e4-a871-ae7f5d9b1840";
    };
    sanoid.enable = true;
    syncthing = {
      virtualHost = "syncthing.rockpro64.benwolsieffer.com";
      certificate = ./syncthing/cert.pem;
      certificateKeySecret = secrets.RockPro64.syncthing.certificateKey;
      httpsCertificate = ./syncthing/https-cert.pem;
      httpsCertificateKeySecret = secrets.RockPro64.syncthing.httpsCertificateKey;
    };
  };

  services.sanoid = {
    datasets = {
      # Each backup node takes its own snapshots of data
      "backup/data" = {
        use_template = [ "backup" ];
        autosnap = true;
        recursive = true;
        process_children_only = true;
      };
      # Prune all backups with one rule
      "backup/backups" = {
        use_template = [ "backup" ];
        recursive = true;
        process_children_only = true;
      };

      # Snapshots of non-ZFS devices that backup to this node
      "backup/backups/P-3400" = {
        use_template = [ "backup" ];
        autosnap = true;
        recursive = true;
      };
    };
  };

  services.syncoid = let
    remote = "backup@hp-z420.benwolsieffer.com";
  in {
    commonArgs = [ "--sshport" "4245" ];
    commands = {
      "backup/backups/Dell-Optiplex-780" = {
        target = "${remote}:backup/backups/Dell-Optiplex-780";
        recursive = true;
        extraArgs = [ "--skip-parent" ];
      };
      "backup/backups/P-3400" = {
        target = "${remote}:backup/backups/P-3400";
        recursive = true;
      };
    };
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;

  environment.secrets = mkMerge [
    (secrets.mkSecret secrets.RockPro64.ssh.hostRsaKey {})
    (secrets.mkSecret secrets.RockPro64.ssh.hostEd25519Key {})
  ];
}
