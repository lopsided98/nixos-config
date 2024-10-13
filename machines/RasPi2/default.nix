{ lib, config, pkgs, secrets, ... }: let
  interface = "enu1u1";
in {
  imports = [
    ../../modules/local/machine/raspberry-pi.nix

    ../../modules/config/dnsupdate.nix
    ../../modules/config/dns.nix

    ../../modules
  ];

  # Enable cross-compilation
  local.system.buildSystem.system = "x86_64-linux";

  local.machine.raspberryPi = {
    enable = true;
    version = 2;
    firmwarePartitionUUID = "C99F-2756";
  };

  local.profiles.headless = true;

  sdImage = {
    rootPartitionUUID = "7292e6e2-4528-4a9a-aed4-1918605dde1f";
    compressImage = false;
  };

  systemd.network = {
    enable = true;
    networks."30-${interface}" = {
      name = interface;
      address = [ "192.168.1.2/24" ];
      gateway = [ "192.168.1.1" ];
      dns = [ "127.0.0.1" "::1" ];
      dhcpV4Config.UseDNS = false;
      dhcpV6Config.UseDNS = false;
      ipv6AcceptRAConfig.UseDNS = false;
    };
  };
  networking.hostName = "RasPi2"; # Define your hostname.

  # List services that you want to enable:

  services.openssh = {
    ports = [ 4242 ];
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.RasPi2.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.RasPi2.ssh.hostEd25519Key; }
    ];
  };

  # System metrics logging
  local.services.telegraf = {
    enable = true;
    influxdb = {
      tlsCertificate = ./telegraf/influxdb.pem;
      tlsKeySecret = secrets.RasPi2.telegraf.influxdbTlsKey;
    };
  };

  # Network monitoring
  services.telegraf.extraConfig.inputs.ping = {
    urls = [
      "www.google.com"
      "192.168.1.1"
      "odroid-xu4.benwolsieffer.com"
      "hp-z420.benwolsieffer.com"
      "p-3400.benwolsieffer.com"
      "rock64.benwolsieffer.com"
      "rockpro64.benwolsieffer.com"
    ];

    # The only metric used in the dashboard
    fieldpass = [ "average_response_ms" ];
  };
  systemd.services.telegraf.path = [ pkgs.iputils /* ping */ ];

  # Quassel core (IRC)
  /*services.quassel = {
    enable = true;
    portNumber = 4600;
    interfaces = [ "0.0.0.0" ];
    dataDir = "/var/lib/quassel";
  };*/

  # Enable SD card TRIM
  services.fstrim.enable = true;

  /*networking.firewall.allowedTCPPorts = [
    4600 # Quassel
  ];*/

  systemd.secrets.sshd = {
    units = [ "sshd@.service" ];
    # Prevent first connection from failing due to decryption taking too long
    lazy = false;
    files = lib.mkMerge [
      (secrets.mkSecret secrets.RasPi2.ssh.hostRsaKey {})
      (secrets.mkSecret secrets.RasPi2.ssh.hostEd25519Key {})
    ];
  };
}
