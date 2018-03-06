{ lib, config, pkgs, ... }: let
  internalInterfacePort = 8010; 
in {

  services.nginx = {
    enable = true;
    virtualHosts = {
      "arch.benwolsieffer.com" = {
        enableACME = true;
        forceSSL = true;
        
        basicAuth = {
          "aur-buildbot" = "Nb7fDr5NyfUnzWpPndGdIO3mWXAgarfoSU43IPzv";
        };
        
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
          password: "rogkzzbgkneihqaz"
          use_tls: true
      workers:
        HP-Z420: "IccOWW6tkOlGXhT2nmFfi8XbajMI2DzA7Gqqq1pn"
        Dell-Optiplex-780: "VKK4scBAqYuRmtuDUXZDz0E65voAOaj31UIoLH7t"
        ODROID-XU4: "xZdKI5whiX5MNSfWcAJ799Krhq5BZhfe11zBdamx"
      architectures:
        any:
          - HP-Z420
          - Dell-Optiplex-780
        x86_64:
          - HP-Z420
          - Dell-Optiplex-780
        armv7h:
          - ODROID-XU4
      packages:
        buildbot: {}
        python3-aur: {}
        dnsupdate: {}
        dnsupdate-git: {}
        python-keras: {}
        google-chrome: {}
        telegraf: {}
        tinyssh-convert: {}
        mkinitcpio-netconf: {}
        mkinitcpio-tinyssh: {}
        mkinitcpio-utils: {}
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
        solaar: {}
        clion: {}
        pycharm-professional: {}
        gnome-mpv: {}
        cutecom: {}
        webstorm: {}
        android-studio: {}
        android-studio-canary: {}
        ghetto-skype: {}
        genymotion: {}
        influxdb: {}
        ucspi-tcp: 
          architectures: [armv7h]
        python-wakeonlan: {}
        sanoid-git: {}
        ovpngen: {}
        sbupdate-git: {}
        libvirt-zfs: {}
        chrome-gnome-shell-git: {}
        dislocker: {}
        dmg2img: {}
        dropbox: {}
        dex2jar: {}
        lejos-nxj: {}
        eagle: {}
        python-v4l2capture:
          architectures: [armv7h]
        heimdall-git: {}
        grpc:
          architectures: [armv7h]
        jd-gui:
          dependencies: [jdk8-openjdk]
        chromium-vaapi: {}
        lcov: {}
        btrfs-snap: {}
        python-nss: {}
        python-port-for: {}
        obfuscate: {}
        python-sphinx-autobuild: {}
        slapi-nis: {}  
        logisim: {}
        lib32-tk: {}
    '';
  };
}
