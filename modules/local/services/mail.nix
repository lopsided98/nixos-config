{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.services.mail;
  nullmailerCfg = config.services.nullmailer;
  
  sendmail = pkgs.writeScriptBin "sendmail" ''
    #!${pkgs.runtimeShell}
    exec /run/wrappers/bin/sudo -nu '${nullmailerCfg.user}' '${pkgs.nullmailer}/bin/sendmail' "$@"
  '';
in {
  options.local.services.mail = {
    enable = mkEnableOption "email sending";
    
    sendmail = mkOption {
      type = types.path;
      readOnly = true;
      description = "Path to wrapped sendmail binary";
    };
  };

  config = mkIf cfg.enable {
    local.services.mail.sendmail = "${sendmail}/bin/sendmail";

    services.nullmailer = {
      enable = true;
      remotesFile = secrets.getSecret secrets.nullmailer.gmailRemote;
      # I use sudo and a wrapper script to only allow the sendmail group to
      # send email.
      setSendmail = false;
    };

    environment.secrets = secrets.mkSecret secrets.nullmailer.gmailRemote {
      inherit (nullmailerCfg) user group;
    };

    environment.systemPackages = [ sendmail ];

    users.groups.sendmail = {};

    security.sudo = {
      enable = true;
      extraConfig = ''
        %sendmail ALL=(${nullmailerCfg.user}) NOPASSWD: ${pkgs.nullmailer}/bin/sendmail *
      '';
    };
  };
}
