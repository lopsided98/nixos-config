# Module to work around the bad design of the nixpkgs.{local,cross}System
# options.
{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.system;
in {
  # Interface

  options.local.system = {
    hostSystem = mkOption {
      type = types.attrs;
      description = ''
        Host system for NixOS. Defaults to the system running the evaluation.
      '';
    };

    buildSystem = mkOption {
      type = types.attrs;
      description = ''
        Build system for NixOS. Defaults to the host system.
      '';
    };
  };

  # Implementation

  config = {
    local.system = {
      hostSystem = mkDefault { system = builtins.currentSystem; };
      buildSystem = mkDefault cfg.hostSystem;
    };
    nixpkgs = {
      localSystem = if cfg.hostSystem != cfg.buildSystem then cfg.buildSystem else cfg.hostSystem;
      crossSystem = mkIf (cfg.hostSystem != cfg.buildSystem) cfg.hostSystem;
    };
  };
}
