{ lib, config, pkgs, secrets, ... }:
with lib;
let
  address = "192.168.1.9";
  gateway = "192.168.1.1";
  interface = "enp1s0";
in {
  imports = [ ../../modules ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/37fe0a4a-bb66-4163-9ed5-48528d72b73b";
      fsType = "ext4";
    };

    "/boot/efi" = {
      device = "/dev/disk/by-uuid/5801-5386";
      fsType = "vfat";
    };
  };

  boot = {
    loader = {
      grub.enable = false;
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
      };
      network = {
        enable = true;
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
    kernelParams = [ "ip=${address}::${gateway}:255.255.255.0::${interface}:none" ];
  };

  /*local.networking.vpn.home.tap.client = {
    enable = true;
    macAddress = "00:07:32:4d:3c:3d";
    certificate = ./vpn/home/client.crt;
    privateKey = secrets.getSecret secrets.atomic-pi.vpn.home.privateKey;
  };*/
  systemd.network = {
    enable = true;

    /*networks."50-vpn-home-tap-client" = {
      address = [ "${address}/24" ];
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=false
      '';
    };*/

    # Home network
    networks."50-${interface}" = {
      name = "${interface}";
      address = [ "${address}/24" ];
      gateway = [ gateway ];
      dns = [ "192.168.1.2" "2601:18a:0:ff60:ba27:ebff:fe5e:6b6e" ];
      dhcpConfig.UseDNS = false;
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=no
      '';
    };
  };
  networking.hostName = "atomic-pi";

  # List services that you want to enable:

  local.services.radonpy.enable = true;

  services.openssh = {
    ports = [ 4286 ];
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSecret secrets.atomic-pi.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSecret secrets.atomic-pi.ssh.hostEd25519Key; }
    ];
  };

  # Enable eMMC TRIM
  services.fstrim.enable = true;

  boot.secrets = secrets.mkSecret secrets.atomic-pi.tinyssh.hostEd25519Key { };
  environment.secrets = mkMerge [
    # (secrets.mkSecret secrets.atomic-pi.vpn.home.privateKey { })
    (secrets.mkSecret secrets.atomic-pi.ssh.hostRsaKey { })
    (secrets.mkSecret secrets.atomic-pi.ssh.hostEd25519Key { })
  ];
}
