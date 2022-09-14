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
    firmwarePartitionID = "0xce102799";
    rootPartitionUUID = "de4bdabd-5b30-4339-9168-14fbd944184f";
    compressImage = false;
  };

  local.machine.beagleBone.enableWirelessCape = true;

  local.networking.wireless = {
    home = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
    eduroam = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
  };

  networking.hostName = "bone";

  # Services to enable

  services.openssh = {
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.bone.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.bone.ssh.hostEd25519Key; }
    ];
  };

  systemd.secrets = {
    sshd = {
      units = [ "sshd@.service" ];
      # Prevent first connection from failing due to decryption taking too long
      lazy = false;
      files = mkMerge [
        (secrets.mkSecret secrets.bone.ssh.hostRsaKey {})
        (secrets.mkSecret secrets.bone.ssh.hostEd25519Key {})
      ];
    };
  };
}
