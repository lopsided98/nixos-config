{ lib, config, pkgs, secrets, ... }: let
  interface = "end0";
in {
  imports = [ ../../modules ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/4ce7c327-458a-4e09-a316-995bce9087b9";
    fsType = "ext4";
  };

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  local.networking.home.interfaces.${interface}.ipv4Address = "192.168.1.6/24";

  networking = {
    hostName = "Rock64";
    hostId = "566a7fd8";
  };

  # List services that you want to enable:

  nix.settings.cores = 4;

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
