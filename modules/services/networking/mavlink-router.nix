{ config, lib, pkgs, ... }: let
  cfg = config.services.mavlink-router;

  # Based on lib.generators.toGitINI, but without quoting of subsection headers
  # and string values.
  toConf = attrs:
    let
      mkSectionName = name:
        let
          sections = lib.strings.splitString "." name;
          section = builtins.head sections;
          subsections = builtins.tail sections;
          subsection = lib.concatStringsSep "." subsections;
        in if subsections == [ ]
        then name
        else "${section} ${subsection}";

      # generation for multiple ini values
      mkKeyValue = k: v:
        let mkKeyValue = lib.generators.mkKeyValueDefault { } " = " k;
        in lib.concatStringsSep "\n" (builtins.map (kv: "\t" + mkKeyValue kv) (lib.toList v));

      # converts { a.b.c = 5; } to { "a.b".c = 5; } for toINI
      flattenAttrs = let
        recurse = path: value:
          if builtins.isAttrs value && !lib.isDerivation value then
            lib.mapAttrsToList (name: value: recurse ([ name ] ++ path) value) value
          else if builtins.length path > 1 then {
            ${lib.concatStringsSep "." (lib.reverseList (builtins.tail path))}.${builtins.head path} = value;
          } else {
            ${builtins.head path} = value;
          };
      in attrs: lib.foldl lib.recursiveUpdate { } (lib.flatten (recurse [ ] attrs));

      toINI_ = lib.generators.toINI { inherit mkKeyValue mkSectionName; };
    in
      toINI_ (flattenAttrs attrs);

  settingsFormat = {
    type = with lib.types; let
      iniAtom = (pkgs.formats.ini { }).type/*attrsOf*/.functor.wrapped/*attrsOf*/.functor.wrapped;
    in attrsOf (attrsOf (either iniAtom (attrsOf iniAtom)));
    generate = name: value: pkgs.writeText name (toConf value);
  };
in {
  # Interface

  options.services.mavlink-router = {
    enable = lib.mkEnableOption "MAVLink Router";

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = {};
      example = {
        UartEndpoint.alpha = {
          Device = "/dev/ttyS0";
          Baud = 52000;
        };
      };
      description = lib.mdDoc ''
        MAVLink Router configuration, see:
        https://github.com/mavlink-router/mavlink-router/blob/master/examples/config.sample
      '';
    };
  };

  # Implementation

  config = lib.mkIf cfg.enable {
    systemd.packages = [ pkgs.mavlink-router ];

    systemd.services.mavlink-router = {
      wantedBy = [ "multi-user.target" ];
      environment.MAVLINK_ROUTERD_CONF_FILE = settingsFormat.generate "mavlink-router.conf" cfg.settings;
    };
  };
}
