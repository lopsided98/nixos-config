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
        # Packages I maintain
        btrfs-snap: {}
        dnsupdate: {}
        dnsupdate-git: {}
        keepass-plugin-quickunlock: {}
        ldcad: {}
        obfuscate: {}
        python-nss: {}
        python-port-for: {}
        python-pynmea2: {}
        python-sphinx-argparse: {}
        python-sphinx-autobuild: {}
        qdriverstation: {}
        qdriverstation-git: {}
        slapi-nis: {}

        # Other packages
        android-studio: {}
        android-sdk-build-tools: {}
        android-sdk-platform-tools: {}
        arm-linux-gnueabihf-gcc: {}
        binfmt-qemu-static: {}
        bumblebee-git: {}
        clion: {}
        dropbox: {}
        eagle: {}
        flightgear: {}
        flightgear-data: {}
        intellij-idea-ultimate-edition: {}
        keepass-plugin-rpc: {}
        keepass-plugin-keetraytotp: {}
        lejos-nxj: {}
        nix: {}
        platformio: {}
        pycharm-professional: {}
        qemu-user-static: {}
        redeclipse: {}
        saleae-logic: {}
        sbupdate-git: {}
        webstorm: {}
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
