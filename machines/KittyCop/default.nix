{ lib, config, pkgs, secrets, ... }:

{
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  local.profiles.minimal = true;

  sdImage = {
    firmwarePartitionID = "0xacf04aa2";
    rootPartitionUUID = "e3338fee-5e7b-4cc4-ab3a-6c8acaa4746e";
  };

  boot.loader.raspberryPi = {
    enable = true;
    version = 1;
    uboot.enable = true;
  };

  systemd.network = {
    enable = true;
    networks."30-eth0" = {
      DHCP = "ipv4";
    };
  };
  networking.hostName = "KittyCop"; # Define your hostname.

  # List services that you want to enable:

  # Set SSH port
  services.openssh.ports = [ 4247 ];

  services.tinyssh = {
    enable = true;
    ports = [ 4248 ];
  };

  networking.firewall.allowedTCPPorts = [
    4248 # TinySSH
  ];
}
