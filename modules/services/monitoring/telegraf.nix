{ config, lib, ... }: with lib; let
  cfg = config.services.telegraf;

  recursiveAttrs = mkOption {
    default = {};
    type = types.nullOr (types.attrs // {
      merge = loc: foldl' (res: def: recursiveUpdate res def.value) {};
    });
  };
in {
  ###### interface
  options = {
    services.telegraf = {

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
  config.services.telegraf.extraConfig = {
    global_tags = cfg.globalTags;
    inherit (cfg) agent aggregators inputs outputs processors;
  };
}
