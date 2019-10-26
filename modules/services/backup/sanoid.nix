{ config, stdenv, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.sanoid;

  percentType = (types.ints.between 0 100) // {
    name = "Percent";
  };

  commonOptions = {
    hourly = mkOption {
      description = "Number of hourly snapshots";
      type = types.nullOr types.ints.unsigned;
      default = null;
    };

    daily = mkOption {
      description = "Number of daily snapshots";
      type = types.nullOr types.ints.unsigned;
      default = null;
    };

    monthly = mkOption {
      description = "Number of monthly snapshots";
      type = types.nullOr types.ints.unsigned;
      default = null;
    };

    yearly = mkOption {
      description = "Number of yearly snapshots";
      type = types.nullOr types.ints.unsigned;
      default = null;
    };

    autoprune = mkOption {
      description = "Whether to automatically prune old snapshots.";
      type = types.nullOr types.bool;
      default = null;
    };

    autosnap = mkOption {
      description = "Whether to automatically take snapshots.";
      type = types.nullOr types.bool;
      default = null;
    };

    extraConfig = mkOption {
      description = "Extra configuration for this template/dataset";
      type = types.lines;
      default = "";
    };
  };

  datasetOptions = commonOptions // {
    useTemplate = mkOption {
      description = "Names of the templates to use for this dataset";
      type = types.nullOr (types.listOf (types.enum (attrNames cfg.templates)));
      default = null;
    };

    recursive = mkOption {
      description = "Whether to recursively snapshot dataset children";
      type = types.nullOr (types.enum [ true false "zfs" ]);
      default = null;
    };

    processChildrenOnly = mkOption {
      description = "Whether to only snapshot child datasets if recursing";
      type = types.nullOr types.bool;
      default = null;
    };
  };

  configBoolPrint = value: name: optionalString (value != null) "${name} = ${if value then "yes" else "no"}";
  configPrint = value: name: optionalString (value != null) "${name} = ${toString value}";

  configBlocks = blocks: prefix:
    concatStringsSep "\n" (mapAttrsToList (d: v: ''
      [${prefix}${d}]
      ${configPrint v.hourly "hourly"}
      ${configPrint v.daily "daily"}
      ${configPrint v.monthly "monthly"}
      ${configPrint v.yearly "yearly"}

      ${configBoolPrint v.autoprune "autoprune"}
      ${configBoolPrint v.autosnap "autosnap"}

      ${optionalString ((v.useTemplate or null) != null) ''
        use_template = ${concatStringsSep "," v.useTemplate}
      ''}

      ${configBoolPrint (v.recursive or null) "recursive"}
      ${configBoolPrint (v.processChildrenOnly or null) "process_children_only"}
      ${v.extraConfig}
    '') blocks);

  configFile = ''
    ${configBlocks cfg.datasets ""}

    ${configBlocks cfg.templates "template_"}
  '';

  configDir = pkgs.runCommand "sanoid-config" {} ''
    mkdir -p "$out"
    ln -s "${pkgs.writeText "sanoid.conf" configFile}" "$out/sanoid.conf"
  '';

in {

    # Interface

    options.services.sanoid = {
      enable = mkEnableOption "Sanoid ZFS snapshotting service";

      interval = mkOption {
        type = types.str;
        default = "hourly";
        example = "daily";
        description = ''
          Run sanoid at this interval. The default is to run hourly.

          The format is described in
          <citerefentry><refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum></citerefentry>.
        '';
      };

      datasets = mkOption {
        type = types.attrsOf (types.submodule {
          options = datasetOptions;
        });
        default = {};
        description = ''
          Datasets to snapshot
        '';
      };

      templates = mkOption {
        type = types.attrsOf (types.submodule {
          options = commonOptions;
        });
        default = {};
        description = "Templates for datasets";
      };

      extraArgs = mkOption {
        description = "Extra arguments to pass to sanoid";
        type = types.separatedString " ";
        default = "";
      };
    };

    # Implementation

    config = mkIf cfg.enable {
      systemd.services.sanoid = {
        description = "Sanoid snapshot service";
        serviceConfig.ExecStart = "${pkgs.sanoid}/bin/sanoid --cron --configdir=${configDir} ${cfg.extraArgs}";
        after = [ "zfs.target" ];
        startAt = cfg.interval;
      };
    };
  }
