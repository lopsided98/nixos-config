{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.watchdog;

  confOptional = k: v: optionalString (v != null) "${k} = ${toString v}";
  confBool = v: if v then "yes" else "no";

  watchdogConf = pkgs.writeText "watchdog.conf" ''
    ${confOptional "watchdog-device" cfg.watchdogDevice}
    watchdog-timeout = ${toString cfg.watchdogTimeout}
    realtime = ${confBool cfg.realtime}

    ${cfg.extraConfig}
  '';
in {
  options.services.watchdog = {
    enable = mkEnableOption "software watchdog daemon";

    interval = mkOption {
      type = types.ints.positive;
      default = 1;
      description = ''
        The highest possible interval between two writes to the watchdog device.
        The device is triggered after each check regardless of the time it took.
        After finishing all checks watchdog goes to sleep for a full cycle of
        <option>interval</option> seconds.
      '';
    };

    watchdogDevice = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Watchdog device name, typically /dev/watchdog. If null, keep alive
        support is disabled.
      '';
      example = "/dev/watchdog";
    };

    watchdogTimeout = mkOption {
      type = types.ints.positive;
      default = 60;
      description = ''
        Watchdog device timeout in seconds.
      '';
      example = 10;
    };

    realtime = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Lock the watchdog into memory so it is never swapped out.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra lines to append to the configuration file.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.watchdog = {
      description = "Software watchdog daemon";
      serviceConfig = {
        Type = "exec";
        ExecStart = "${pkgs.watchdog}/bin/watchdog -F -c ${watchdogConf}";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
