{ config, lib, pkgs, secrets, ... }: with lib; {

  services.hydra = {
    enable = true;
    hydraURL = "https://hydra.benwolsieffer.com";
    notificationSender = "hydra@hydra.benwolsieffer.com";
    port = 8080;
    extraConfig = ''
      store_uri = daemon?secret-key=${secrets.getSecret secrets.hydra.binaryCacheSecretKey}
      binary_cache_secret_key_file=${secrets.getSecret secrets.hydra.binaryCacheSecretKey}
    '';
    useSubstitutes = true;
  };

  # Thayer sysadmins decided pubkey auth was too secure/convenient, so we need
  # this hack to supply the password
  systemd.services = let
    sshpass-wrapper = pkgs.writeScriptBin "ssh" ''
      #!${pkgs.stdenv.shell}
      '${pkgs.sshpass}/bin/sshpass' -f '${secrets.getSecret secrets.hydra.thayerServerPassword}' '${pkgs.openssh}/bin/ssh' -oBatchMode=no "$@"
    '';
  in {
    hydra-queue-runner.path = mkBefore [ sshpass-wrapper ];
    nix-daemon.path = mkBefore [ sshpass-wrapper ];
  };

  services.postgresql = {
    package = pkgs.postgresql96;
    dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
    extraConfig = ''
      max_connections = 250
      work_mem = 8MB
      shared_buffers = 512MB
    '';
  };

  # Serve binary cache
  services.nginx = {
    enable = true;

    appendHttpConfig = ''
      proxy_cache_path /var/cache/hydra levels=1:2 keys_zone=hydra:10m max_size=10g
                       inactive=1w use_temp_path=off;
    '';

    virtualHosts = {
      "hydra.benwolsieffer.com" = let
        proxyPass = "http://127.0.0.1:${toString config.services.hydra.port}";
        cacheConfig = ''
          proxy_cache hydra;
          add_header X-Cache $upstream_cache_status;
        '';
      in {
        enableACME = true;
        forceSSL = true;

        basicAuthFile = secrets.getSecret secrets.hydra.htpasswd;

        locations = {
          "/" = {
            inherit proxyPass;
          };
          "/nar/" = {
            inherit proxyPass;
            extraConfig = cacheConfig;
          };
          "~* \.narinfo$" = {
            inherit proxyPass;
            extraConfig = cacheConfig;
          };
          "~* ^/build/\d+/download/" = {
            inherit proxyPass;
            extraConfig = cacheConfig;
          };
          "= /nix-cache-info" = {
            inherit proxyPass;
            extraConfig = ''
              satisfy any;
              allow all;
            '';
          };
          "/log/" = {
            inherit proxyPass;
            extraConfig = ''
              # Allow access from local network without password
              satisfy any;
              allow 192.168.1.0/24;
              allow 2601:18a:0:7723::/64;
              deny all;
            '';
          };
        };
        extraConfig = ''
          proxy_force_ranges on;
          # Would be necessary if Hydra supported range requests; in any case it
          # doesn't hurt.
          proxy_http_version 1.1;
          proxy_cache_valid 1w;
          # Ignore cache headers from Hydra; they cause caching of error
          # responses
          proxy_ignore_headers Expires Cache-Control;
        '';
      };
    };
  };

  # Only use these builders on the Hydra machine because they require special
  # network configuration.
  system.buildMachines = let
    machine = m: { sshKey = secrets.getSecret secrets.build.sshKey; } // m;
  in {
    /*"babylon1" = machine {
      systems = [ "x86_64-linux" ];
      maxJobs = 12;
      speedFactor = 20;
      supportedFeatures = [ "big-parallel" ];
      sshUser = "f002w9k";
    };
    "babylon2" = machine {
      systems = [ "x86_64-linux" ];
      maxJobs = 12;
      speedFactor = 20;
      supportedFeatures = [ "big-parallel" ];
      sshUser = "f002w9k";
    };
    "babylon3" = machine {
      systems = [ "x86_64-linux" ];
      maxJobs = 12;
      speedFactor = 20;
      supportedFeatures = [ "big-parallel" ];
      sshUser = "f002w9k";
    };
    "babylon4" = machine {
      systems = [ "x86_64-linux" ];
      maxJobs = 12;
      speedFactor = 20;
      supportedFeatures = [ "big-parallel" ];
      sshUser = "f002w9k";
    };
    "babylon5" = machine {
      systems = [ "x86_64-linux" ];
      maxJobs = 6;
      speedFactor = 10;
      supportedFeatures = [ "big-parallel" ];
      sshUser = "f002w9k";
    };
    "babylon6" = machine {
      systems = [ "x86_64-linux" ];
      maxJobs = 6;
      speedFactor = 10;
      supportedFeatures = [ "big-parallel" ];
      sshUser = "f002w9k";
    };
    "babylon7" = machine {
      systems = [ "x86_64-linux" ];
      maxJobs = 6;
      speedFactor = 10;
      supportedFeatures = [ "big-parallel" ];
      sshUser = "f002w9k";
    };
    "babylon8" = machine {
      systems = [ "x86_64-linux" ];
      maxJobs = 6;
      speedFactor = 10;
      supportedFeatures = [ "big-parallel" ];
      sshUser = "f002w9k";
    };
    "bear" = machine {
      systems = [ "x86_64-linux" ];
      maxJobs = 6;
      speedFactor = 8;
      supportedFeatures = [ "big-parallel" ];
      sshUser = "benwolsieffer";
    };
    "flume" = machine {
      systems = [ "x86_64-linux" ];
      maxJobs = 10;
      speedFactor = 12;
      supportedFeatures = [ "big-parallel" ];
      sshUser = "benwolsieffer";
    };
    "tahoe" = machine {
      systems = [ "x86_64-linux" ];
      maxJobs = 6;
      speedFactor = 8;
      supportedFeatures = [ "big-parallel" ];
      sshUser = "benwolsieffer";
    };*/
  };

  environment.secrets = {
    "${secrets.build.sshKey}" = {
      user = "hydra-queue-runner";
      group = "hydra";
    };
  } // secrets.mkSecret secrets.hydra.htpasswd { user = "nginx"; }
    // secrets.mkSecret secrets.hydra.binaryCacheSecretKey { user = "hydra-www"; }
    // secrets.mkSecret secrets.hydra.thayerServerPassword { user = "hydra-queue-runner"; };
}
