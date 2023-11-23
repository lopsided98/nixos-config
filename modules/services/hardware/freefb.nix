{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.freefb;
in {
  options.services.freefb = {
    enable = mkEnableOption "FreeFB Fitbit synchronization";

    interval = mkOption {
      type = types.str;
      default = "*:0/30";
      example = "hourly";
      description = ''
        Syncronize trackers at this interval. The default is to run every half
        hour.

        The format is described in
        <citerefentry><refentrytitle>systemd.time</refentrytitle>
        <manvolnum>7</manvolnum></citerefentry>.
      '';
    };

    link = mkOption {
      type = types.enum [ "dongle" "ble" ];
      default = "dongle";
      description = ''
        Type of connection to use to connect to trackers.
      '';
    };

    dump = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to dump mega dump files to /var/lib/freefb.
      '';
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to freefb config file. This file normally contains passwords, so
        should not be kept in the Nix store.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      users = {
        users.freefb = {
          isSystemUser = true;
          description = "FreeFB user";
          group = "freefb";
        };
        groups.freefb = {};
      };

      systemd.services.freefb = {
        serviceConfig = mkMerge [
          {
            Type = "oneshot";
            ExecStart = escapeShellArgs ([
              "${pkgs.freefb}/bin/freefb"
            ] ++ optionals (cfg.configFile != null) [
              "--config" cfg.configFile
            ] ++ [
              "--link" "${cfg.link}"
              "sync"
            ] ++ optional cfg.dump "--dump");
            User = "freefb";
            Group = "freefb";
            CacheDirectory = "freefb";
          }
          (mkIf cfg.dump {
            StateDirectory = "freefb";
            StateDirectoryMode = "0750";
            WorkingDirectory = "/var/lib/freefb";
          })
        ];
        environment = {
          XDG_CACHE_HOME = "/var/cache";
          RUST_LOG = "info";
        };
        startAt = cfg.interval;
      };
    })
    (mkIf (cfg.link == "dongle") {
      # Allow access to Fitbit dongle
      services.udev.extraRules = ''
        SUBSYSTEM=="usb", ATTRS{idVendor}=="2687", ATTRS{idProduct}=="fb01", MODE="660", GROUP="freefb"
      '';
    })
    (mkIf (cfg.link == "ble") {
      hardware.bluetooth = {
        enable = true;
        package = pkgs.bluez5-experimental;
        # Enable advertisement monitor
        settings.General.Experimental = true;
      };

      # Allow access to BlueZ over DBus
      services.dbus.packages = singleton (pkgs.writeTextFile {
        name = "dbus-freefb-bluetooth.conf";
        destination = "/etc/dbus-1/system.d/freefb-bluetooth.conf";
        text = ''
          <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
           "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
          <busconfig>
            <policy user="freefb">
              <allow send_destination="org.bluez"/>
            </policy>
          </busconfig>
        '';
      });
    })
  ]);
}
