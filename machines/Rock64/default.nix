# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, secrets, ... }: let
  interface = "eth0";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules
  ];

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  systemd.network = {
    enable = true;
    networks."30-${interface}" = {
      name = interface;
      address = [ "192.168.1.6/24" ];
      gateway = [ "192.168.1.1" ];
      dns = [ "192.168.1.2" "2601:18a:0:85e0:ba27:ebff:fe5e:6b6e" ];
      dhcpConfig.UseDNS = false;
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=no
      '';
    };
  };
  networking.hostName = "Rock64"; # Define your hostname.
  networking.hostId = "566a7fd8";

  # List services that you want to enable:

  # Set SSH port
  services.openssh.ports = [ 4246 ];

  # System metrics logging
  local.services.telegraf = {
    enable = true;
    influxdb = {
      tlsCertificate = ./telegraf/influxdb.pem;
      tlsKeySecret = secrets.Rock64.telegraf.influxdbTlsKey;
    };
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;
}
