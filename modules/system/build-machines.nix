{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.system.buildMachines;

  hydraBuildMachinesText = lib.concatStrings (lib.mapAttrsToList (
    origHostName: machine:
    let
      localhost = origHostName == config.networking.hostName;
      hostName = if localhost then "localhost" else origHostName;
      # Hydra doesn't support ssh-ng
      # https://github.com/NixOS/hydra/issues/688
      protocol = if localhost then null else "ssh";
      sshUser = if localhost then null else machine.sshUser;
    in
    (lib.concatStringsSep " " ([
      "${lib.optionalString (protocol != null) "${protocol}://"}${
        lib.optionalString (sshUser != null) "${sshUser}@"
      }${hostName}"
      (
        if machine.systems != [ ] then
          lib.concatStringsSep "," machine.systems
        else
          "-"
      )
      (if machine.sshKey != null then machine.sshKey else "-")
      (toString machine.maxJobs)
      (toString machine.speedFactor)
      (
        let
          res = (machine.supportedFeatures ++ machine.mandatoryFeatures);
        in
        if (res == [ ]) then "-" else (lib.concatStringsSep "," res)
      )
      (
        let
          res = machine.mandatoryFeatures;
        in
        if (res == [ ]) then "-" else (lib.concatStringsSep "," machine.mandatoryFeatures)
      )
      "-"
    ]))
    + "\n"
  ) cfg);
in
{
  options = {
    system.buildMachines = lib.mkOption {
      description = ''
        Build machines used for distributed builds and Hydra, working around 
        bugs in each.
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

    # Include a second machine file with the configuration for the local machine
    services.hydra.buildMachinesFiles = [
      (pkgs.writeText "hydra-build-machines" hydraBuildMachinesText)
    ];
  };
}
