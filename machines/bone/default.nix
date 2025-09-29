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
    firmwarePartitionUUID = "CE10-2799";
    enableWirelessCape = true;
  };

  sdImage = {
    rootPartitionUUID = "de4bdabd-5b30-4339-9168-14fbd944184f";
    compressImage = false;
  };

  local.networking = {
    wireless.home = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
    home.interfaces.eth0 = {};
  };
  systemd.network.wait-online.anyInterface = true;

  networking.hostName = "bone";

  # Services to enable

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.bone.ssh.hostRsaKey; }
    { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.bone.ssh.hostEd25519Key; }
  ];

  systemd.secrets.sshd = {
    units = [ "sshd.service" ];
    files = mkMerge [
      (secrets.mkSecret secrets.bone.ssh.hostRsaKey {})
      (secrets.mkSecret secrets.bone.ssh.hostEd25519Key {})
    ];
  };
}
