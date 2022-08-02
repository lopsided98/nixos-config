{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.networking.wireless;
  localCfg = config.local.networking.wireless;

  units = if cfg.interfaces == []
    then [ "wpa_supplicant" ]
    else map (i: "wpa_supplicant-${i}") cfg.interfaces;
in {
  # Interface

  options.local.networking.wireless.passwordFiles = mkOption {
    type = types.listOf types.path;
    default = [];
    description = "Password files to pass to ext_password_backend";
  };

  # Implementation

  config = {
    systemd.services = listToAttrs (map (unit: nameValuePair unit {
      # /dev/null is included so this still works with no password files
      preStart = ''
        cat ${escapeShellArgs localCfg.passwordFiles} /dev/null > "$RUNTIME_DIRECTORY/passwords.conf"
      '';
    }) units);

    networking.wireless.extraConfig = ''
      ext_password_backend=file:/run/wpa_supplicant/passwords.conf
    '';

    boot.extraModprobeConfig = ''
      options cfg80211 ieee80211_regdom="US"
    '';
  };
}
