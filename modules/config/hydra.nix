{ config, lib, pkgs, secrets, ... }: with lib; let
  nixFlakes = pkgs.nixFlakes.overrideAttrs ({ patches ? [], ... }: {
    patches = patches ++ [
      # Fix bugs in unstable Nix
      (pkgs.fetchpatch {
        url = "https://github.com/NixOS/nix/commit/525b38eee8fac48eb2a82fb78fa0a933a9eee2a4.patch";
        sha256 = "sha256-58MAq5zyCIGRd2P6p0ydpfpxZDULKanVpzMsNYKz6IM=";
      })
      (pkgs.fetchpatch {
        url = "https://github.com/NixOS/nix/commit/8dbd57a6a5fe497bde9e647a3249c1ce0ea121ab.patch";
        sha256 = "sha256-AsjV8sya/pk927SK2DWMeF4vgt2fRKjSerdB8bRhMB8=";
      })
    ];
  });
in {

  services.hydra = {
    enable = true;
    package = (pkgs.hydra-unstable.override (old: {
      nix = nixFlakes;
    })).overrideAttrs ({ patches ? [], ... }: {
      patches = patches ++ [
        # Fix queue getting stuck
        (pkgs.fetchpatch {
          url = "https://github.com/lopsided98/hydra/commit/1f047a5dd3e16c21e14ea9130a8c8fbfd485e5a9.patch";
          sha256 = "1pmiy702rvcil97qlldmcyahv3438anis3kwrgjlpp4h5nx5z4g1";
        })
      ];
    });
    hydraURL = "https://hydra.benwolsieffer.com";
    notificationSender = "hydra@hydra.benwolsieffer.com";
    port = 8080;
    extraConfig = ''
      store_uri = daemon?secret-key=${secrets.getSystemdSecret "hydra" secrets.hydra.binaryCacheSecretKey}
      binary_cache_secret_key_file=${secrets.getSystemdSecret "hydra" secrets.hydra.binaryCacheSecretKey}
    '';
    useSubstitutes = true;
  };

  services.postgresql = {
    package = pkgs.postgresql_11;
    dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
    settings = {
      max_connections = 250;
      work_mem = "8MB";
      shared_buffers = "512MB";
    };
  };

  # hydra-queue-runner gets stuck running localhost builds unless unstable Nix
  # daemon is used
  nix.package = nixFlakes;

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

        basicAuthFile = secrets.getSystemdSecret "hydra" secrets.hydra.htpasswd;

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
    machine = m: { sshKey = secrets.getSystemdSecret "nix" secrets.build.sshKey; } // m;
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

  systemd.secrets = {
    nix = {
      units = [ "hydra-queue-runner.service" ];
      files."${secrets.build.sshKey}" = {
        user = "hydra-queue-runner";
        group = "hydra";
      };
    };
    hydra = {
      units = [ "nginx.service" "hydra-server.service" "hydra-queue-runner.service" ];
      files = mkMerge [
        (secrets.mkSecret secrets.hydra.htpasswd { user = "nginx"; })
        (secrets.mkSecret secrets.hydra.binaryCacheSecretKey { user = "hydra-www"; })
        (secrets.mkSecret secrets.hydra.thayerServerPassword { user = "hydra-queue-runner"; })
      ];
    };
  };
}
