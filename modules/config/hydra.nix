{ config, lib, pkgs, secrets, ... }: {

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

  environment.secrets = {
    "${secrets.build.sshKey}" = {
      user = "hydra-queue-runner";
      group = "hydra";
      mode = "0400";
    };
  } // secrets.mkSecret secrets.hydra.htpasswd { user = "nginx"; }
    // secrets.mkSecret secrets.hydra.binaryCacheSecretKey { user = "hydra-server"; };
}
