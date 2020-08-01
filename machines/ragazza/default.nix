{ lib, config, pkgs, secrets, ... }:

with lib;

{
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  local.machine.raspberryPi.enableWirelessFirmware = true;
  local.profiles.minimal = true;

  sdImage = {
    firmwarePartitionID = "0x4454ef4a";
    rootPartitionUUID = "26d7843f-5484-4504-9df0-3fd6b808a157";
  };

  boot = {
    loader.raspberryPi = {
      enable = true;
      version = 0;
      firmwareConfig = ''
        # Use the minimum amount of GPU memory
        gpu_mem=16
      '';
      uboot.enable = true;
    };
    kernelPackages = lib.mkForce pkgs.crossPackages.linuxPackages_rpi0;
  };
  hardware.deviceTree.name = "bcm2708-rpi-zero-w.dtb";

  local.networking.wireless.home = {
    enable = true;
    interface = "wlan0";
  };

  networking.hostName = "ragazza";

  # Services to enable

  services.openssh = {
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.ragazza.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.ragazza.ssh.hostEd25519Key; }
    ];
  };

  systemd.secrets.sshd = {
    units = [ "sshd@.service" ];
    files = mkMerge [
      (secrets.mkSecret secrets.ragazza.ssh.hostRsaKey {})
      (secrets.mkSecret secrets.ragazza.ssh.hostEd25519Key {})
    ];
  };
}
