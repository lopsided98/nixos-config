{ config, lib, pkgs, secrets, inputs, ... }: with lib; {

  services.hydra = {
    enable = true;
    hydraURL = "https://hydra.benwolsieffer.com";
    notificationSender = "hydra@hydra.benwolsieffer.com";
    port = 8080;
    extraConfig = ''
      store_uri = daemon?secret-key=${secrets.getSystemdSecret "hydra" secrets.hydra.binaryCacheSecretKey}
      binary_cache_secret_key_file=${secrets.getSystemdSecret "hydra" secrets.hydra.binaryCacheSecretKey}
      # Prevent: "Use of uninitialized value $numThreads in numeric gt (>)"
      compress_num_threads = 0
    '';
    useSubstitutes = true;
  };

  # ZFS dataset properties:
  # atime=off
  # compression=zstd
  # recordsize=16K
  services.postgresql = {
    package = pkgs.postgresql_17;
    dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
    settings = {
      max_connections = 250;
      work_mem = "8MB";
      shared_buffers = "4GB";
      # ZFS ARC defaults to 50% of RAM
      effective_cache_size = "64GB";
      # ZFS writes are atomic, so this is unnecessary
      # See: https://wiki.postgresql.org/wiki/Full_page_writes
      full_page_writes = "off";
      # Useless with CoW
      wal_init_zero = "off";
      wal_recycle = "off";
    };
  };

  # Allow Hydra to access flake inputs
  nix.settings.allowed-uris = "git+ssh:// http:// https:// github:";

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
          proxy_cache_valid 1w;
          # Ignore cache headers from Hydra; they cause caching of error
          # responses
          proxy_ignore_headers Expires Cache-Control;
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
          };
        };
        extraConfig = ''
          proxy_force_ranges on;
          # Would be necessary if Hydra supported range requests; in any case it
          # doesn't hurt.
          proxy_http_version 1.1;
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
