{ lib, config, pkgs, secrets, ... }:
with lib;
let
  address = "192.168.1.9";
  interface = "enp1s0";
in {
  imports = [ ../../modules ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/37fe0a4a-bb66-4163-9ed5-48528d72b73b";
      fsType = "ext4";
      # Prevent timeout while waiting for decryption password
      options = [ "x-systemd.device-timeout=0" ];
    };

    "/boot/efi" = {
      device = "/dev/disk/by-uuid/5801-5386";
      fsType = "vfat";
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };

    initrd = {
      availableKernelModules = [
        # USB
        "xhci_pci"
        "usb_storage"
        "usbhid"
        # Keyboard
        "hid_generic"
        # eMMC
        "sd_mod"
        "sdhci_acpi"
        "mmc_block"
        # Ethernet
        "r8169"
      ];

      luks.devices.root = {
        device = "/dev/disk/by-uuid/b70eef17-f299-4f20-857f-1c04c5d316df";
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
            privateKey = secrets.getBootSecret secrets.atomic-pi.tinyssh.hostEd25519Key;
          };
        };
        decryptssh.enable = true;
      };
    };
  };

  hardware.cpu.intel.updateMicrocode = true;

  local.networking.home.interfaces.${interface} = {
    ipv4Address = "${address}/24";
    initrd = true;
  };

  networking.hostName = "atomic-pi";

  # List services that you want to enable:

  # Radon sensor logging
  local.services.radonpy.enable = true;

  # Power usage logging
  local.services.rtlamr.enable = true;
  boot.blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];

  # Fitbit synchronization
  services.freefb = {
    enable = true;
    link = "ble";
    dump = true;
    configFile = secrets.getSystemdSecret "freefb" secrets.freefb.configFile;
  };

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.atomic-pi.ssh.hostRsaKey; }
    { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.atomic-pi.ssh.hostEd25519Key; }
  ];

  # Enable eMMC TRIM
  services.fstrim.enable = true;

  boot.secrets = secrets.mkSecret secrets.atomic-pi.tinyssh.hostEd25519Key { };
  systemd.secrets = {
    freefb = {
      units = [ "freefb.service" ];
      files = secrets.mkSecret secrets.freefb.configFile {};
    };
    sshd = {
      units = [ "sshd@.service" ];
      # Prevent first connection from failing due to decryption taking too long
      lazy = false;
      files = mkMerge [
        (secrets.mkSecret secrets.atomic-pi.ssh.hostRsaKey {})
        (secrets.mkSecret secrets.atomic-pi.ssh.hostEd25519Key {})
      ];
    };
  };
}
