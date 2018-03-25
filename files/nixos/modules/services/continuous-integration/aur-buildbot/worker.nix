{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.aur-buildbot-worker;

  python = cfg.package.python or pkgs.python2;
  pythonPackages = python.pkgs;
  pythonVersion = python.pythonVersion;
  
  tacFile = pkgs.writeText "aur-buildbot-worker.tac" ''
    import os

    from buildbot_worker.bot import Worker
    from twisted.application import service

    basedir = '${cfg.buildbotDir}'
    rotateLength = 10000000
    maxRotatedFiles = 10

    # note: this line is matched against to check that this is a worker
    # directory; do not edit it.
    application = service.Application('buildbot-worker')

    buildmaster_host = "${cfg.masterHost}"
    port = ${toString cfg.masterPort}
    workername = '${cfg.workerUser}'
    
    with open('${cfg.workerPassFile}', 'r') as passwd_file:
        passwd = passwd_file.read().strip('\r\n')
    keepalive = 600
    umask = None
    maxdelay = 300
    numcpus = None
    allow_shutdown = None

    s = Worker(buildmaster_host, port, workername, passwd, basedir,
               keepalive, umask=umask, maxdelay=maxdelay,
               numcpus=numcpus, allow_shutdown=allow_shutdown)
    s.setServiceParent(application)
  '';
in {
  options = {
    services.aur-buildbot-worker = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the AUR Buildbot Worker.";
      };

      buildbotDir = mkOption {
        default = "/var/lib/aur-buildbot/worker";
        type = types.path;
        description = "Specifies the AUR Buildbot directory.";
      };

      workerUser = mkOption {
        default = config.networking.hostName;
        type = types.str;
        description = "Specifies the AUR Buildbot Worker user.";
      };

      workerPass = mkOption {
        default = "pass";
        type = types.str;
        description = "Specifies the AUR Buildbot Worker password.";
      };
      
      workerPassFile = mkOption {
        default = pkgs.writeText "aur-buildbot-worker-password" cfg.workerPass;
        type = types.path;
        description = "File used to store the AUR Buildbot worker password";
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

      package = mkOption {
        type = types.package;
        default = pkgs.buildbot-worker;
        defaultText = "pkgs.buildbot-worker";
        description = "Package to use for buildbot worker.";
        example = literalExample "pkgs.buildbot-worker";
      };

    };
  };

  config = mkIf cfg.enable {
    security.sudo = {
      enable = true;
      extraConfig = with pkgs; ''
        Defaults:aur-buildbot-worker secure_path="${aur-buildbot}/worker:${docker}/bin:${coreutils}/bin"
        aur-buildbot-worker ALL=(ALL) NOPASSWD: ${aur-buildbot}/worker/build-package *
      '';
    };
    
    users.extraGroups."aur-buildbot" = {};
    users.extraUsers."aur-buildbot-worker" = {
      description = "AUR Buildbot Worker user";
      isSystemUser = true;
      home = cfg.buildbotDir;
      group = "aur-buildbot";
    };

    systemd.services.aur-buildbot-worker = {
      description = "AUR Buildbot Worker";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ "/run/wrappers" pythonPackages.twisted git ];

      serviceConfig = {
        Type = "simple";
        User = "aur-buildbot-worker";
        Group = "aur-buildbot";
        WorkingDirectory = cfg.buildbotDir;
        Environment = "PYTHONPATH=${cfg.package}/lib/python${pythonVersion}/site-packages:${pythonPackages.future}/lib/python3.6/site-packages";

        # NOTE: call twistd directly with stdout logging for systemd
        #ExecStart = "${cfg.package}/bin/buildbot-worker start --nodaemon ${cfg.buildbotDir}";
        ExecStart = "${pythonPackages.twisted}/bin/twistd -n -l - -y ${tacFile}";
      };

    };
  };
}
