{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.sources;
in {
  # Interface

  options.local.sources = {
    nixpkgs = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to install nixpkgs sources on the machine and add them to
          NIX_PATH.
        '';
      };

      source = mkOption {
        type = types.path;
        description = ''
          Source path for nixpkgs. Can be a store path or an impure local path.
        '';
      };
    };

    localpkgs = {
      enable = mkOption {
        type = types.bool;
        description = ''
          Whether to install localpkgs (the repo containing this file) sources
          on the machine and add them to NIX_PATH. This also sets appropriate
          values for 'nixos-config' and 'nixpkgs-overlays'.
        '';
      };

      source = mkOption {
        type = types.path;
        default = "/etc/nixos";
        description = ''
          Source path for localpkgs. Can be a store path or an impure local
          path.
        '';
      };

      machineName = mkOption {
        type = types.str;
        description = ''
          Name of the machine directory in localpkgs. Defaults to the hostname.
        '';
      };
    };
  };

  # Implementation

  config = {
    local.sources = {
      nixpkgs.source = mkDefault (lib.cleanSource pkgs.path);
      localpkgs = {
        enable = mkDefault cfg.nixpkgs.enable;
        machineName = mkDefault config.networking.hostName;
      };
    };

    nix.nixPath = 
      optional cfg.nixpkgs.enable "nixpkgs=${cfg.nixpkgs.source}" ++
      optionals cfg.localpkgs.enable [
        "localpkgs=${cfg.localpkgs.source}"
        "nixos-config=${cfg.localpkgs.source}/machines/${cfg.localpkgs.machineName}"
        "nixpkgs-overlays=${cfg.localpkgs.source}/overlays"
      ];
  };
}
