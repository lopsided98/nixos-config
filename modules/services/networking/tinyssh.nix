{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.tinyssh;
in {
  options = {
    services.tinyssh = {
      enable = mkEnableOption "TinySSH server";

      ports = mkOption {
        type = types.listOf types.port;
        default = [ 22 ];
        description = ''
          Specifies on which ports the TinySSH daemon listens.
        '';
      };

      keyDir = mkOption {
        type = types.path;
        default = "/etc/tinyssh/sshkeydir";
        description = ''
          Directory to store host keys.
        '';
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Extra arguments to pass to tinysshd.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      sockets.tinysshd = {
        description = "TinySSH Socket";
        wantedBy = [ "sockets.target" ];
        socketConfig = {
          ListenStream = cfg.ports;
          Accept = true;
        };
      };

      services."tinysshd@" = {
        description = "TinySSH Daemon";
        after = [ "network.target" ];
        stopIfChanged = false;

        preStart = ''
          mkdir -m 0755 -p "$(dirname "${cfg.keyDir}")"
          ${pkgs.tinyssh}/bin/tinysshd-makekey -q "${cfg.keyDir}" || true
        '';

        serviceConfig = {
          ExecStart = "${pkgs.tinyssh}/bin/tinysshd ${concatStringsSep " " cfg.extraArgs} -- ${cfg.keyDir}";
          KillMode = "process";
          StandardInput = "socket";
          StandardError = "journal";
        };
      };
    };
  };
}
