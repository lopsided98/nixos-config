# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, options, config, pkgs, secrets, ... }: let

interface = "br0";
address = "192.168.1.5";

rootPoolDeviceUnits = [ "dev-disk-by\\x2duuid-10787227399261399199.device" ];

in {
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

  fileSystems = {
    "/" = {
      device = "root/system/root";
      fsType = "zfs";
    };

    "/nix" = {
      device = "root/system/nix";
      fsType = "zfs";
    };

    "/var" = {
      device = "root/data/var";
      fsType = "zfs";
    };

    "/var/lib/docker" = {
      device = "root/local/docker";
      fsType = "zfs";
    };

    "/var/db/postgresql-17" = {
      device = "root/data/var/postgresql-17";
      fsType = "zfs";
    };

    "/home" = {
      device = "root/data/home";
      fsType = "zfs";
    };

    "/boot/esp" = {
      device = "/dev/disk/by-uuid/BAA5-3E52";
      fsType = "vfat";
      # Prevent unprivileged users from being able to read secrets in the initrd
      options = [ "fmask=0137" ];
    };
  };

  boot = {
    # Use systemd-boot
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/esp";
      };
    };

    kernelModules = [ "kvm-intel" ];
    kernelParams = [ "intel_iommu=on" ];

    initrd = {
      availableKernelModules = [
        # Mode setting
        "nouveau"
        # USB
        "ehci_pci"
        "xhci_pci"
        "usb_storage"
        "usbhid"
        # Keyboard
        "hid_generic"
        # Disks
        "ahci"
        "sd_mod"
        "sr_mod"
        # SSD
        "isci"
        # Ethernet
        "e1000e"
      ];

      luks.devices.root = {
        device = "/dev/disk/by-uuid/0deb8a8e-13ea-4d58-aaa8-aaf444385843";
        crypttabExtraOpts = [ "tries=0" ];
      };

      systemd = {
        network.enable = true;

        # Wait until disk is decrypted before trying to import
        services."zfs-import-root" = {
          wants = rootPoolDeviceUnits;
          after = rootPoolDeviceUnits;
        };
        # Disable device timeout
        units = lib.listToAttrs (map (device: {
          name = device;
          value.text = ''
            [Unit]
            JobTimeoutSec=infinity
          '';
        }) rootPoolDeviceUnits);
      };

      network = {
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

    tmp.useTmpfs = true;
  };

  hardware.cpu.intel.updateMicrocode = true;

  local.networking.home = {
    interfaces.${interface}.ipv4Address = "${address}/24";
    initrdInterfaces.eno1.ipv4Address = "${address}/24";
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
    workerPassFile = secrets.getSystemdSecret "aur-buildbot-worker" secrets.HP-Z420.aurBuildbot.password;
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

  boot.zfs = {
    extraPools = [ "backup" "backup2" ];
    requestEncryptionCredentials = false;
  };

  local.services.backup = {
    server = {
      enable = true;
      devices = [ "/dev/disk/by-id/ata-WDC_WD80EMZZ-11B4FB0_WD-CA0K7KNK" ];
    };
    sanoid.enable = true;
    syncthing = {
      virtualHost = "syncthing.hp-z420.benwolsieffer.com";
      backupMountpoint = "/mnt/backup/home";
      certificate = ./syncthing/cert.pem;
      certificateKeySecret = secrets.HP-Z420.syncthing.certificateKey;
      httpsCertificate = ./syncthing/https-cert.pem;
      httpsCertificateKeySecret = secrets.HP-Z420.syncthing.httpsCertificateKey;
    };
  };

  services.sanoid = {
    datasets = {
      "root/data" = {
        recursive = true;
        use_template = [ "data" ];
      };
      "root/system" = {
        recursive = true;
        use_template = [ "system" ];
      };

      # Prune all backups
      "backup" = {
        recursive = true;
        use_template = [ "backup" ];
      };
      # Prune system data more aggressively
      "backup/home/backups/HP-Z420/system" = {
        recursive = true;
        use_template = [ "backup-system" ];
      };

      # Snapshots of data
      "backup/home/data" = {
        recursive = true;
        autosnap = true;
      };

      # Snapshots of non-ZFS devices that backup to this node
      "backup/home/backups/Dell-Inspiron-15" = {
        recursive = true;
        autosnap = true;
      };
      "backup/home/backups/P-3400" = {
        recursive = true;
        autosnap = true;
      };
    };
  };

  services.syncoid = let
    remote = "backup@rockpro64.benwolsieffer.com";
  in {
    commonArgs = [ "--sshport" "4247" ];
    commands = {
      "root" = {
        target = "backup/home/backups/HP-Z420";
        recursive = true;
        extraArgs = [ "--skip-parent" ];
      };
      "backup/home" = {
        target = "backup2/home";
        recursive = true;
        sendOptions = "w";
        localTargetAllow = options.services.syncoid.localTargetAllow.default ++ [ "destroy" ];
        extraArgs = [ "--delete-target-snapshots" ];
      };
      /*"backup/backups/HP-Z420" = {
        target = "${remote}:backup/backups/HP-Z420";
        recursive = true;
        extraArgs = [ "--skip-parent" ];
      };
      "backup/backups/Dell-Inspiron-15-Windows" = {
        target = "${remote}:backup/backups/Dell-Inspiron-15-Windows";
        recursive = true;
      };*/
    };
  };

  networking.firewall.allowedTCPPorts = [
    8086 # InfluxDB
  ];

  # Enable SSD TRIM
  services.fstrim.enable = true;

  boot.secrets = secrets.mkSecret secrets.HP-Z420.tinyssh.hostEd25519Key {};

  systemd.secrets.aur-buildbot-worker = {
    units = [ "buildbot-worker.service" ];
    files = secrets.mkSecret secrets.HP-Z420.aurBuildbot.password { user = "aur-buildbot-worker"; };
  };
}
