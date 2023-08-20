{ lib, writeShellScript, nix, user-env }:

writeShellScript "${lib.getName user-env}-update" ''
  ${lib.escapeShellArg nix}/bin/nix-env --set ${lib.escapeShellArg user-env}
''
