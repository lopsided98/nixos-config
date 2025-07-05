{ lib, config, pkgs, secrets, ... }: with lib; {
  imports = [ ../../modules ];

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/5dd58fb9-dc7f-4b77-b14b-d53d370735a7";
      fsType = "ext4";
    };
  };

  swapDevices = lib.singleton {
    device = "/var/lib/swap";
    size = 4096; # 4 GiB
  };

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR benwolsieffer@gmail.com
        ARRAY /dev/md/root metadata=1.2 name=RockPro64:root UUID=6f5b44ce:973b3ca0:9fdb264d:c50f508b
      '';
    };

    initrd = {
      availableKernelModules = [
        # PCIe SATA
        "pcie_rockchip_host"
        "phy_rockchip_pcie"
      ];

      luks.devices.root = {
        device = "/dev/disk/by-uuid/1e3f4804-300d-490a-9241-fb986b993986";
        allowDiscards = true;
        keyFile = "/dev/disk/by-partuuid/95745259-1c1c-4633-8190-10cf1c1495eb";
        keyFileSize = 4096;
      };
    };
  };

  hardware.firmware = let
    libreElecFirmware = pkgs.fetchFromGitHub {
      owner = "LibreELEC";
      repo = "brcmfmac_sdio-firmware";
      rev = "afc477e807c407736cfaff6a6188d09197dfbceb";
      hash = "sha256-544zEHIBMKXtIAp7sSLolPChCIFQw+xVin1/Ki1MliI=";
    };
  in singleton (pkgs.runCommand "bcm4359-firmware" {} ''
    mkdir -p "$out/lib/firmware/brcm"
    cp '${libreElecFirmware}'/{BCM4359*.hcd,brcmfmac4359-sdio*}  "$out/lib/firmware/brcm"
  '');

  # Ethernet/WiFi
  local.networking = {
    home.interfaces.end0.ipv4Address = "192.168.1.7/24";
    wireless.home = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
  };
  systemd.network.wait-online.anyInterface = true;

  networking = {
    hostName = "RockPro64";
    hostId = "67b35626";
  };

  # List services that you want to enable:

  nix.settings.cores = 2;

  services.openssh = {
    ports = [ 4247 ];
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.RockPro64.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.RockPro64.ssh.hostEd25519Key; }
    ];
  };

  # Save/restore time
  services.fakeHwClock.enable = true;

  # System metrics logging
  local.services.telegraf = {
    enable = true;
    influxdb = {
      tlsCertificate = ./telegraf/influxdb.pem;
      tlsKeySecret = secrets.RockPro64.telegraf.influxdbTlsKey;
    };
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;

  nixpkgs.overlays = lib.singleton (final: prev: {
    qt6 = prev.qt6.overrideScope (qtFinal : qtPrev: {
      qtbase = qtPrev.qtbase.overrideAttrs ({
        buildInputs ? [],
        cmakeFlags ? [], ...
      }: {
        buildInputs = buildInputs ++ [
          pkgs.libgbm
        ];
      });
    });

    ffmpeg = prev.ffmpeg.overrideAttrs ({
      patches ? [], 
      buildInputs ? [],
      configureFlags ? [], ...
    }: {
      patches = patches ++ [
        # v4l2-request
        (pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/LibreELEC/LibreELEC.tv/6239a5f89647da5e286c478ca73a17c636bff273/packages/multimedia/ffmpeg/patches/v4l2-request/ffmpeg-001-v4l2-request.patch";
          hash = "sha256-YuPB74ktoMIkplGkqSdkqjH5CtcrorSh451FGwnN5WA=";
        })
        # v4l2-drmprime
        (pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/LibreELEC/LibreELEC.tv/6239a5f89647da5e286c478ca73a17c636bff273/packages/multimedia/ffmpeg/patches/v4l2-drmprime/ffmpeg-001-v4l2-drmprime.patch";
          hash = "sha256-MTtWEUAc1BckE3G9TCT4jEapAomKOER7Tl6392fflsw=";
        })
      ];

      buildInputs = buildInputs ++ [
        pkgs.udev
      ];

      configureFlags = configureFlags ++ [
        "--enable-v4l2-request"
      ];
    });
  });

  hardware.graphics.enable = true;
  users.users.ben.extraGroups = [ "input" "video" "render" ];

  environment.systemPackages = with pkgs; [
    #moonlight-qt
    moonlight-embedded
  ];

  systemd.secrets.sshd = {
    units = [ "sshd@.service" ];
    # Prevent first connection from failing due to decryption taking too long
    lazy = false;
    files = mkMerge [
      (secrets.mkSecret secrets.RockPro64.ssh.hostRsaKey {})
      (secrets.mkSecret secrets.RockPro64.ssh.hostEd25519Key {})
    ];
  };
}
