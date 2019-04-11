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
  };

  systemd.network = {
    enable = true;
    networks."30-${interface}" = {
      name = interface;
      address = [ "192.168.1.2/24" ];
      gateway = [ "192.168.1.1" ];
      dns = [ "127.0.0.1" "::1" ];
      dhcpConfig.UseDNS = false;
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=no
      '';
    };
  };
  networking.hostName = "RasPi2"; # Define your hostname.

  # List services that you want to enable:

  # Set SSH port
  services.openssh.ports = [ 4242 ];

  # Network monitoring
  services.telegraf.inputs.ping = {
    urls = [
      "www.google.com"
      "192.168.1.1"
      "odroid-xu4.benwolsieffer.com"
      "hp-z420.benwolsieffer.com"
      "dell-optiplex-780.benwolsieffer.com"
      "rock64.benwolsieffer.com"
      "rockpro64.benwolsieffer.com"
    ];

    # The only metric used in the dashboard
    fieldpass = [ "average_response_ms" ];
  };
  # We need the privileged ping executable in the path (is there a better way
  # to do this?)
  systemd.services.telegraf.path = [ "/run/wrappers" ];

  # Quassel core (IRC)
  services.quassel = {
    enable = true;
    portNumber = 4600;
    interfaces = [ "0.0.0.0" ];
    dataDir = "/var/lib/quassel";
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;

  networking.firewall.allowedTCPPorts = [
    4600 # Quassel
  ];
}
