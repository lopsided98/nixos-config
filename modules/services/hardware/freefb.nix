{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.freefb;
in {
  options.services.freefb = {
    enable = mkEnableOption "FreeFB Fitbit synchronization";

    interval = mkOption {
      type = types.str;
      default = "hourly";
      example = "*:0/10";
      description = ''
        Syncronize trackers at this interval. The default is to run hourly.

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
  };

  config = mkIf cfg.enable {
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
            "-l" "${cfg.link}"
            "sync"
          ] ++ optional cfg.dump "--dump");
        }
        (mkIf cfg.dump {
          StateDirectory = "freefb";
          StateDirectoryMode = "0750";
          WorkingDirectory = "/var/lib/freefb";
        })
      ];
      environment.RUST_LOG = "info";
      startAt = cfg.interval;
    };

    # Allow access to Fitbit dongle
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="2687", ATTRS{idProduct}=="fb01", MODE="660", GROUP="freefb"
    '';
  };
}
