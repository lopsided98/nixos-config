{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.system.buildMachines;
in
{
  options = {
    system.buildMachines = lib.mkOption {
      description = ''
        Build machines used for distributed builds and Hydra
      '';
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            sshUser = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            sshKey = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            systems = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "x86_64-linux" ];
            };
            maxJobs = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 1;
            };
            speedFactor = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 1;
            };
            supportedFeatures = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
            mandatoryFeatures = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        }
      );
    };
  };

  config = {
    nix.buildMachines = lib.mapAttrsToList (
      hostName: m:
      {
        inherit hostName;
        inherit (m)
          sshUser
          sshKey
          systems
          maxJobs
          speedFactor
          supportedFeatures
          mandatoryFeatures
          ;
        protocol = "ssh-ng";
      }
    ) (lib.filterAttrs (h: m: h != config.networking.hostName) cfg);
  };
}
