{ lib, config, pkgs, secrets, ... }:

with lib;

{
  imports = [
    ../../modules
    ../../modules/local/machine/beagle-bone
  ];

  # Enable cross-compilation
  local.system.buildSystem.system = "x86_64-linux";

  local.profiles.minimal = true;

  local.machine.beagleBone = {
    enable = true;
    firmwarePartitionUUID = "D6C6-2B6C";
  };

  sdImage = {
    rootPartitionUUID = "880d38c2-5a88-47a0-8d9d-65a7a601c8ee";
    compressImage = false;
  };

  local.networking.home.interfaces.eth0 = {};

  networking.hostName = "bone-black";

  # Services to enable

  services.openssh = {
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.bone-black.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.bone-black.ssh.hostEd25519Key; }
    ];
  };

  networking.firewall.allowedUDPPorts = [
    5353 # mDNS
  ];

  systemd.secrets.sshd = {
    units = [ "sshd.service" ];
    files = mkMerge [
      (secrets.mkSecret secrets.bone-black.ssh.hostRsaKey {})
      (secrets.mkSecret secrets.bone-black.ssh.hostEd25519Key {})
    ];
  };
}
