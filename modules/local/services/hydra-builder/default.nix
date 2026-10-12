{ config, lib, pkgs, secrets, ... }:

let
  cfg = config.local.services.hydra-builder;
in {
  options.local.services.hydra-builder = {
    enable = lib.mkEnableOption "hydra.benwolsieffer.com builder";

    mtlsClientCertPath = lib.mkOption {
      type = lib.types.path;
      description = "mTLS client certificate path";
    };

    mtlsClientKeySecret = lib.mkOption {
      type = lib.types.str;
      description = "mTLS client private key secret";
    };
  };

  config = lib.mkIf cfg.enable {
    services.hydra-builder = {
      enable = true;
      package = pkgs.hydra-builder.overrideAttrs ({ patches ? [], ... }:{
        patches = patches ++ [
          ./0001-hydra-builder-always-run-build-locally.patch
        ];
      });
      queueRunnerAddr = "https://hydra.benwolsieffer.com:50051";

      mtls = {
        serverRootCaCertPath = ../../../config/hydra/queue-runner-ca.crt;
        clientCertPath = cfg.mtlsClientCertPath;
        clientKeyPath = secrets.getSystemdSecret "hydra-builder" cfg.mtlsClientKeySecret;
        domainName = "hydra.benwolsieffer.com";
      };
    };

    systemd.secrets.hydra-builder = {
      units = [ "hydra-builder.service" ];
      files = secrets.mkSecret cfg.mtlsClientKeySecret {
        user = "hydra-builder";
        group = "hydra";
      };
    };
  };
}
