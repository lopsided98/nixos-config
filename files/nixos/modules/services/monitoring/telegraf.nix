{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.telegraf-fixed;

  recursiveAttrs = mkOption {
    default = {};
    type = types.nullOr (types.attrs // {
      merge = loc: foldl' (res: def: recursiveUpdate res def.value) {};
    });
  };

  optionString = name: value: optionalString (value != null) ''"name": "${value}"'';

  configFileJSON = pkgs.writeText "config.json" ''
    {
      "global_tags": {
        ${concatStringsSep (mapAttrsToList optionString cfg.globalTags)}
      },
      "agent": ${builtins.toJSON cfg.agent},
      "aggregators": ${builtins.toJSON cfg.aggregators},
      "inputs": ${builtins.toJSON cfg.inputs},
      "outputs": ${builtins.toJSON cfg.outputs},
      "processors": ${builtins.toJSON cfg.processors}
    }
  '';

  configFile = pkgs.runCommand "config.toml" {
    buildInputs = [ pkgs.remarshal ];
  } ''
    remarshal -if json -of toml \
      < "${configFileJSON}" \
      > "$out"
  '';
in {
  ###### interface
  options = {
    services.telegraf-fixed = {
      enable = mkEnableOption "telegraf server";

      package = mkOption {
        default = pkgs.telegraf;
        defaultText = "pkgs.telegraf";
        description = "Which telegraf derivation to use";
        type = types.package;
      };

      globalTags = mkOption {
        default = {};
        description = "Global tags for all outputs";
        type = types.attrsOf types.str;
      };

      agent = recursiveAttrs;
      aggregators = recursiveAttrs;
      inputs = recursiveAttrs;
      outputs = recursiveAttrs;
      processors = recursiveAttrs;
    };
  };


  ###### implementation
  config = mkIf config.services.telegraf-fixed.enable {
    systemd.services.telegraf = {
      description = "Telegraf Agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        ExecStart=''${cfg.package}/bin/telegraf -config "${configFile}"'';
        ExecReload="${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        User = "telegraf";
        Restart = "on-failure";
      };
    };

    users.extraUsers = [{
      name = "telegraf";
      uid = config.ids.uids.telegraf;
      description = "telegraf daemon user";
    }];
  };
}
