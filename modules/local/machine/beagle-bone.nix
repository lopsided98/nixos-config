# This module does not have an enable option because the sd-image module does
# not either and there is no way to do conditional imports. Any machine that
# uses this configuration must manually include it.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.machine.beagleBone;
in {
  # FIXME: find a way to import this from nixpkgs with flakes
  imports = singleton ./sd-image.nix;

  options.local.machine.beagleBone = {
  };

  config = {
    sdImage = {
      imageBaseName = "${config.networking.hostName}-sd-image";
      firmwareSize = 16; # MiB

      populateFirmwareCommands = ''
        cp '${pkgs.ubootAmx335xEVM}'/{MLO,u-boot.img} firmware
      '';
      populateRootCommands = ''
        mkdir -p ./files/boot
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c '${config.system.build.toplevel}' -d ./files/boot
      '';
    };

    boot = {
      loader = {
        grub.enable = false;
        generic-extlinux-compatible.enable = true;
      };
      kernelParams = [
        "earlycon" # Enable early serial console
      ];
    };

    fileSystems."/boot/firmware".options = [ "x-systemd.automount" ];

    # Enable SD card TRIM
    services.fstrim.enable = true;
  };
}
