# Addon for the telegraf module to allow the configuration to be merged
# recursively
{ config, lib, ... }: with lib; let
  cfg = config.services.telegraf;

  recursiveAttrs = mkOption {
    default = {};
    type = types.nullOr (types.attrs // {
      merge = loc: foldl' (res: def: recursiveUpdate res def.value) {};
    });
  };
in {
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

  config.services.telegraf.extraConfig = {
    global_tags = cfg.globalTags;
    inherit (cfg) agent aggregators inputs outputs processors;
  };
}
