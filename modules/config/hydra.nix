{ config, lib, pkgs, secrets, ... }: {

  services.hydra = {
    enable = true;
    hydraURL = "http://hydra.benwolsieffer.com";
    notificationSender = "hydra@benwolsieffer.com";
    #smtpHost = "smtp.gmail.com";
    #extraEnv = {
    #  EMAIL_SENDER_TRANSPORT_port = "465";
    #  EMAIL_SENDER_TRANSPORT_ssl = "ssl";
    #  EMAIL_SENDER_TRANSPORT_sasl_username = "benwolsieffer@gmail.com";
    #  EMAIL_SENDER_TRANSPORT_sasl_password = ""; # Previous password was revoked
    #};
    port = 8080;
    extraConfig = ''
      store_uri = daemon?secret-key=/var/lib/hydra/nix-cache.benwolsieffer.com-1
      binary_cache_secret_key_file=/var/lib/hydra/nix-cache.benwolsieffer.com-1
    '';
    useSubstitutes = true;
  };

  services.postgresql = {
    package = pkgs.postgresql96;
    dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
  };

  # Use ARM binary cache
  # Currently broken
  # nix.binaryCaches = [ "http://nixos-arm.dezgeg.me/channel" ];
  nix.binaryCachePublicKeys = [ "nixos-arm.dezgeg.me-1:xBaUKS3n17BZPKeyxL4JfbTqECsT+ysbDJz29kLFRW0=%" ];

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
      in {
        enableACME = true;
        forceSSL = true;

        basicAuthFile = secrets.getSecret secrets.hydra.htpasswd;

        locations = {
          "/" = {
            inherit proxyPass;
          };
          "~* \.nar(info|\.xz)$" = {
            inherit proxyPass;
            extraConfig = ''
              proxy_cache hydra;

              add_header X-Cache $upstream_cache_status;

              # Allow access from local network without password
              satisfy any;
              allow 192.168.1.0/24;
              allow 2601:18a:0:7829::/64;
              deny all;
            '';
          };
        };
        extraConfig = ''
          proxy_cache_valid 200 1w;
          proxy_ignore_headers Set-Cookie;
        '';
      };
    };
  };

  environment.secrets = {
    "${secrets.build.sshKey}" = {
      group = "hydra";
      mode = "0440";
    };
  } // secrets.mkSecret secrets.hydra.htpasswd { user = "nginx"; };
}
