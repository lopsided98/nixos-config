# This module does not have an enable option because the sd-image module does
# not either and there is no way to do conditional imports. Any machine that
# uses this configuration must manually include it.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.machine.raspberryPi;
  bootloaderCfg = config.boot.loader.raspberryPi;
  ubootEnabled = bootloaderCfg.uboot.enable;
in {
  # FIXME: find a way to import this from nixpkgs with flakes
  imports = singleton ./sd-image.nix;

  options.local.machine.raspberryPi = {
    enableWirelessFirmware = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the WiFi/Bluetooth firmware for the Raspberry Pi.
      '';
    };
  };

  config = {
    sdImage = let
      firmwareBuilder = pkgs.buildPackages.callPackage
        (pkgs.path + "/nixos/modules/system/boot/loader/raspberrypi/firmware-builder.nix") {
          inherit (bootloaderCfg) version;
          inherit ubootEnabled;
          # Override to use host packages where necessary
          inherit pkgs; # For U-Boot
          inherit (pkgs) raspberrypifw;
        };
      raspberryPiBuilder = pkgs.buildPackages.callPackage
        (pkgs.path + "/nixos/modules/system/boot/loader/raspberrypi/raspberrypi-builder.nix") { };

      configTxt = pkgs.writeText "config.txt" bootloaderCfg.firmwareConfig;
    in {
      imageBaseName = "${config.networking.hostName}-sd-image";

      firmwareSize = mkIf (!ubootEnabled) 200;

      populateFirmwareCommands = ''
        '${firmwareBuilder}' -d ./firmware -c '${configTxt}'
      '' + optionalString (!ubootEnabled) ''
        # This should probably be done by raspberrypi-builder.sh
        cp -r ${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays ./firmware
        '${raspberryPiBuilder}' -c '${config.system.build.toplevel}' -d ./firmware
      '';
      populateRootCommands = optionalString ubootEnabled ''
        mkdir -p ./files/boot
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c '${config.system.build.toplevel}' -d ./files/boot
      '';
    };

    boot.loader = {
      raspberryPi.firmwareDir = "/boot/firmware";
      grub.enable = false;
    };

    fileSystems."/boot/firmware".options = [ "x-systemd.automount" ];

    hardware.firmware = mkIf cfg.enableWirelessFirmware [ pkgs.raspberrypiWirelessFirmware ];

    # Enable SD card TRIM
    services.fstrim.enable = true;
  };
}
