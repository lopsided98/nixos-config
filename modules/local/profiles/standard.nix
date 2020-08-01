{ config, lib, pkgs, ... }:
with lib;
{
  options = {
    local.profiles.standard = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Enable features common to most machines, except those designed to be as
        small as possible.
      '';
    };
  };

  config = mkIf config.local.profiles.standard {
    # Standard set of packages
    environment.systemPackages = with pkgs; [
      linuxPackages_latest.tmon
      bmon
      git
      file
      vim
    ];
  };
}
