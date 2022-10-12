# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, secrets, ... }:
let

interface = "br0";
address = "192.168.1.5";
gateway = "192.168.1.1";

in rec {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/config/docker.nix
    ../../modules/config/hydra.nix
    ../../modules/config/hacker-hats.nix
    ../../modules/config/aur-buildbot.nix
    ../../modules/config/influxdb
    ../../modules/config/grafana

    ../../modules
  ];

  boot = {
    # Use systemd-boot
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/esp";
      };
    };

    initrd = {
      luks.devices = {
        root.device = "/dev/disk/by-uuid/0deb8a8e-13ea-4d58-aaa8-aaf444385843";
        ssd = {
          device = "/dev/disk/by-uuid/aee09f7d-1d4b-42ea-8058-82272d3f8400";
          allowDiscards = true;
        };
      };

      network = {
        enable = true;
        tinyssh = {
          port = lib.head config.services.openssh.ports;
          authorizedKeys = config.users.extraUsers.ben.openssh.authorizedKeys.keys;
          hostEd25519Key = {
            publicKey = "${./tinyssh/ed25519.pk}";
            privateKey = secrets.getBootSecret secrets.HP-Z420.tinyssh.hostEd25519Key;
          };
        };
        decryptssh.enable = true;
      };
    };
    # "ip=:::::eno1:dhcp"
    kernelParams = [ "ip=${address}::${gateway}:255.255.255.0::eno1:none" "intel_iommu=on" ];
  };

  hardware.cpu.intel.updateMicrocode = true;

  local.networking.home = {
    enable = true;
    interfaces = [ interface ];
    ipv4Address = "${address}/24";
  };

  # local.networking.vpn.dartmouth.enable = true;

  /*local.networking.vpn.home.tap.client = {
    enable = true;
    macAddress = "a0:d3:c1:20:da:3f";
    certificate = ./vpn/home/client.crt;
    privateKeySecret = secrets.HP-Z420.vpn.home.privateKey;
  };*/
  systemd.network = {
    enable = true;

    # Dartmouth network
    /*networks."50-${interface}" = {
      name = interface;
      DHCP = "ipv4";
    };

    networks."50-vpn-home-tap-client" = {
      address = [ "${address}/24" ];
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=false
      '';
    };*/

    # Use physical interface MAC on bridge to get same IPs
    netdevs."50-${interface}".netdevConfig = {
      Name = interface;
      Kind = "bridge";
      MACAddress = "a0:d3:c1:20:da:3f";
    };

    # Attach the physical interface to the bridge
    #
    # Use a different MAC address on physical interface, because the normal MAC
    # is used on the VPN and bridge in order to get consistent IPs.
    networks."50-eno1" = {
      name = "eno1";
      networkConfig.Bridge = interface;
      linkConfig.MACAddress = "ea:d3:5b:d6:a0:6b";
    };
  };
  networking = {
    hostName = "HP-Z420"; # Define your hostname.
    hostId = "5e9c1aa3";
  };

  # System metrics logging
  local.services.telegraf = {
    enable = true;
    influxdb = {
      tlsCertificate = ./telegraf/influxdb.pem;
      tlsKeySecret = secrets.HP-Z420.telegraf.influxdbTlsKey;
    };
  };

  # List services that you want to enable:

  # Set SSH port
  services.openssh.ports = [ 4245 ];

  services.aur-buildbot-worker = {
    enable = true;
    workerPassFile = secrets.getSecret secrets.HP-Z420.aurBuildbot.password;
    masterHost = "hp-z420.benwolsieffer.com";
    adminMessage = "Ben Wolsieffer <benwolsieffer@gmail.com>";
  };

  # Web server for sharing publicly accessible files
  local.services.publicFiles.enable = true;

  /*modules.doorman = {
    enable = true;
    device = "/dev/doorman";
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="doorman"
  '';*/

  # Deluge torrent client
  local.services.deluge = {
    enable = true;
    downloadDir = "/var/lib/torrents";
  };

  local.services.backup = {
    server = {
      enable = true;
      device = "/dev/disk/by-uuid/fb800281-ab46-4fe1-be4d-4d4606915346";
    };
    sanoid.enable = true;
    syncthing = {
      virtualHost = "syncthing.hp-z420.benwolsieffer.com";
      certificate = ./syncthing/cert.pem;
      certificateKeySecret = secrets.HP-Z420.syncthing.certificateKey;
      httpsCertificate = ./syncthing/https-cert.pem;
      httpsCertificateKeySecret = secrets.HP-Z420.syncthing.httpsCertificateKey;
    };
  };

  services.sanoid = {
    datasets = {
      "root/data" = {
        use_template = [ "data" ];
        # Not allowed in template
        recursive = true;
      };
      "root/system" = {
        use_template = [ "system" ];
        # Not allowed in template
        recursive = true;
      };

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
      "backup/backups/Dell-Inspiron-15-Windows" = {
        use_template = [ "backup" ];
        autosnap = true;
        recursive = true;
      };
    };
  };

  services.syncoid = let
    remote = "backup@rockpro64.benwolsieffer.com";
  in {
    commonArgs = [ "--sshport" "4247" ];
    commands = {
      "root" = {
        target = "backup/backups/HP-Z420";
        recursive = true;
        extraArgs = [ "--skip-parent" ];
      };
      "backup/backups/HP-Z420" = {
        target = "${remote}:backup/backups/HP-Z420";
        recursive = true;
        extraArgs = [ "--skip-parent" ];
      };
      "backup/backups/Dell-Inspiron-15-Windows" = {
        target = "${remote}:backup/backups/Dell-Inspiron-15-Windows";
        recursive = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    8086 # InfluxDB
  ];

  # Enable SSD TRIM
  services.fstrim.enable = true;

  boot.secrets = secrets.mkSecret secrets.HP-Z420.tinyssh.hostEd25519Key {};
}
