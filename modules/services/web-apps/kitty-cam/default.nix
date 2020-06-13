{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.kittyCam;
  uwsgiSocket = "${config.services.uwsgi.runDir}/kitty-cam.sock";
in {
  options.services.kittyCam = {
    enable = mkEnableOption "KittyCam server";

    audioDevice = mkOption {
      type = types.str;
      default = "hw:1,0";
      description = ''
        ALSA device to use for audio stream.
      '';
    };
  };

  config = mkIf cfg.enable {

    users = {
      users = {
        kitty-cam = {
          isSystemUser = true;
          description = "KittyCam user";
          group = "kitty-cam";
          extraGroups = [ "video" "audio" ];
        };
        nginx.extraGroups = [ "lirc" ];
      };
      groups.kitty-cam = {};
    };

    services.nginx = {
      enable = true;
      package = mkForce (pkgs.nginxMainline.override {
        modules = [ pkgs.nginxModules.rtmp ];
      });

      virtualHosts.kitty-cam = {
        locations = {
          "/".tryFiles = "$uri @kitty_cam";

          "@kitty_cam" = {
            extraConfig = ''
              uwsgi_pass unix:${uwsgiSocket};
            '';
          };

          "/static/".root = "${pkgs.kitty-cam}/${pkgs.python3.sitePackages}/kitty_cam";

          "/hls" = {
            root = "/run/kitty-cam";
            extraConfig = ''
              # Disable cache
              add_header Cache-Control no-cache;

              # CORS setup
              add_header 'Access-Control-Allow-Origin' '*' always;
              add_header 'Access-Control-Expose-Headers' 'Content-Length';

              # allow CORS preflight requests
              if ($request_method = 'OPTIONS') {
                add_header Cache-Control no-cache;
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain charset=UTF-8';
                add_header 'Content-Length' 0;
                return 204;
              }

              types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
              }
            '';
          };
        };
      };

      appendConfig = ''
        rtmp {
          server {
            listen 1935;

            chunk_size 4000;

            application stream {

              # enable live streaming
              live on;

              # publish only from localhost
              allow publish 127.0.0.1;
              deny publish all;

              allow play all;
            }
          }
        }
      '';
    };

    services.uwsgi = {
      enable = true;
      user = "nginx";
      group = "nginx";
      plugins = [ "python3" ];    
      instance = {
        type = "emperor";
        vassals.kitty-cam = {
          type = "normal";
          pythonPackages = self: with self; [ pkgs.kitty-cam ];
          env = [
            "KITTY_CAM_SETTINGS=${pkgs.writeText "kitty-cam-settings.py" ''
            ''}"
          ];
          socket = uwsgiSocket;
          module = "kitty_cam.controller";
          callable = "app";
          processes = 2;
          threads = 4;
        };
      };
    };

    services.udev.extraRules = ''
      KERNEL=="lirc[0-9]*", SUBSYSTEM=="lirc", OWNER="lirc", MODE="0660"
    '';

    services.lirc = {
      enable = true;
      options = ''
        [lircd]
        nodaemon = True
        device = /dev/lirc0
        pidfile = /tmp/lird.pid
      '';
      configs = [ (readFile ./lego_combo_pwm.conf) ];
    };
    systemd.services.lircd.serviceConfig.PrivateTmp = true;

    sound.enable = true;

    systemd.services.kitty-cam = {
      description = "KittyCam stream";
      after = [ "nginx.service" ];
      wantedBy = [ "nginx.service" ];
      serviceConfig = {
        Type = "exec";
        User = "kitty-cam";
        Group = "kitty-cam";
        Restart = "on-failure";
        ExecStart = pkgs.runCommand "stream-hls.sh" {
          text = ''
            #!${pkgs.stdenv.shell}
            export GST_PLUGIN_SYSTEM_PATH_1_0="@gstPluginSystemPath@"
            hls_dir=/run/kitty-cam/hls

            mkdir -p "$hls_dir"

            ${pkgs.gst_all_1.gstreamer.dev}/bin/gst-launch-1.0 \
              v4l2src ! \
              image/jpeg,width=960,height=544,framerate=30/1 !\
              jpegdec ! videoconvert !\
              v4l2h264enc extra-controls="encode,h264_i_frame_period=15,video_bitrate=3000000;" ! \
              video/x-h264,profile=high ! \
              tee name=h264_tee ! \
              h264parse config-interval=1 ! \
              flvmux name=flv_mux latency=1000000000 streamable=true ! \
              rtmpsink location='rtmp://localhost:1935/stream/stream live=1 buffer=100' \
              \
              h264_tee. ! h264parse config-interval=1 ! \
              mpegtsmux name=mpegts_mux ! \
              hlssink playlist-location="$hls_dir/stream.m3u8" location="$hls_dir/segment%05d.ts" target-duration=1 \
              \
              alsasrc device='${cfg.audioDevice}' ! \
              queue ! \
              faac ! \
              tee name=audio_tee ! \
              aacparse ! \
              audio/mpeg, mpegversion=4 ! mpegts_mux. \
              \
              audio_tee. ! aacparse ! \
              audio/mpeg, mpegversion=4 ! flv_mux.
          '';
          passAsFile = [ "text" ];
          buildInputs = with pkgs.gst_all_1; [
            gstreamer
            gst-plugins-base
            gst-plugins-good
            (gst-plugins-bad.override {
              faacSupport = true;
            })
          ];
          preferLocalBuild = true;
        } ''
          export gstPluginSystemPath="$GST_PLUGIN_SYSTEM_PATH_1_0"
          substituteAll "$textPath" "$out"
          chmod +x "$out"
        '';
        RuntimeDirectory = "kitty-cam";
        RuntimeDirectoryMode = "0755";
      };
    };
  };
}
