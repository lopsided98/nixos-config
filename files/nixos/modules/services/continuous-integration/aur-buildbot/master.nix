{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.aur-buildbot;

  python = cfg.package.python;
  pythonPackages = python.pkgs;
  pythonVersion = python.pythonVersion;
  
  tacFile = pkgs.writeText "aur-buildbot-master.tac" ''
    import os

    from twisted.application import service
    from buildbot.master import BuildMaster

    basedir = '${cfg.buildbotDir}'

    rotateLength = 10000000
    maxRotatedFiles = 10
    configfile = '${pkgs.aur-buildbot}/master/master.cfg'

    # Default umask for server
    umask = None

    # note: this line is matched against to check that this is a buildmaster
    # directory; do not edit it.
    application = service.Application('buildmaster')

    m = BuildMaster(basedir, configfile, umask)
    m.setServiceParent(application)
    m.log_rotation.rotateLength = rotateLength
    m.log_rotation.maxRotatedFiles = maxRotatedFiles
  '';
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
        default = pkgs.buildbot.withPlugins (with pkgs.buildbot-plugins; [ www console-view waterfall-view grid-view ]);
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

    systemd.services.aur-buildbot = {
      description = "AUR Buildbot Master";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ pythonPackages.twisted git pacman ];
      environment = {
          PYTHONPATH = "${pkgs.aur-buildbot}/master:" + (with pythonPackages; concatMapStringsSep ":" (pkg: "${pkg}/lib/${python.libPrefix}/site-packages")
            [ cfg.package future pkgs.python3Packages.aur pyxdg pkgs.python3Packages.memoizedb pkgs.python3Packages.xcpf pkgs.python3Packages.xcgf ]);
          AUR_BUILDBOT_CONFIG = pkgs.writeText "aur-buildbot-config.yml" cfg.configFile;
      };
      serviceConfig = {
        Type = "simple";
        User = "aur-buildbot";
        Group = "aur-buildbot";
        WorkingDirectory = cfg.buildbotDir;

        # NOTE: call twistd directly with stdout logging for systemd
        #ExecStart = "${cfg.package}/bin/buildbot-worker start --nodaemon ${cfg.buildbotDir}";
        ExecStart = "${cfg.package}/bin/buildbot-twistd -n -l - -y ${tacFile}";
      };

    };
  };

  meta.maintainers = with lib.maintainers; [ nand0p ];

}
