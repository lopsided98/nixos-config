{ hostSystems ? [ "x86_64-linux" "armv7l-linux" ], ... }:
with import <nixpkgs/lib>;
let
  # Evaluate the configuration for a machine
  callMachine = path: system: import <nixpkgs/nixos/lib/eval-config.nix> {
    modules = [ {  _module.args = { inherit system; }; } path ];
    inherit system;
  };
# Filter out machines with systems that are not supported
in filterAttrs (m: c: builtins.elem c.config.nixpkgs.system hostSystems) {
  "HP-Z420" = callMachine ./HP-Z420/configuration.nix "x86_64-linux";
  "Dell-Optiplex-780" = callMachine ./Dell-Optiplex-780/configuration.nix "x86_64-linux";
  "ODROID-XU4" = callMachine ./ODROID-XU4/configuration.nix "armv7l-linux";
  "RasPi2" = callMachine ./RasPi2/configuration.nix "armv7l-linux";
}
