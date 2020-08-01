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
  imports = singleton <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>;

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
        <nixpkgs/nixos/modules/system/boot/loader/raspberrypi/firmware-builder.nix> {
          inherit (bootloaderCfg) version;
          inherit ubootEnabled;
          # Override to use host packages where necessary
          inherit pkgs; # For U-Boot
          inherit (pkgs) raspberrypifw;
        };
      raspberryPiBuilder = pkgs.buildPackages.callPackage
        <nixpkgs/nixos/modules/system/boot/loader/raspberrypi/raspberrypi-builder.nix> { };

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
        '${config.boot.loader.generic-extlinux-compatible.populateCmd}' -c '${config.system.build.toplevel}' -d ./files/boot
      '';
    };

    boot.loader = {
      raspberryPi.firmwareDir = "/boot/firmware";
      grub.enable = false;
    };

    fileSystems."/boot/firmware".options = [ "x-systemd.automount" ];

    hardware.firmware = mkIf cfg.enableWirelessFirmware [ (let
      firmwareNonfree = pkgs.fetchFromGitHub {
        owner = "RPi-Distro";
        repo = "firmware-nonfree";
        rev = "7533cd1f124f07d87ca6fd11a4a2143748ed806c";
        sha256 = "0nvs3zrsv1apvijalf16382yqia6zb1cdgckqaw3pph3lb4bzlqp";
      };
    in pkgs.runCommand "raspberry-pi-wireless-firmware" {} ''
      mkdir -p "$out/lib/firmware/brcm"
      cp '${firmwareNonfree}'/brcm/brcmfmac434??-sdio.{bin,clm_blob,raspberrypi*.txt} \
        "$out/lib/firmware/brcm"
      # Provide all the file names used by mainline and downstream kernels
      ln -s brcmfmac43430-sdio.raspberrypi-rpi.txt "$out/lib/firmware/brcm/brcmfmac43430-sdio.raspberrypi,model-zero-w.txt"
      ln -s brcmfmac43430-sdio.raspberrypi-rpi.txt "$out/lib/firmware/brcm/brcmfmac43430-sdio.raspberrypi,3-model-b.txt"
      ln -s brcmfmac43430-sdio.raspberrypi-rpi.txt "$out/lib/firmware/brcm/brcmfmac43430-sdio.txt"
    '') ];

    # Enable SD card TRIM
    services.fstrim.enable = true;
  };
}
