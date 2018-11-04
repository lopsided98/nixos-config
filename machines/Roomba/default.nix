# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, secrets, ... }: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../modules
  ];

  boot = {
    loader = {
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 3;
        firmwareConfig = ''
          dtoverlay=lirc-rpi,gpio_out_pin=22
        '';
      };
    };
    kernelParams = [ "cma=32M" ];
    kernelPackages = lib.mkForce pkgs.crossPackages.linuxPackages_rpi;
    kernelPatches = [ {
      patch = ./0001-staging-vchiq_arm-fix-msgbufcount-in-VCHIQ_IOC_AWAIT.patch;
      name = "staging-vchiq_arm-fix-msgbufcount";
    } ];
    # Fix dropped webcam frames
    extraModprobeConfig = ''
      options uvcvideo nodrop=1 timeout=1000
    '';
  };

  hardware.enableRedistributableFirmware = true;

  networking.wireless.enable = true;

  systemd.network = {
    enable = true;
    networks = {
      "50-eth0" = {
        name = "eth0";
        DHCP = "v4";
        dhcpConfig.UseDNS = false;
        dns = [ "192.168.1.2" "2601:18a:0:7829:ba27:ebff:fe5e:6b6e" ];
        linkConfig.RequiredForOnline = false;
        extraConfig = ''
          [IPv6AcceptRA]
          UseDNS=no
        '';
      };
      "50-wlan0" = {
        name = "wlan0";
        DHCP = "v4";
        dhcpConfig.UseDNS = false;
        dns = [ "192.168.1.2" "2601:18a:0:7829:ba27:ebff:fe5e:6b6e" ];
        extraConfig = ''
          [IPv6AcceptRA]
          UseDNS=no
        '';
      };
    };
  };
  networking.hostName = "Roomba"; # Define your hostname.

  # List services that you want to enable:

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

  environment.secrets = secrets.mkSecret secrets.Roomba.wpaSupplicantConf {
    target = "wpa_supplicant.conf";
  };
}
