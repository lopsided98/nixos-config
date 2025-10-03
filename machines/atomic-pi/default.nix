{ lib, config, pkgs, secrets, ... }:
with lib;
let
  address = "192.168.1.9";
  interface = "enp1s0";
in {
  imports = [ ../../modules ];

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "ext4";
    };

    "/boot/efi" = {
      device = "/dev/disk/by-uuid/CF34-3252";
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
        device = "/dev/disk/by-uuid/4e7ada7f-1ed8-43c0-92e5-e682cf384dc9";
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
    duidIdentifier = "59:2b:f1:e2:f2:d5:81:5c";
    initrd = true;
  };

  networking.hostName = "atomic-pi";

  # List services that you want to enable:

  # Radon sensor logging
  local.services.radonpy.enable = true;

  # Fitbit synchronization
  services.freefb = {
    enable = true;
    link = "ble";
    dump = true;
    configFile = secrets.getSystemdSecret "freefb" secrets.freefb.configFile;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    # Socket activation too slow for headless; start at boot instead.
    socketActivation = false;
    alsa.enable = true;
    pulse.enable = true;
  };
  systemd.user.services.wireplumber.wantedBy = [ "default.target" ];
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-vaapi-driver ];
  };
  users.users.ben.extraGroups = [ "audio" "input" "video" "render" ];

  environment.systemPackages = with pkgs; [
    moonlight-qt
    #moonlight-embedded
  ];

  local.networking.vpn.home.wireGuard.server = {
    enable = true;
    uplinkInterface = interface;
    # Public key: +6YE+L1kyBmvbQ4GKpw20g2vQv/58QujDHCCCIqzH14=
    privateKeySecret = secrets.atomic-pi.vpn.wireGuardPrivateKey;
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
      files = secrets.mkSecret secrets.freefb.configFile { user = "freefb"; };
    };
    sshd = {
      units = [ "sshd-keygen.service" ];
      files = mkMerge [
        (secrets.mkSecret secrets.atomic-pi.ssh.hostRsaKey {})
        (secrets.mkSecret secrets.atomic-pi.ssh.hostEd25519Key {})
      ];
    };
  };
}
