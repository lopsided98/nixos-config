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

  sdImage = {
    firmwarePartitionID = "0xd6c62b6c";
    rootPartitionUUID = "880d38c2-5a88-47a0-8d9d-65a7a601c8ee";
    compressImage = false;
  };

  local.networking.home = {
    enable = true;
    interfaces = [ "eth0" ];
  };

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
    units = [ "sshd@.service" ];
    # Prevent first connection from failing due to decryption taking too long
    lazy = false;
    files = mkMerge [
      (secrets.mkSecret secrets.bone-black.ssh.hostRsaKey {})
      (secrets.mkSecret secrets.bone-black.ssh.hostEd25519Key {})
    ];
  };
}
