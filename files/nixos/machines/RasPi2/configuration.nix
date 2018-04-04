# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }: let
  interface = "eth0";
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ../../modules/config/telegraf.nix
      ../../modules/config/dnsupdate.nix
      ../../modules/config/dns.nix

      ../../modules
    ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  };

  systemd.network = {
    enable = true;
    networks."${interface}" = {
      name = interface;
      address = [ "192.168.1.2/24" ];
      gateway = [ "192.168.1.1" ];
      dns = [ "127.0.0.1" "::1" ];
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=no
      '';
    };
  };
  networking.hostName = "RasPi2"; # Define your hostname.

  # Use ARM binary cache
  # Currently broken
  # nix.binaryCaches = [ "http://nixos-arm.dezgeg.me/channel" ];
  nix.binaryCachePublicKeys = [ "nixos-arm.dezgeg.me-1:xBaUKS3n17BZPKeyxL4JfbTqECsT+ysbDJz29kLFRW0=%" ];

  # List services that you want to enable:

  # Set SSH port
  services.openssh.ports = [4242];

  networking.firewall.allowedTCPPorts = [ 8883 ];

  # Network monitoring
  services.telegraf-fixed.inputs.ping = {
    urls = [
      "www.google.com"
      "192.168.1.1"
      "odroid-xu4.benwolsieffer.com"
      "hp-z420.benwolsieffer.com"
      "dell-optiplex-780.benwolsieffer.com"
      "rock64.benwolsieffer.com"
    ];

    # The only metric used in the dashboard
    fieldpass = [ "average_response_ms" ];
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;
}
