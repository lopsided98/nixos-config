{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.aur-buildbot-worker;

  python = cfg.package.pythonModule;
in {
  options = {
    services.aur-buildbot-worker = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the AUR Buildbot Worker.";
      };

      stateDirectory = mkOption {
        default = "aur-buildbot/worker";
        type = types.str;
        description = "Specifies the AUR Buildbot directory below /var/lib";
      };

      workerUser = mkOption {
        default = config.networking.hostName;
        type = types.str;
        description = "Specifies the AUR Buildbot Worker user.";
      };

      workerPassFile = mkOption {
        type = types.path;
        description = "File used to store the AUR Buildbot worker password";
      };

      hostMessage = mkOption {
        default = "AUR Buildbot Worker";
        type = types.str;
        description = "Description of this worker";
      };

      adminMessage = mkOption {
        default = "";
        type = types.str;
        description = "Name of the administrator of this worker";
      };

      masterHost = mkOption {
        default = "localhost";
        type = types.str;
        description = "Specifies the AUR Buildbot master hostname.";
      };

      masterPort = mkOption {
        default = 7192;
        type = types.int;
        description = "Specifies the AUR Buildbot master port.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.aur-buildbot-worker.hostMessage = mkDefault "AUR Buildbot Worker on ${config.networking.hostName}";

    security.sudo = {
      enable = true;
      extraConfig = with pkgs; ''
        Defaults:aur-buildbot-worker secure_path="${aur-buildbot}/worker:${docker}/bin:${coreutils}/bin"
        aur-buildbot-worker ALL=(root) NOPASSWD: ${aur-buildbot}/worker/build-package *
      '';
    };

    users.extraGroups."aur-buildbot" = {};
    users.extraUsers."aur-buildbot-worker" = {
      description = "AUR Buildbot Worker user";
      isSystemUser = true;
      home = "/var/lib/${cfg.stateDirectory}";
      group = "aur-buildbot";
    };

    services.buildbot-worker = {
      enable = true;
      buildbotDir = "/var/lib/${cfg.stateDirectory}";
      user = "aur-buildbot-worker";
      group = "aur-buildbot";
      package = pkgs.python3Packages.buildbot-worker;
      masterUrl = "${cfg.masterHost}:${toString cfg.masterPort}";

      inherit (cfg) workerUser workerPassFile hostMessage adminMessage;
    };

    systemd.services.buildbot-worker = {
      description = mkForce "AUR Buildbot Worker";
      path = [ "/run/wrappers" ];
      serviceConfig = {
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        WorkingDirectory = mkForce "/run/aur-buildbot/worker";
        RuntimeDirectory = "aur-buildbot/worker";
        RuntimeDirectoryMode = "0700";
        StateDirectory = cfg.stateDirectory;
        StateDirectoryMode = "0700";
      };
    };
  };
}
