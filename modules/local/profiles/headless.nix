{ config, lib, pkgs, ... }: {
  options = {
    local.profiles.headless = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = ''
        Disable modules and package features not needed on headless systems.
      '';
    };
  };

  config = lib.mkIf config.local.profiles.headless {
    # Unnecessary, and pulls in X11 libraries through xauth
    security.pam.services.su.forwardXAuth = lib.mkForce false;

    nixpkgs.overlays = lib.singleton (final: prev: {
      dbus = prev.dbus.override { x11Support = false; };
      gnupg = prev.gnupg.override { guiSupport = false; };
      qt515 = prev.qt515.overrideScope' (final: prev: {
        # Build Qt without Gtk. The other GUI deps can't be disabled right now.
        qtbase = prev.qtbase.override {
          withGtk3 = false;
        };
      });
      v4l-utils = prev.v4l-utils.override { withGUI = false; };

      gst_all_1 = prev.gst_all_1 // {
        gst-plugins-base = prev.gst_all_1.gst-plugins-base.override {
          enableX11 = false;
          enableWayland = false;
          enableGl = false;
        };
      };
    });
  };
}
