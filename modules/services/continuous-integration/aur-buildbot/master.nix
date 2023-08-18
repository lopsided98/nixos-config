{ config, lib, pkgs, ... }:

let
  cfg = config.services.aur-buildbot;

  package = pkgs.python3.pkgs.toPythonModule cfg.package;
  python = package.pythonModule;
in {
  options = {
    services.aur-buildbot = {
      enable = lib.mkEnableOption "AUR Buildbot Master";

      buildbotDir = lib.mkOption {
        default = "/var/lib/aur-buildbot/master";
        type = lib.types.path;
        description = "Specifies the AUR Buildbot directory.";
      };

      configFile = lib.mkOption {
        default = "localhost";
        type = lib.types.lines;
        description = "AUR Buildbot YAML configuration file";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.buildbot.withPlugins (with pkgs.buildbot-plugins; [ www console-view waterfall-view grid-view ]);
        defaultText = "pkgs.buildbot.withPlugins (with pkgs.buildbot-plugins; [ www console-view waterfall-view grid-view ])";
        description = "Package to use for buildbot.";
        example = lib.literalExample "pkgs.buildbot-full";
      };
    };
  };

  config = lib.mkIf cfg.enable {

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
      packages = with pkgs; [ git pacman gzip ];
      pythonPackages = self: [
        self.pyyaml
        self.requests
        self.future
        self.aur
        self.pyxdg
        self.memoizedb
        self.xcpf
        self.xcgf
      ];
      masterCfg = "${pkgs.aur-buildbot}/master/master.cfg";
    };

    systemd.services.buildbot-master = {
      environment = {
        PYTHONPATH = lib.mkForce "${pkgs.aur-buildbot}/master:${(python.withPackages (self: [
          package
          self.pyyaml
          self.requests
          self.future
          self.aur
          self.pyxdg
          self.memoizedb
          self.xcpf
          self.xcgf
        ]))}/${python.sitePackages}";
        AUR_BUILDBOT_CONFIG = pkgs.writeText "aur-buildbot-config.yml" cfg.configFile;
      };
      serviceConfig.TimeoutStartSec = "300";
    };
  };

  meta.maintainers = with lib.maintainers; [ lopsided98 ];

}
