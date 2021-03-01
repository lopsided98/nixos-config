{ lib, config, pkgs, secrets, ... }: with lib; let
  interface = "enp2s0";
  address = "192.168.1.4";
  gateway = "192.168.1.1";
in {
  imports = [ ../../modules ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/142198ba-ed5c-45e1-986b-f92646a53fd0";
      fsType = "ext4";
    };

    "/boot/esp" = {
      device = "/dev/disk/by-uuid/6B22-0731";
      fsType = "vfat";
      # Prevent unprivileged users from being able to read secrets in the initrd
      options = [ "fmask=0137" ];
    };
  };

  hardware.cpu.intel.updateMicrocode = true;

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
    
      luks.devices.root.device = "/dev/disk/by-uuid/2d7c8523-15a0-4922-a65f-fdd37d078a34";

      network = {
        enable = true;
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
    kernelParams = [ "ip=${address}::${gateway}:255.255.255.0::${interface}:none" "intel_iommu=on" ];
  };

  local.networking.home = {
    enable = true;
    interfaces = [ interface ];
    ipv4Address = "${address}/24";
  };

  networking = {
    hostName = "p-3400";
    hostId = "9035d933";
  };

  local.services.telegraf = {
    enable = true;
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

  boot.secrets = secrets.mkSecret secrets.p-3400.tinyssh.hostEd25519Key {};
  systemd.secrets.sshd = {
    units = [ "sshd@.service" ];
    # Prevent first connection from failing due to decryption taking too long
    lazy = false;
    files = mkMerge [
      (secrets.mkSecret secrets.p-3400.ssh.hostRsaKey {})
      (secrets.mkSecret secrets.p-3400.ssh.hostEd25519Key {})
    ];
  };
}
