{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.syncoid;

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

    recursive = mkOption {
      description = "Whether to recursively snapshot dataset children";
      type = types.nullOr types.bool;
      default = null;
    };

    processChildrenOnly = mkOption {
      description = "Whether to only snapshot child datasets if recursing";
      type = types.nullOr types.bool;
      default = null;
    };

    autoprune = mkOption {
      type = types.nullOr types.bool;
      default = null;
    };

    autosnap = mkOption {
      type = types.nullOr types.bool;
      default = null;
    };

    minPercentFree = mkOption {
      type = types.nullOr percentType;
      default = null;
    };
  };

  datasetOptions = commonOptions // {
    useTemplate = mkOption {
      description = "Names of the templates to use for this dataset";
      type = types.nullOr (types.listOf (types.enum (attrNames cfg.templates)));
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

      ${configBoolPrint v.recursive "recursive"}
      ${configBoolPrint v.processChildrenOnly "process_children_only"}
      ${configBoolPrint v.autoprune "autoprune"}
      ${configBoolPrint v.autosnap "autosnap"}
      ${configPrint v.minPercentFree "min_percent_free"}

      ${optionalString ((v.useTemplate or null) != null) ''
        use_template = ${concatStringsSep "," v.useTemplate}
      ''};
    '') blocks);

  configFile = ''
    ${configBlocks cfg.datasets ""}

    ${configBlocks cfg.templates "template_"}
  '';

  configDir = pkgs.runCommand "sanoid-config" {} '' 
    mkdir -p "$out"
    # Sanoid requires a default configuration file, so symlink it from the package
    ln -s "${pkgs.sanoid}/conf/sanoid.defaults.conf" "$out"
    ln -s "${pkgs.writeText "sanoid.conf" configFile}" "$out/sanoid.conf"
  '';

in {

    # Interface

    options.services.syncoid = {
      enable = mkEnableOption "Syncoid ZFS synchronization service";

      interval = mkOption {
        type = types.str;
        default = "hourly";
        example = "*-*-* *:15:00";
        description = ''
          Run syncoid at this interval. The default is to run hourly.

          The format is described in
          <citerefentry><refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum></citerefentry>.
        '';
      };
      
      user = mkOption { 
        type = types.str;
        default = "root";
        example = "backup";
        description = ''
          The user for the service. ZFS priveledge delegation must be set up to
          use a user other than root.
        '';
      };
      
      sshKey = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          SSH private key file to use to login to remote system. Can be 
          overridden in individual commands.
        '';
      };
      
      defaultArguments = mkOption { 
        type = types.str;
        default = "";
        example = "--no-sync-snap";
        description = ''
          Arguments to add to every syncoid command, unless disabled for that 
          command.
        '';
      };

      commands = mkOption {
        type = types.listOf (types.submodule {
          options = {
            source = mkOption {
              type = types.str;
              description = ''
                Source ZFS dataset. Can be either local or remote.
              '';
            };
            
            target = mkOption {
              type = types.str;
              description = ''
                Target ZFS dataset. Can be either local or remote.
              '';
            };
            
            recursive = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether to also transfer child datasets.
              '';
            };
            
            sshKey = mkOption {
              type = types.nullOr types.path;
              default = cfg.sshKey;
              description = ''
                SSH private key file to use to login to remote system.
              '';
            };
            
            useDefaultArguments = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether to use the default arguments for this command.
              '';
            };
          
            extraArguments = mkOption { 
              type = types.str;
              default = "";
              example = "--sshport 2222";
              description = ''
                Extra syncoid arguments.
              '';
            };
          };
        });
        default = [];
        description = ''
          Syncoid commands to run.
        '';
      };

    };

    # Implementation

    config = mkIf cfg.enable {

      systemd.services.syncoid = {
        description = "Syncoid ZFS synchronization service";
        unitConfig = {
          After = "zfs.target";
        };
        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          ExecStart = pkgs.writeScript "syncoid-service" ''
            #!${pkgs.stdenv.shell}
            ${concatMapStringsSep "\n" (c: ''
              ${pkgs.sanoid}/bin/syncoid \
                ${optionalString c.useDefaultArguments cfg.defaultArguments} \
                ${optionalString c.recursive "-r"} \
                ${optionalString (c.sshKey != null) "--sshkey \"${c.sshKey}\""} \
                ${c.extraArguments} ${c.source} ${c.target}
            '') cfg.commands}
          '';
        };
      };

      systemd.timers.syncoid = {
        description = "Syncoid timer";
        partOf = [ "syncoid.service" ];
        wantedBy = [ "timers.target" ];
        timerConfig.OnCalendar = cfg.interval;
      };
    };
  }
