{ lib, config, pkgs, secrets, ... }:

{
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  # Enable cross-compilation
  local.system.buildSystem.system = "x86_64-linux";

  local.machine.raspberryPi = {
    enable = true;
    version = 1;
    firmwarePartitionUUID = "ACF0-4AA2";
  };

  local.profiles.minimal = true;

  sdImage.rootPartitionUUID = "e3338fee-5e7b-4cc4-ab3a-6c8acaa4746e";

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
