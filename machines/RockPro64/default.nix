{ lib, config, pkgs, secrets, ... }:

with lib;

let
  address = "192.168.1.7";
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
    # Disable 4-way handshake offloading, which appears to be broken
    extraModprobeConfig = ''
      options brcmfmac feature_disable=0x82000
    '';
  };

  hardware.firmware = let
    libreElecFirmware = pkgs.fetchFromGitHub {
      owner = "LibreELEC";
      repo = "brcmfmac_sdio-firmware";
      rev = "afc477e807c407736cfaff6a6188d09197dfbceb";
      hash = "sha256-544zEHIBMKXtIAp7sSLolPChCIFQw+xVin1/Ki1MliI=";
    };
  in singleton (pkgs.runCommandNoCC "bcm4359-firmware" {} ''
    mkdir -p "$out/lib/firmware/brcm"
    cp '${libreElecFirmware}'/{BCM4359*.hcd,brcmfmac4359-sdio*}  "$out/lib/firmware/brcm"
  '');

  local.networking = {
    wireless = {
      xfinitywifi = {
        enable = true;
        interfaces = [ "wlan0" ];
      };
      home = {
        enable = true;
        interfaces = [ "wlan0" ];
      };
    };
    vpn.home.tap.client = {
      enable = true;
      macAddress = "b2:5e:ef:50:6a:ff";
      certificate = ./vpn/home/client.crt;
      privateKeySecret = secrets.RockPro64.vpn.home.privateKey;
    };
  };
  systemd.network = {
    enable = true;
    networks = {
      # Use a different MAC address on physical interface, because the normal MAC
      # is used on the VPN in order to get consistent IPs.
      "30-eth0" = {
        name = "eth0";
        DHCP = "ipv4";
        linkConfig.MACAddress = "ba:4b:f9:9b:f1:88";
      };

      "50-vpn-home-tap-client" = {
        address = [ "${address}/24" ];
        extraConfig = ''
          [IPv6AcceptRA]
          UseDNS=false
        '';
      };
    };
    wait-online.anyInterface = true;
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
