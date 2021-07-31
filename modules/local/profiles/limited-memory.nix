{ config, lib, pkgs, ... }:
with lib;
{
  options = {
    local.profiles.limitedMemory = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Further stripping down to save memory on devices with very little RAM
        (<128 MB). 32 MB is probably a low as you can usefully go with this
        profile.
      '';
    };
  };

  config = mkIf config.local.profiles.limitedMemory {
    local.profiles.minimal = mkDefault true;

    # Disable uncessary systemd components
    # Override mkDefault in nixpkgs networkd config
    services.resolved.enable = mkOverride 900 false;
  };
}
