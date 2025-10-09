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

    # VFIO/PCI Passthrough
    kernelParams = [ "intel_iommu=on" ];
    # These modules must come before early modesetting
    kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" ];
    # Quadro K4000
    extraModprobeConfig = "options vfio-pci ids=10de:2486,10de:228b";

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

      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/0deb8a8e-13ea-4d58-aaa8-aaf444385843";
          crypttabExtraOpts = [ "tries=0" ];
        };
        root-metadata-1 = {
          device = "/dev/disk/by-uuid/0e4b0dca-3609-4fa9-8328-53184883454e";
          # Supposed to increase performance of SSDs
          bypassWorkqueues = true;
          allowDiscards = true;
          crypttabExtraOpts = [ "tries=0" ];
        };
        root-metadata-2 = {
          device = "/dev/disk/by-uuid/bab48222-f09d-400b-973f-021140721467";
          # Supposed to increase performance of SSDs
          bypassWorkqueues = true;
          allowDiscards = true;
          crypttabExtraOpts = [ "tries=0" ];
        };
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

  systemd.network = {
    enable = true;

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

  environment.systemPackages = with pkgs; [
    pciutils
    nvme-cli
  ];

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

  # Libvirt
  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown";
    qemu = {
      runAsRoot = false;
      swtpm.enable = true;
      ovmf.packages = [ pkgs.OVMFFull.fd ];
    };
    hooks.qemu.windows-11-isolate-cpus = "${pkgs.writeShellScript "windows-11-isolate-cpus.sh" ''
      object="$1"
      command="$2"

      if [ "$object" != "Windows-11"]; then
        exit 0
      fi

      if [ "$command" = "started" ]; then
          ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-3,8-11
          ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-3,8-11
          ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-3,8-11
      elif [ "$command" = "release" ]; then
          ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=
          ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=
          ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=
      fi
    ''}";
  };
  users.users.ben.extraGroups = [ "libvirtd" ];

  services.lvm = {
    dmeventd.enable = true;
    boot.thin.enable = true;
  };
  # Automatic extension of LVM thin pools
  environment.etc."lvm/lvm.conf".text = ''
     activation/thin_pool_autoextend_threshold = 90
  '';

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
}
