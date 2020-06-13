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

    clockMaster = mkOption {
      type = types.bool;
      default = false;
      description = "If true, this device serves time to the others";
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

    systemd.services.audio-server = {
      path = [ "/run/wrappers" pkgs.systemd ];
      environment = {
        RUST_LOG = "debug";
        AUDIO_SERVER_SETTINGS = pkgs.writeText "audio-server-settings.yaml" (builtins.toJSON {
          systemd_logging = true;
          audio_dir = "/var/lib/${cfg.audioDir}";
          mixer_control = cfg.control;
          mixer_enums = [ {
            control = "Capture Mux";
            value = "LINE_IN";
          } ];
          clock_master = cfg.clockMaster;
        });
      };
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "audio-server";
        Group = "audio-recorder";
        ExecStart = "${pkgs.audio-recorder.audio-server}/bin/audio_server";
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

        Defaults:audio-server secure_path="${systemd}/bin:${chrony}/bin"
        audio-server ALL=(root) NOPASSWD: ${systemd}/bin/systemctl start chronyd
        audio-server ALL=(chrony) NOPASSWD: ${chrony}/bin/chronyc *
      '';
    };

    services.uwsgi = {
      enable = true;
      user = "nginx";
      group = "nginx";
      plugins = [ "python3" ];
      instance = {
        type = "emperor";
        vassals.audio-recorder = {
          type = "normal";
          pythonPackages = self: with self; [ pkgs.audio-recorder.web-interface ];
          env = [
            "PATH=/run/wrappers/bin"
            "AUDIO_RECORDER_SETTINGS=${pkgs.writeText "audio-recorder-settings.py" ''
              DEVICES=[${concatMapStrings (d: "\"${escape ["\""] d}\",") cfg.devices}]
            ''}"
          ];
          socket = uwsgiSocket;
          module = "audio_recorder.web_interface";
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
            root = "${pkgs.audio-recorder.web-interface}/${pkgs.python3.sitePackages}/audio_recorder/web_interface";
            extraConfig = ''
              expires 300;
            '';
          };
        };
      };
    };
  };
}
