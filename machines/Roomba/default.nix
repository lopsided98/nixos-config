{ lib, config, pkgs, inputs, secrets, ... }:

with lib;

{
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  local.machine.raspberryPi = {
    enable = true;
    version = 3;
    firmwarePartitionUUID = "0980-DF14";
    enableWirelessFirmware = true;
  };

  sdImage.rootPartitionUUID = "b12d092c-fc79-4d6d-8879-0be220bc1ad2";

  boot = {
    loader.generic-extlinux-compatible.copyKernels = false;
    kernelPackages = mkForce pkgs.linuxPackages_5_15;
  };

  networking.hostName = "Roomba";

  local.networking = {
    wireless.home = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
    home.interfaces.enu1u1 = {};
  };
  systemd.network.wait-online.anyInterface = true;

  # List services that you want to enable:

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.Roomba.ssh.hostRsaKey; }
    { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.Roomba.ssh.hostEd25519Key; }
  ];

  # Save/restore time
  services.fakeHwClock.enable = true;

  # Enable SD card TRIM
  services.fstrim.enable = true;

  systemd.secrets = {
    sshd = {
      units = [ "sshd-secrets.service" ];
      files = mkMerge [
        (secrets.mkSecret secrets.Roomba.ssh.hostRsaKey {})
        (secrets.mkSecret secrets.Roomba.ssh.hostEd25519Key {})
      ];
    };
  };
}
