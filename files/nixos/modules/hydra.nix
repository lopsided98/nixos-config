{ config, lib, pkgs, ... }:

{

  services.hydra = {
    enable = true;
    hydraURL = "http://hydra.benwolsieffer.com";
    notificationSender = "hydra@benwolsieffer.com";
    smtpHost = "smtp.gmail.com";
    extraEnv = {
      EMAIL_SENDER_TRANSPORT_port = "465";
      EMAIL_SENDER_TRANSPORT_ssl = "ssl";
      EMAIL_SENDER_TRANSPORT_sasl_username = "benwolsieffer@gmail.com";
      EMAIL_SENDER_TRANSPORT_sasl_password = "zfzrmrfpzzshhvpc";
    };
    port = 8080;
    extraConfig = ''
      store_uri = file:///var/lib/hydra/cache?secret-key=/var/lib/hydra/nix-cache.benwolsieffer.com-1
    '';
    buildMachinesFiles = [ "/etc/nix/machines" ];
  };
  services.postgresql = {
    package = pkgs.postgresql96;
    dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
  };
  networking.firewall.allowedTCPPorts = [ config.services.hydra.port ];
  
  # Use ARM binary cache
  nix.binaryCaches = lib.mkForce [ "http://nixos-arm.dezgeg.me/channel" ];
  nix.binaryCachePublicKeys = [ "nixos-arm.dezgeg.me-1:xBaUKS3n17BZPKeyxL4JfbTqECsT+ysbDJz29kLFRW0=%" ];

}
