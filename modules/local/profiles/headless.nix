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

    nixpkgs.overlays = singleton (const (super: {
      gnupg = super.gnupg.override { guiSupport = false; };
      qt515 = super.qt515.overrideScope' (const (super: {
        # Build Qt without Gtk. The other GUI deps can't be disabled right now.
        qtbase = super.qtbase.override {
          withGtk3 = false;
        };
      }));
      v4l-utils = super.v4l-utils.override { withGUI = false; };
    }));
  };
}
