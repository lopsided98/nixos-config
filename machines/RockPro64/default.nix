{ lib, config, pkgs, secrets, ... }:

with lib;

let
  interface = "eth0";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../modules/config/telegraf.nix

    ../../modules
  ];

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  local.networking.wireless.home = {
    enable = true;
    interface = "wlan0";
  };

  systemd.network = {
    enable = true;
    networks = {
      "30-${interface}" = {
        name = interface;
        address = [ "192.168.1.7/24" ];
        gateway = [ "192.168.1.1" ];
        dns = [ "192.168.1.2" "2601:18a:0:ff60:ba27:ebff:fe5e:6b6e" ];
        dhcpConfig.UseDNS = false;
        extraConfig = ''
          [IPv6AcceptRA]
          UseDNS=no
        '';
      };
    };
  };
  networking = {
    hostName = "RockPro64";
    hostId = "67b35626";
  };

  hardware = {
    bluetooth.enable = true;
    firmware = [ (pkgs.runCommand "bcm4359-firwmare" {} ''
      mkdir -p "$out/lib/firmware/brcm"
      cd "$out/lib/firmware/brcm"
      ln -s '${pkgs.fetchurl {
        url = "https://github.com/armbian/firmware/raw/78a566d50b7f82bfe77b32c172ce0dfee8642dea/brcm/brcmfmac4359-sdio.bin";
        sha256 = "1h1axlwlyvnzvds6wqh460q9jagy8cipcx58kn88bnb9p306jib9";
      }}' brcmfmac4359-sdio.bin
      ln -s '${pkgs.fetchurl {
        url = "https://github.com/armbian/firmware/raw/78a566d50b7f82bfe77b32c172ce0dfee8642dea/brcm/brcmfmac4359-sdio.txt";
        sha256 = "122c6rqjwfirdp602nv6vy63z683hpyy47p2vawxnhydzq2qbk2s";
      }}' brcmfmac4359-sdio.txt
      ln -s '${pkgs.fetchurl {
        url = "https://github.com/reMarkable/brcmfmac-firmware/raw/04f5d06feadee32da803c54e36c2b85909142867/brcmfmac4359-sdio.clm_blob";
        sha256 = "10yxmhjq7jyhb8a0jslldfj5yabacgyg03xb4mvqv1fnskihi1f4";
      }}' brcmfmac4359-sdio.clm_blob
    '') ];
  };


  # List services that you want to enable:

  # Use the same speed as the bootloader/early console
  services.mingetty.serialSpeed = [ 1500000 ];

  services.openssh = {
    ports = [ 4247 ];
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSecret secrets.RockPro64.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSecret secrets.RockPro64.ssh.hostEd25519Key; }
    ];
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;

  environment.secrets = mkMerge [
    (secrets.mkSecret secrets.RockPro64.ssh.hostRsaKey {})
    (secrets.mkSecret secrets.RockPro64.ssh.hostEd25519Key {})
  ];
}
