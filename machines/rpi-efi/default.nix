{ lib, config, pkgs, secrets, ... }:

{
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  # Enable cross-compilation
  local.system.buildSystem.system = "x86_64-linux";

  local.profiles.minimal = true;

  nixpkgs.overlays = lib.singleton (final: prev: {
    ubootRaspberryPiZero = prev.ubootRaspberryPiZero.override ({
      extraConfig ? "", ...
    }: {
      extraConfig = extraConfig + ''
        CONFIG_CMD_BOOTEFI=y
        CONFIG_EFI_LOADER=y
      '';
    });
  });

  local.machine.raspberryPi = {
    enable = true;
    version = 0;
    firmwarePartitionUUID = "DA50-94ED";
    # Use the minimum amount of GPU memory
    firmwareSettings.globalSection.gpu_mem = 16;
    enableWirelessFirmware = true;
  };

  boot.loader = {
    generic-extlinux-compatible.enable = lib.mkForce false;
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
  };

  sdImage = {
    rootPartitionUUID = "09ed1787-7c85-453f-bc74-e408e13e7435";
    compressImage = false;
  };

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="US"
  '';

  services.udev.extraRules = ''
    # Disable power saving (causes network hangs every few seconds)
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan0", RUN+="${pkgs.iw}/bin/iw dev $name set power_save off"
  '';

  networking.hostName = "rpi-efi";

  local.networking.wireless.home = {
    enable = true;
    interfaces = [ "wlan0" ];
    enableWpa2Sha256 = false;
  };

  # Services to enable

  services.openssh = {
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.rpi-efi.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.rpi-efi.ssh.hostEd25519Key; }
    ];
  };

  systemd.secrets = {
    sshd = {
      units = [ "sshd@.service" ];
      # Prevent first connection from failing due to decryption taking too long
      lazy = false;
      files = lib.mkMerge [
        (secrets.mkSecret secrets.rpi-efi.ssh.hostRsaKey {})
        (secrets.mkSecret secrets.rpi-efi.ssh.hostEd25519Key {})
      ];
    };
  };
}
