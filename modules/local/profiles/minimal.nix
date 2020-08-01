{ config, lib, pkgs, ... }:
with lib;
{
  options = {
    local.profiles.minimal = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Strip down NixOS as much as possible.
      '';
    };
  };

  config = mkIf config.local.profiles.minimal {
    local.profiles.headless = mkDefault true;
    local.profiles.standard = mkDefault false;
    boot.enableContainers = mkDefault false;
    security.polkit.enable = mkDefault false;
    services.udisks2.enable = mkDefault false;
    documentation.enable = mkDefault false;
    programs.command-not-found.enable = mkDefault false;
    xdg.mime.enable = mkDefault false;
    i18n.supportedLocales = mkDefault [ "en_US.UTF-8/UTF-8" ];

    nixpkgs.overlays = singleton (const (super: {
      nix = super.nix.override { withAWS = false; };
      # Prevent building two versions of glibcLocales
      glibcLocales = super.glibcLocales.override {
        allLocales = false;
        locales = config.i18n.supportedLocales;
      };
    }));
  };
}