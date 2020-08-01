{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.systemd.notifyFailed;
in {
  options = {
    systemd = {
      services = mkOption {
        type = types.attrsOf (types.submodule ({ config, ... }: {
          options.notifyFailed = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to send an email when this service fails";
          };
          config.unitConfig.OnFailure = mkIf (cfg.enable && config.notifyFailed) "notify-failed@%n.service";
        }));
      };
      notifyFailed = {
        enable = mkEnableOption "systemd service failure notification";
        address = mkOption {
          type = types.str;
          default = "benwolsieffer@gmail.com";
          description = "Recipient email address";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services."notify-failed@" = {
      script = ''
        '${config.local.services.mail.sendmail}' -t <<EOF
        From: ${config.networking.hostName} <notify-failed@${config.networking.hostName}>
        To: ${cfg.address}
        Subject: $1 failed
        $(systemctl status "$1")
        EOF
      '';
      scriptArgs = "%I";
    };

    local.services.mail.enable = true;
  };
}
