{ config, lib, pkgs, secrets, ... }: with lib; {

  services.hydra = {
    enable = true;
    package = pkgs.hydra-unstable.overrideAttrs ({ patches ? [], ... }: {
      patches = patches ++ [
        # Fix queue getting stuck
        (pkgs.fetchpatch {
          url = "https://github.com/lopsided98/hydra/commit/1f047a5dd3e16c21e14ea9130a8c8fbfd485e5a9.patch";
          sha256 = "1pmiy702rvcil97qlldmcyahv3438anis3kwrgjlpp4h5nx5z4g1";
        })
        # Fix incompatibility with builders running Nix unstable
        # https://github.com/NixOS/hydra/pull/914
        (pkgs.fetchpatch {
          url = "https://github.com/NixOS/hydra/commit/0bee194ce9bcc0c88991ed72a60c13d13a0bfdab.patch";
          sha256 = "sha256-lMcQ+81dBHl4Nn04klVJIjzSt5ksQJZyKCHl/v8+y3w=";
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

  nix = {
    # hydra-queue-runner gets stuck running localhost builds unless unstable Nix
    # daemon is used
    package = pkgs.nixFlakes;
    extraOptions = ''
      # Allow Hydra to build flakes
      experimental-features = nix-command flakes
      # Allow Hydra to access SSH URIs in flakes (I think this is a Nix bug)
      allowed-uris = ssh://
    '';
  };

  # Deploy keys for private repositories
  programs.ssh.extraConfig = ''
    Host gitlab.com
      IdentityFile ${secrets.getSystemdSecret "hydra" secrets.hydra.ssh.gitlab}
  '';

  # Automatically select the right deploy key for SSH access to different GitHub
  # repositories
  systemd.services.hydra-evaluator.environment.GIT_SSH = pkgs.writers.writePython3 "git-ssh-identity.py" {
    # Ignore "line too long"
    flakeIgnore  = [ "E501" ];
  } ''
    import sys
    import os
    import re

    SSH_EXECUTABLE = '${pkgs.openssh}/bin/ssh'

    KEY_MAP = {
        'git@github.com/lopsided98/nixos-config-secrets.git': '${secrets.getSystemdSecret "hydra" secrets.hydra.ssh.githubNixosConfigSecrets}',
        'git@github.com/lopsided98/freefb.git': '${secrets.getSystemdSecret "hydra" secrets.hydra.ssh.githubFreefb}',
    }

    host = sys.argv[-2]
    command_match = re.match(r'([^ ]+)[ ]+[\']([^\']*)[\']', sys.argv[-1])

    key_args = []
    if command_match:
        path = command_match.group(2)
        key = KEY_MAP.get(host + path)
        if key is not None:
            key_args = ['-i', key]

    os.execv(SSH_EXECUTABLE, [SSH_EXECUTABLE] + key_args + sys.argv[1:])
  '';

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
  # Allow access to cache directory
  systemd.services.nginx.serviceConfig.ReadWritePaths = [ "/var/cache/hydra" ];

  systemd.secrets = {
    nix = {
      units = [ "hydra-queue-runner.service" ];
      files."${secrets.build.sshKey}" = {
        user = "hydra-queue-runner";
        group = "hydra";
      };
    };
    hydra = {
      units = [
        "nginx.service"
        "hydra-server.service"
        "hydra-evaluator.service"
        "hydra-queue-runner.service"
      ];
      files = mkMerge [
        (secrets.mkSecret secrets.hydra.htpasswd { user = "nginx"; })
        (secrets.mkSecret secrets.hydra.binaryCacheSecretKey { user = "hydra-www"; })
        # SSH deploy keys
        (secrets.mkSecret secrets.hydra.ssh.gitlab { user = "hydra"; })
        (secrets.mkSecret secrets.hydra.ssh.githubNixosConfigSecrets { user = "hydra"; })
        (secrets.mkSecret secrets.hydra.ssh.githubFreefb { user = "hydra"; })
      ];
    };
  };
}
