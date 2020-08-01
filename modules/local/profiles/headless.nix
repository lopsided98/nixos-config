{ config, lib, pkgs, ... }:
with lib;
{
  options = {
    local.profiles.headless = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Disable modules and package features not needed on headless systems.
      '';
    };
  };

  config = mkIf config.local.profiles.headless {
    environment.noXlibs = true;
  };
}
