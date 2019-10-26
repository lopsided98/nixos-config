# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, secrets, ... }: let
  interface = "eth0";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../modules/config/telegraf.nix

    ../../modules
  ];

  nixpkgs.localSystem = lib.systems.examples.aarch64-multiplatform // {
    platform = lib.systems.platforms.aarch64-multiplatform // {
      # Allow overlays to be applied to upstream device trees
      kernelMakeFlags = [ "DTC_FLAGS='-@'" ];
    };
  };

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelPackages = lib.mkForce pkgs.crossPackages.linuxPackages_rock64_5_3;
    kernelPatches = [
      {
        name = "brcmfmac-add-support-for-BCM4359-SDIO-chipset";
        patch = ./0001-brcmfmac-add-support-for-BCM4359-SDIO-chipset.patch;
      }
      {
        name = "brcmfac-reset-two-D11-cores-if-chip-has-two-D11-cores";
        patch = ./0002-brcmfmac-reset-two-D11-cores-if-chip-has-two-D11-cor.patch;
      }
    ];
  };

  # Disabled until BCM4359 works correctly
  # networking.wireless.enable = true;

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
      "30-wlan0" = {
        name = "wlan0";
        DHCP = "v4";
        dhcpConfig.UseDNS = false;
        dns = [ "192.168.1.2" "2601:18a:0:ff60:ba27:ebff:fe5e:6b6e" ];
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
    deviceTree = {
      enable = true;
      overlays = [ ./rockpro64-wifi-bt.dtbo ];
    };
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

  # Set SSH port
  services.openssh.ports = [ 4247 ];

  # Enable SD card TRIM
  services.fstrim.enable = true;

  environment.secrets = secrets.mkSecret secrets.wpaSupplicant.homeNetwork {
    target = "wpa_supplicant.conf";
  };
}
