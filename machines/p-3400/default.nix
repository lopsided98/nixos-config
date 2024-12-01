{ lib, config, pkgs, secrets, ... }: {
  imports = [ ../../modules ];

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "ext4";
    };

    "/boot/efi" = {
      device = "/dev/disk/by-uuid/7D38-19FE";
      fsType = "vfat";
      # Prevent unprivileged users from being able to read secrets in the initrd
      options = [ "fmask=0137" ];
    };
  };

  swapDevices = lib.singleton {
    device = "/var/lib/swap";
    size = 1024; # 1 GiB
  };

  boot = {
    # Use systemd-boot
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };

    kernelModules = [ "kvm-intel" ];
    kernelParams = [ "intel_iommu=on" ];

    initrd = {
      availableKernelModules = [
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
        # Ethernet
        "r8169"
      ];

      luks.devices.root = {
        device = "/dev/disk/by-uuid/9911ded5-61bf-4cda-9c79-faf743799d90";
        # Supposed to increase performance of SSDs
        bypassWorkqueues = true;
        allowDiscards = true;
        crypttabExtraOpts = [ "tries=0" ];
      };

      systemd.network.enable = true;

      network = {
        tinyssh = {
          port = lib.head config.services.openssh.ports;
          authorizedKeys = config.users.extraUsers.ben.openssh.authorizedKeys.keys;
          hostEd25519Key = {
            publicKey = "${./tinyssh/ed25519.pk}";
            privateKey = secrets.getBootSecret secrets.p-3400.tinyssh.hostEd25519Key;
          };
        };
        decryptssh.enable = true;
      };
    };
  };

  hardware.cpu.intel.updateMicrocode = true;

  local.networking.home.interfaces.enp2s0 = {
    ipv4Address = "192.168.1.4/24";
    initrd = true;
  };

  networking = {
    hostName = "p-3400";
    hostId = "9035d933";
  };

  # System metrics logging
  local.services.telegraf = {
    # Constantly wakes the system up. Still testing, so don't remove the config
    # yet.
    enable = false;
    influxdb = {
      tlsCertificate = ./telegraf/influxdb.pem;
      tlsKeySecret = secrets.p-3400.telegraf.influxdbTlsKey;
    };
  };

  # List services that you want to enable:

  services.openssh = {
    ports = [ 4244 ];
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.p-3400.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.p-3400.ssh.hostEd25519Key; }
    ];
  };

  # Suspend system when idle
  services.logind.extraConfig = ''
    IdleAction=suspend
    IdleActionSec=10
  '';

  # Wake up on unicast packets
  systemd.network.links."30-ethernet-wol" = {
    matchConfig.MACAddress = "44:8a:5b:ce:23:c6";
    linkConfig = {
      # Need to duplicate settings from 99-default.link, because multiple
      # matching files are not merged.
      NamePolicy = "keep kernel database onboard slot path";
      AlternativeNamesPolicy = "database onboard slot path";
      MACAddressPolicy = "persistent";

      WakeOnLan = "unicast";
    };
  };

  # Enable SSD TRIM
  services.fstrim.enable = true;

  boot.secrets = secrets.mkSecret secrets.p-3400.tinyssh.hostEd25519Key {};
  systemd.secrets.sshd = {
    units = [ "sshd@.service" ];
    # Prevent first connection from failing due to decryption taking too long
    lazy = false;
    files = lib.mkMerge [
      (secrets.mkSecret secrets.p-3400.ssh.hostRsaKey {})
      (secrets.mkSecret secrets.p-3400.ssh.hostEd25519Key {})
    ];
  };
}
