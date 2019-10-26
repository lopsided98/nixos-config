{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.syncoid;
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
          The user for the service. ZFS privilege delegation must be configured
          to use a user other than root.
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
        type = types.separatedString " ";
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
              type = types.separatedString " ";
              default = "";
              example = "--sshport 2222";
              description = ''
                Extra syncoid arguments.
              '';
            };
          };
        });
        default = [];
        description = "Syncoid commands to run.";
      };
    };

    # Implementation

    config = mkIf cfg.enable {
      systemd.services.syncoid = {
        description = "Syncoid ZFS synchronization service";
        script = concatMapStringsSep "\n" (c: ''
          ${pkgs.sanoid}/bin/syncoid \
            ${optionalString c.useDefaultArguments cfg.defaultArguments} \
            ${optionalString c.recursive "-r"} \
            ${optionalString (c.sshKey != null) "--sshkey \"${c.sshKey}\""} \
            ${c.extraArguments} ${c.source} ${c.target}
        '') cfg.commands;
        after = [ "zfs.target" ];
        serviceConfig.User = cfg.user;
        startAt = cfg.interval;
      };
    };
  }
