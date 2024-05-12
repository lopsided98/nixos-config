# This module does not have an enable option because the sd-image module does
# not either and there is no way to do conditional imports. Any machine that
# uses this configuration must manually include it.

{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.local.machine.beagleBone;
in {
  imports = singleton ../sd-image.nix;

  options.local.machine.beagleBone = {
    enableWirelessCape = mkEnableOption "support for the Wireless Connectivity Cape";
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
        generic-extlinux-compatible = {
          enable = true;
          copyKernels = false;
        };
      };
      kernelParams = [
        "earlycon" # Enable early serial console
      ];
    };

    fileSystems."/boot/firmware".options = [ "x-systemd.automount" ];

    # Enable SD card TRIM
    services.fstrim.enable = true;

    hardware = mkIf cfg.enableWirelessCape {
      deviceTree = {
        filter = "am335x-bone*.dtb";
        overlays = singleton {
          name = "wifi-cape";
          dtsFile = ./BB-GATEWAY-WL1837-00A0.dts;
        };
      };

      firmware = singleton (pkgs.runCommand "wl18xx-firmware" {} ''
        mkdir -p "$out/lib/firmware/ti-connectivity"
        cp '${pkgs.linux-firmware}'/lib/firmware/ti-connectivity/wl18xx-*.bin "$out/lib/firmware/ti-connectivity"
      '');
    };
  };
}
