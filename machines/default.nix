{ hostSystems ? [ "x86_64-linux" "armv7l-linux" ], ... }:
with import <nixpkgs/lib>;
let
  # Evaluate the configuration for a machine
  callMachine = path: system: import <nixpkgs/nixos/lib/eval-config.nix> {
    modules = [ {  _module.args = { inherit system; }; } path ];
    inherit system;
  };

  realSystem = n: if n.crossSystem != null then n.crossSystem.system else n.localSystem.system;
# Filter out machines with systems that are not supported
in filterAttrs (m: c: builtins.elem (realSystem c.config.nixpkgs) hostSystems) {
  "HP-Z420" = callMachine ./HP-Z420 "x86_64-linux";
  "Dell-Optiplex-780" = callMachine ./Dell-Optiplex-780 "x86_64-linux";
  "ODROID-XU4" = callMachine ./ODROID-XU4 "armv7l-linux";
  "RasPi2" = callMachine ./RasPi2 "armv7l-linux";
  "Rock64" = callMachine ./Rock64 "aarch64-linux";
  "Roomba" = callMachine ./Roomba "aarch64-linux";
  "KittyCop" = callMachine ./KittyCop "armv6l-linux";
  "AudioRecorder1" = callMachine ./AudioRecorder1 "armv6l-linux";
  "AudioRecorder2" = callMachine ./AudioRecorder2 "armv6l-linux";
  "AudioRecorder3" = callMachine ./AudioRecorder3 "armv6l-linux";
  "AudioRecorder4" = callMachine ./AudioRecorder4 "armv6l-linux";
}
