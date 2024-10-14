# This module does not have an enable option because the sd-image module does
# not either and there is no way to do conditional imports. Any machine that
# uses this configuration must manually include it.

{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.local.machine.beagleBone;

  firmwarePartitionMount = "/boot/firmware";

  update-firmware = let
    inputs = with pkgs; [ util-linux coreutils ];
  in pkgs.writers.writeBashBin "nixos-update-firmware" ''
    set -eu -o pipefail
    export PATH=${lib.escapeShellArg (lib.makeBinPath inputs)}

    firmware=${lib.escapeShellArg firmwarePartitionMount}

    if ! mountpoint "$firmware"; then
      exit 1
    fi

    cp '${pkgs.ubootAmx335xEVM}'/{MLO,u-boot.img} -t "$firmware"
  '';
in {
  imports = singleton ../sd-image.nix;

  options.local.machine.beagleBone = {
    enable = lib.mkEnableOption "Beagle Bone hardware support";

    firmwarePartitionUUID = lib.mkOption {
      type = lib.types.str;
      example = "2178-694E";
      description = ''
        UUID for the firmware partition; 8 uppercase hex digits in two groups
        separated by a dash.
      '';
    };

    enableWirelessCape = lib.mkEnableOption "support for the Wireless Connectivity Cape";
  };

  config = lib.mkIf cfg.enable {
    assertions = [ {
      assertion = (builtins.match "[0-9,A-F]{4}-[0-9,A-F]{4}" cfg.firmwarePartitionUUID != null);
      message = "Invalid firmware partition UUID: ${cfg.firmwarePartitionUUID}";
    } ];

    fileSystems.${firmwarePartitionMount} = {
      device = "/dev/disk/by-uuid/${cfg.firmwarePartitionUUID}";
      fsType = "vfat";
      options = [ "noauto" "x-systemd.automount" ];
    };

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

    # Enable SD card TRIM
    services.fstrim.enable = true;

    environment.systemPackages = [ update-firmware ];

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
