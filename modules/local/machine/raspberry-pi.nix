# This module does not have an enable option because the sd-image module does
# not either and there is no way to do conditional imports. Any machine that
# uses this configuration must manually include it.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.machine.raspberryPi;

  firmwarePartitionMount = "/boot/firmware";
  configTxt = pkgs.writeText "config.txt" cfg.firmwareConfig;
  uboot =
    if cfg.version == 0 then
      pkgs.ubootRaspberryPiZero
    else if cfg.version == 1 then
      pkgs.ubootRaspberryPi
    else if cfg.version == 2 then
      pkgs.ubootRaspberryPi2
    else if cfg.version == 3 then
      if stdenv.hostPlatform.isAarch64 then
        pkgs.ubootRaspberryPi3_64bit
      else
        pkgs.ubootRaspberryPi3_32bit
    else if cfg.version == 4 then
      pkgs.ubootRaspberryPi4
    else
      throw "U-Boot is not yet supported on the Raspberry Pi ${cfg.version}.";

  update-firmware = let
    inputs = with pkgs; [ util-linux coreutils ];
  in pkgs.writers.writeBashBin "nixos-update-firmware" ''
    set -eu -o pipefail
    export PATH=${lib.escapeShellArg (lib.makeBinPath inputs)}

    firmware=${lib.escapeShellArg firmwarePartitionMount}

    if ! mountpoint "$firmware"; then
      exit 1
    fi

    cp ${lib.escapeShellArg configTxt} "$firmware"/config.txt
    cp ${lib.escapeShellArg uboot}/u-boot.bin "$firmware"/u-boot.bin
  '';
in {
  imports = singleton ./sd-image.nix;

  options.local.machine.raspberryPi = {
    enable = lib.mkEnableOption "Raspberry Pi hardware support";

    version = mkOption {
      type = types.enum [ 0 1 2 3 4 ];
      description = "Raspberry Pi model version number";
    };

    enableWirelessFirmware = lib.mkEnableOption "WiFi/Bluetooth firmware for the Raspberry Pi";

    firmwarePartitionUUID = mkOption {
      type = lib.types.str;
      example = "2178-694E";
    };

    firmwareConfig = mkOption {
      type = types.lines;
      description = ''
        Extra options that will be appended to `${firmwarePartitionMount}/config.txt` file.
        For possible values, see: https://www.raspberrypi.com/documentation/computers/config_txt.html
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [ {
      assertion = (builtins.match "[0-9,A-F]{4}-[0-9,A-F]{4}" cfg.firmwarePartitionUUID != null);
      message = "Invalid firmware partition UUID: ${cfg.firmwarePartitionUUID}";
    } ];

    local.machine.raspberryPi.firmwareConfig = mkBefore (''
      # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
      # when attempting to show low-voltage or overtemperature warnings.
      avoid_warnings=1
      # U-Boot needs this to work, regardless of whether UART is actually used or not.
      # Look in arch/arm/mach-bcm283x/Kconfig in the U-Boot tree to see if this is still
      # a requirement in the future.
      enable_uart=1
      kernel=u-boot.bin
    '' + optionalString pkgs.stdenv.hostPlatform.isAarch64 ''
      # Boot in 64-bit mode.
      arm_64bit=1
    '');

    # Raspberry Pi 0s and 1s are the only ARMv6 systems I have, so it makes
    # sense to optimize for them. More importantly, enabling ARMv6k avoids many
    # issues with the lack of atomics support.
    local.system.hostSystem = mkIf (cfg.version <= 1) (lib.systems.examples.raspberryPi // {
      gcc = {
        arch = "armv6k";
        fpu = "vfpv2";
        tune = "arm1176jzf-s";
      };
    });

    fileSystems.${firmwarePartitionMount} = {
      device = "/dev/disk/by-uuid/${cfg.firmwarePartitionUUID}";
      fsType = "vfat";
      options = [ "noauto" "x-systemd.automount" ];
    };

    sdImage = let
      firmwareBuilder = pkgs.buildPackages.callPackage
        (pkgs.path + "/nixos/modules/system/boot/loader/raspberrypi/firmware-builder.nix") {
          inherit (cfg) version;
          ubootEnabled = true;
          # Override to use host packages where necessary
          inherit pkgs; # For U-Boot
          inherit (pkgs) raspberrypifw;
        };
      raspberryPiBuilder = pkgs.buildPackages.callPackage
        (pkgs.path + "/nixos/modules/system/boot/loader/raspberrypi/raspberrypi-builder.nix") { };
    in {
      imageBaseName = "${config.networking.hostName}-sd-image";

      firmwareSize = mkIf (!ubootEnabled) 200;
      firmwarePartitionID = "0x${builtins.replaceStrings [ "-" "" ] cfg.firmwarePartitionUUID}";

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
      raspberryPi = {
        inherit (cfg) version;
        firmwareDir = firmwarePartitionMount;
      };
      generic-extlinux-compatible.enable = true;
      grub.enable = false;
    };

    hardware.firmware = mkIf cfg.enableWirelessFirmware [ pkgs.raspberrypiWirelessFirmware ];

    # Enable SD card TRIM
    services.fstrim.enable = true;

    environment.systemPackages = [ update-firmware ];
  };
}
