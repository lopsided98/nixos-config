{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.aur-buildbot;

  python = cfg.package.python;
in {
  options = {
    services.aur-buildbot = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the AUR Buildbot Master.";
      };

      buildbotDir = mkOption {
        default = "/var/lib/aur-buildbot/master";
        type = types.path;
        description = "Specifies the AUR Buildbot directory.";
      };

      configFile = mkOption {
        default = "localhost";
        type = types.lines;
        description = "AUR Buildbot YAML configuration file";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.python3Packages.buildbot.withPlugins (with pkgs.python3Packages.buildbot-plugins; [ www console-view waterfall-view grid-view ]);
        defaultText = "pkgs.buildbot.withPlugins (with pkgs.buildbot-plugins; [ www console-view waterfall-view grid-view ])";
        description = "Package to use for buildbot.";
        example = literalExample "pkgs.buildbot-full";
      };
    };
  };

  config = mkIf cfg.enable {

    users.extraGroups."aur-buildbot" = {};
    users.extraUsers."aur-buildbot" = {
      description = "AUR Buildbot Master user";
      isSystemUser = true;
      home = cfg.buildbotDir;
      group = "aur-buildbot";
    };

    services.buildbot-master = {
      enable = true;
      inherit (cfg) package buildbotDir;
      home = cfg.buildbotDir;
      user = "aur-buildbot";
      group = "aur-buildbot";
      packages = with pkgs; [ git pacman ];
      masterCfg = "${pkgs.aur-buildbot}/master/master.cfg";
    };

    systemd.services.buildbot-master = {
      description = mkForce "AUR Buildbot Master";
      environment = {
          PYTHONPATH = mkForce "${pkgs.aur-buildbot}/master:${(python.withPackages (self: [
            cfg.package
            self.future
            self.aur
            self.pyxdg
            self.memoizedb
            self.xcpf
            self.xcgf
          ]))}/${python.sitePackages}";
          AUR_BUILDBOT_CONFIG = pkgs.writeText "aur-buildbot-config.yml" cfg.configFile;
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ lopsided98 ];

}
