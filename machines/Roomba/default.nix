# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, secrets, ... }: {
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  local.machine.raspberryPi.enableWirelessFirmware = true;

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

  local.networking = {
    wireless.home = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
    home = {
      enable = true;
      interfaces = [ "eth0" ];
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

  networking.firewall.allowedTCPPorts = [
    1935 # RTMP Streaming
  ];
}
