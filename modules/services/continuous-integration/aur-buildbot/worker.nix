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

    basedir = '/var/lib/${cfg.stateDirectory}'
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
      
      hostMessage = mkOption {
        default = "AUR Buildbot Worker on ${config.networking.hostName}";
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

    systemd.services.aur-buildbot-worker = {
      description = "AUR Buildbot Worker";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ "/run/wrappers" pythonPackages.twisted git ];

      preStart = ''
        mkdir -p "/var/lib/${cfg.stateDirectory}/info"
        ln -sf "${pkgs.writeText "aur-buildbot-worker-host" cfg.hostMessage}" "/var/lib/${cfg.stateDirectory}/info/host"
        ln -sf "${pkgs.writeText "aur-buildbot-worker-admin" cfg.adminMessage}" "/var/lib/${cfg.stateDirectory}/info/admin"
      '';

      serviceConfig = {
        Type = "simple";
        User = "aur-buildbot-worker";
        Group = "aur-buildbot";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        WorkingDirectory = "/run/aur-buildbot/worker";
        RuntimeDirectory = "aur-buildbot/worker";
        RuntimeDirectoryMode = "0700";
        StateDirectory = cfg.stateDirectory;
        StateDirectoryMode = "0700";
        Environment = "PYTHONPATH=${cfg.package}/${python.sitePackages}:${pythonPackages.future}/${python.sitePackages}";

        # NOTE: call twistd directly with stdout logging for systemd
        #ExecStart = "${cfg.package}/bin/buildbot-worker start --nodaemon /var/lib/${cfg.stateDirectory}";
        ExecStart = "${pythonPackages.twisted}/bin/twistd -n -l - -y ${tacFile}";
      };

    };
  };
}
