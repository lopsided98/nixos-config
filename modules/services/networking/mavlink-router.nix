{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mavlink-router;
  settingsFormat = pkgs.formats.gitIni { };
in {
  # Interface

  options.services.mavlink-router = {
    enable = mkEnableOption "MAVLink Router";

    settings = mkOption {
      type = settingsFormat.type;
      default = {};
      example = {
        UartEndpoint.alpha = {
          Device = "/dev/ttyS0";
          Baud = 52000;
        };
      };
      description = lib.mdDoc ''
        MAVLink Router configuration, see:
        https://github.com/mavlink-router/mavlink-router/blob/master/examples/config.sample
      '';
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    systemd.packages = [ pkgs.mavlink-router ];

    systemd.services.mavlink-router = {
      wantedBy = [ "multi-user.target" ];
      environment.MAVLINK_ROUTERD_CONF_FILE = settingsFormat.generate "mavlink-router.conf" cfg.settings;
    };
  };
}
