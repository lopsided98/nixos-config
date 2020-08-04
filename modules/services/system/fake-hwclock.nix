{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.fakeHwClock;
in {
  options.services.fakeHwClock.enable = mkEnableOption "fake hardware clock";

  config = mkIf cfg.enable {
    systemd.services.fake-hwclock = {
      before = [ "sysinit.target" "shutdown.target" ];
      after = [ "local-fs.target" ];
      wantedBy = [ "sysinit.target" ];
      conflicts = [ "shutdown.target" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "fake-hwclock";
        ExecStart = pkgs.writers.writeBash "fake-hwclock-start" ''
          if [ -e /var/lib/fake-hwclock/clock ]; then
            ${pkgs.coreutils}/bin/date -s "$(< /var/lib/fake-hwclock/clock)"
          fi
        '';
        ExecStop = pkgs.writers.writeBash "fake-hwclock-stop" ''
          ${pkgs.coreutils}/bin/date > /var/lib/fake-hwclock/clock
        '';
      };
    };
  };
}
