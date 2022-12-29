# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, secrets, ... }: let
  interface = "br0";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # Modules without configuration options
    ../../modules/config/openvpn/server.nix

    ../../modules
  ];

  # Enable cross-compilation
  local.system.buildSystem.system = "x86_64-linux";

  local.profiles.headless = true;
  # SpiderMonkey doesn't build on 32-bit (OOM)
  security.polkit.enable = false;

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        copyKernels = false;
      };
    };
  };

  local.networking.home.interfaces.${interface}.ipv4Address = "192.168.1.3/24";

  networking.hostName = "ODROID-XU4"; # Define your hostname.

  nix.settings.extra-platforms = "armv6l-linux";

  environment.systemPackages = with pkgs; [
    linuxPackages_latest.tmon
    tcpdump
  ];

  # List services that you want to enable:

  # Serial terminal
  systemd.services."getty@ttySAC2".enable = true;

  # Set SSH port
  services.openssh.ports = [4243];

  local.networking.vpn.home.wireGuard.server = {
    enable = true;
    uplinkInterface = interface;
    # Public key: k8hqq72n9/MqGpbnIriPwcSXHkZYGOh8xXFMw1zj3QE=
    privateKeySecret = secrets.ODROID-XU4.vpn.wireGuardPrivateKey;
  };

  # System metrics logging
  local.services.telegraf = {
    enable = true;
    influxdb = {
      tlsCertificate = ./telegraf/influxdb.pem;
      tlsKeySecret = secrets.ODROID-XU4.telegraf.influxdbTlsKey;
    };
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;
}
