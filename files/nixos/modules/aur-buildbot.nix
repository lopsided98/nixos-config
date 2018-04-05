{ lib, config, pkgs, secrets, ... }: let
  internalInterfacePort = 8010; 
in {

  services.nginx = {
    enable = true;
    virtualHosts = {
      "arch.benwolsieffer.com" = {
        enableACME = true;
        forceSSL = true;
        
        basicAuthFile = secrets.getSecret secrets.aurBuildbot.htpasswd;
        
        locations = {
          "/aur-buildbot/" = {
            alias = "/var/lib/aur-buildbot/repo/";
            extraConfig = ''
              autoindex on;

              # Bypass basic auth for repo
              satisfy any;
              allow all;
            '';
          };
          "/" = {
            proxyPass = "http://127.0.0.1:${toString internalInterfacePort}";
          };
          "/sse" = {
            proxyPass = "http://127.0.0.1:${toString internalInterfacePort}/sse";
            extraConfig = ''
            proxy_buffering off;
            '';
          };

          "/ws" = {
            proxyPass = "http://127.0.0.1:${toString internalInterfacePort}/ws";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              proxy_read_timeout 6000s;
            '';
          };
        };
        extraConfig = ''
          
        '';
      };
    };
  };

  services.aur-buildbot = {
    enable = true;
    configFile = ''
      ui:
        url: https://arch.benwolsieffer.com/
        port: ${toString internalInterfacePort}
      # Repository where packages are stored
      repo:
        name: aur-buildbot
        directory: /var/lib/aur-buildbot/repo
      # Interval in seconds between package update checks
      poll_interval: 3600
      # Port for workers to connect to
      port: 7192
      email:
        from: aur-buildbot@benwolsieffer.com
        to: [ "benwolsieffer@gmail.com" ]
        smtp:
          addr: smtp.gmail.com
          port: 587
          user: benwolsieffer@gmail.com
          password: !include_text ${secrets.getSecret secrets.aurBuildbot.smtpPassword}
          use_tls: true
      workers:
        HP-Z420: !include_text ${secrets.getSecret secrets.HP-Z420.aurBuildbot.password}
      architectures:
        any:
          - HP-Z420
        x86_64:
          - HP-Z420
      packages:
        dnsupdate: {}
        dnsupdate-git: {}
        python-keras: {}
        pacaur: {}
        arm-linux-gnueabihf-gcc: {}
        redeclipse: {}
        python-scikit-image: {}
        ldcad: {}
        keepass-plugin-http: {}
        keepass-plugin-quickunlock: {}
        keepass-plugin-traytotp: {}
        qdriverstation: {}
        qdriverstation-git: {}
        zotero: {}
        solaar-git: {}
        clion: {}
        pycharm-professional: {}
        gnome-mpv: {}
        cutecom: {}
        webstorm: {}
        android-studio: {}
        android-studio-canary: {}
        ghetto-skype: {}
        genymotion: {}
        sbupdate-git: {}
        chrome-gnome-shell-git: {}
        dislocker: {}
        dmg2img: {}
        dropbox: {}
        dex2jar: {}
        lejos-nxj: {}
        eagle: {}
        python-v4l2capture: {}
        heimdall-git: {}
        grpc: {}
        jd-gui:
          dependencies: [jdk8-openjdk]
        chromium-vaapi: {}
        lcov: {}
        python-port-for: {}
        obfuscate: {}
        python-sphinx-autobuild: {}
        slapi-nis: {}  
        logisim: {}
        lib32-tk: {}
        xca: {}
    '';
  };
  
  environment.secrets =
    secrets.mkSecret secrets.HP-Z420.aurBuildbot.password {
      user = "aur-buildbot";
      group = "aur-buildbot";
      mode = "0440";
    } //
    secrets.mkSecret secrets.aurBuildbot.smtpPassword { user = "aur-buildbot"; } //
    secrets.mkSecret secrets.aurBuildbot.htpasswd { user = "nginx"; };
}
