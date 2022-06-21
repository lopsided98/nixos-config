{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.buildMachines;
  
  buildMachine = hostName: machine:
    "${if machine.sshUser != null then "${machine.sshUser}@" else ""}${hostName} "
    + machine.system or (concatStringsSep "," machine.systems)
    + " ${machine.sshKey} ${toString machine.maxJobs} "
    + toString machine.speedFactor
    + " "
    + concatStringsSep "," (machine.mandatoryFeatures ++ machine.supportedFeatures)
    + " "
    + concatStringsSep "," machine.mandatoryFeatures
    + "\n";

  hostName = config.networking.hostName;
in {
  options = {
    system.buildMachines = mkOption {
      description = ''
        Build machines used for distributed builds and Hydra, working around 
        bugs in each.
      '';
      default = {};
      type = types.attrsOf (types.submodule {
        options = {
          sshUser = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          sshKey = mkOption {
            type = types.str;
            default = "-";
          };
          systems = mkOption {
            type = types.listOf types.str;
            default = [ "x86_64-linux" ];
          };
          maxJobs = mkOption {
            type = types.ints.unsigned;
            default = 1;
          };
          speedFactor = mkOption {
            type = types.ints.unsigned;
            default = 1;
          };
          supportedFeatures = mkOption {
            type = types.listOf types.str;
            default = [];
          };
          mandatoryFeatures = mkOption {
            type = types.listOf types.str;
            default = [];
          };
        };
      });
    };
  };

  config = mkIf (cfg != {}) {
    nix.buildMachines = mapAttrsToList (hostName: m:
      (if m.sshUser != null then { inherit (m) sshUser; } else {}) // {
        inherit hostName;
        inherit (m)
          sshKey
          systems
          maxJobs
          speedFactor
          supportedFeatures
          mandatoryFeatures;
      }) (filterAttrs (h: m: h != hostName) cfg);
    # Include a second machine file with the configuration for the local machine
    services.hydra.buildMachinesFiles = [
      "/etc/nix/machines"
      (pkgs.writeText "hydra-localhost-build" (buildMachine "localhost" (cfg.${hostName} // { sshUser = null; })))
    ];
  };
}
