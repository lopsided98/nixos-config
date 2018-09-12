{ config, lib, pkgs, ... }: with lib; let
  cfg = config.modules.audioRecorder;
  uwsgiSocket = "${config.services.uwsgi.runDir}/audio-recorder.sock";
in {

  options.modules.audioRecorder = {
    enable = mkEnableOption "Audio recording server";

    virtualHost = mkOption {
      type = types.str;
      description = "Name of the nginx virtual host";
    };

    audioDir = mkOption {
      type = types.str;
      default = "audio";
      description = "Path to save recorded files (relative to /var/lib)";
    };

    cardIndex = mkOption {
      type = types.int;
      default = 0;
      description = "ALSA card index";
    };

    control = mkOption {
      type = types.str;
      default = "Capture";
      description = "Name of the capture volume control";
    };

    devices = mkOption {
      type = types.listOf types.str;
      default = [ "" ];
      description = "Addresses of devices to display in the web interface";
    };
  };

  config = mkIf cfg.enable {
    users = {
      users.audio-server = {
        isSystemUser = true;
        group = "audio-recorder";
        extraGroups = [ "audio" ];
      };
      groups.audio-recorder = {};
    };

    systemd.services.audio-server = let
      pyEnv = pkgs.python3.withPackages(ps: [ pkgs.audioRecorder ]);
    in {
      environment = {
        PYTHONPATH="${pyEnv}/${pkgs.python3.sitePackages}/";
        AUDIO_SERVER_SETTINGS = pkgs.writeText "audio-server-settings.yaml" ''
          audio_dir: "/var/lib/${cfg.audioDir}"
          card_index: ${builtins.toString cfg.cardIndex}
          control: "${cfg.control}"
        '';
      };
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "audio-server";
        Group = "audio-recorder";
        ExecStart = "${pkgs.python3.interpreter} -m audio_server.server";
        AmbientCapabilities = "CAP_SYS_TIME";
        StateDirectory = cfg.audioDir;
        StateDirectoryMode = "0770";
      };
    };

    security.sudo = {
      enable = true;
      extraConfig = with pkgs; ''
        Defaults:nginx secure_path="${systemd}/bin"
        nginx ALL=(root) NOPASSWD: ${systemd}/bin/poweroff
      '';
    };

    services.uwsgi = {
      enable = true;
      user = "nginx";
      group = "nginx";
      plugins = [ "python3" ];
      type = "emperor";
      vassals.audio-recorder = {
        pythonPackages = self: with self; [ pkgs.audioRecorder ];
        env = {
          PATH = "/run/wrappers/bin";
          AUDIO_RECORDER_SETTINGS = pkgs.writeText "audio-recorder-settings.py" ''
            DEVICES=[${concatMapStrings (d: "\"${escape ["\""] d}\",") cfg.devices}]
          '';
          PYTHONPATH = pkgs.python3.withPackages(ps: [ pkgs.audioRecorder ]);
        };
        extraConfig = {
          socket = uwsgiSocket;
          module = "web_interface";
          callable = "app";
          processes = 2;
          threads = 4;
        };
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.audio-recorder = {
        locations = {
          "/" = {
            tryFiles = "$uri @audio_recorder";
          };

          "/levels" = {
            tryFiles = "$uri @audio_recorder";
            extraConfig = ''
              chunked_transfer_encoding off;
            '';
          };

          "@audio_recorder" = {
            extraConfig = ''
              uwsgi_pass unix:${uwsgiSocket};
            '';
          };

          "/static/" = {
            root = "${pkgs.audioRecorder}/${pkgs.python3.sitePackages}/web_interface";
          };
        };

        extraConfig = ''
          expires 300;
        '';
      };
    };
  };
}
