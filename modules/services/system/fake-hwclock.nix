{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.fakeHwClock;

  saveScript = pkgs.writers.writeBash "fake-hwclock-save" ''
    ${pkgs.coreutils}/bin/date > /var/lib/fake-hwclock/clock
  '';
in {
  options.services.fakeHwClock = {
    enable = mkEnableOption "fake hardware clock";

    interval = mkOption {
      type = types.str;
      default = "*:0/10";
      example = "hourly";
      description = ''
        Save the current time at this interval. Defaults to every 10 minutes.

        The format is described in
        <citerefentry><refentrytitle>systemd.time</refentrytitle>
        <manvolnum>7</manvolnum></citerefentry>.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services = {
      fake-hwclock = {
        before = [ "sysinit.target" "shutdown.target" ];
        after = [ "local-fs.target" ];
        wantedBy = [ "sysinit.target" ];
        conflicts = [ "shutdown.target" ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "fake-hwclock";
          ExecStart = pkgs.writers.writeBash "fake-hwclock-restore" ''
            if [ -e /var/lib/fake-hwclock/clock ]; then
              ${pkgs.coreutils}/bin/date -s "$(< /var/lib/fake-hwclock/clock)"
            fi
          '';
          ExecStop = saveScript;
        };
      };

      fake-hwclock-save = {
        serviceConfig = {
          Type = "oneshot";
          StateDirectory = "fake-hwclock";
          ExecStart = saveScript;
        };
        startAt = cfg.interval;
      };
    };
  };
}
