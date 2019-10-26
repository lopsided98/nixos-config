# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, secrets, ... }: {
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  sdImage = {
    firmwarePartitionID = "0x0980df14";
    rootPartitionUUID = "b12d092c-fc79-4d6d-8879-0be220bc1ad2";
  };

  boot = {
    loader.raspberryPi = {
      enable = true;
      version = 3;
      firmwareConfig = ''
        dtoverlay=gpio-ir-tx,gpio_pin=22
        dtoverlay=pi3-disable-bt
      '';
    };
    kernelPackages = lib.mkForce pkgs.crossPackages.linuxPackages_rpi3;
  };

  hardware.enableRedistributableFirmware = true;

  networking.wireless.enable = true;

  systemd.network = {
    enable = true;
    networks = {
      "30-eth0" = {
        name = "eth0";
        DHCP = "v4";
        dhcpConfig.UseDNS = false;
        dns = [ "192.168.1.2" "2601:18a:0:ff60:ba27:ebff:fe5e:6b6e" ];
        linkConfig.RequiredForOnline = false;
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
  networking.hostName = "Roomba"; # Define your hostname.

  # List services that you want to enable:

  # Allow faac (non-redistributable) for AAC encoding
  nixpkgs.config.allowUnfree = true;

  services.kittyCam.enable = true;

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  sound.enable = true;

  # Enable SD card TRIM
  services.fstrim.enable = true;

  networking.firewall.allowedTCPPorts = [
    1935 # RTMP Streaming
  ];

  environment.secrets = secrets.mkSecret secrets.wpaSupplicant.homeNetwork {
    target = "wpa_supplicant.conf";
  };
}
