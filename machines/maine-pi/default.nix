{ lib, config, pkgs, secrets, ... }:

with lib;

let
  extraFirmwareConfig = ''
    # Use the minimum amount of GPU memory
    gpu_mem=16
  '';
in {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>

    ../../modules
  ];

  sdImage = let
    configTxt = pkgs.writeText "config.txt" config.boot.loader.raspberryPi.firmwareConfig;
    raspberrypi-uboot-builder =
      import <nixpkgs/nixos/modules/system/boot/loader/raspberrypi/uboot-builder.nix> {
        version = 0;
        inherit pkgs configTxt;
      };
  in {
    firmwarePartitionID = "0x2a7208bc";
    rootPartitionUUID = "79cd7c77-b355-4d2b-b1d5-fa9207e944f2";

    imageBaseName = "${config.networking.hostName}-sd-image";

    populateFirmwareCommands = ''
      "${raspberrypi-uboot-builder}" -t 3 -c "${config.system.build.toplevel}" -d ./files/boot
    '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      "${raspberrypi-uboot-builder}" -t 3 -c "${config.system.build.toplevel}" -d ./files/boot
    '';
  };

  boot = {
    loader = {
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 0;
        firmwareConfig = extraFirmwareConfig;
        uboot.enable = true;
      };
    };
  };

  hardware = {
    bluetooth.enable = true;
    # Enable wifi firmware
    enableRedistributableFirmware = true;
  };

  networking.wireless = {
    enable = true;
    interfaces = [ "wlan0" ];
  };

  systemd.network = {
    enable = true;
    networks."30-wlan0" = {
      name = "wlan0";
      DHCP = "v4";
    };
    networks."50-openvpn-client-home-network".DHCP = "v4";
  };
  networking.hostName = "maine-pi";

  #environment.systemPackages = [ pkgs.rustc ];

  # Services to enable

  services.openssh = {
    ports = [ 4287 ];
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSecret secrets.maine-pi.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSecret secrets.maine-pi.ssh.hostEd25519Key; }
    ];
  };

  modules.openvpnClientHomeNetwork = {
    enable = true;
    certificate = ./openvpn/client.crt;
    privateKey = secrets.getSecret secrets.maine-pi.openvpn.privateKey;
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;
  
  environment.secrets = mkMerge [
    (secrets.mkSecret secrets.maine-pi.wpaSupplicantConf {
      target = "wpa_supplicant.conf";
    })
    (secrets.mkSecret secrets.maine-pi.openvpn.privateKey {})
    (secrets.mkSecret secrets.maine-pi.ssh.hostRsaKey {})
    (secrets.mkSecret secrets.maine-pi.ssh.hostEd25519Key {})
  ];
}
