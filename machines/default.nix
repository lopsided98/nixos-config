{ hostSystems ? [ "x86_64-linux" "aarch64-linux" "armv7l-linux" "armv6l-linux" ]
, buildSystem ? null
, modules ? [] }:
with import <nixpkgs/lib>;
let
  # Evaluate the configuration for a machine
  callMachine = path: system: import <nixpkgs/nixos/lib/eval-config.nix> {
    modules = [ path ({
      nixpkgs = if buildSystem == null then {
        localSystem.system = system;
      } else {
        crossSystem.system = system;
        localSystem.system = buildSystem;
      };
    }) ] ++ modules;
  };

  realSystem = n: if n.crossSystem != null then n.crossSystem.system else n.localSystem.system;
# Filter out machines with systems that are not supported
in filterAttrs (m: c: builtins.elem (realSystem c.config.nixpkgs) hostSystems) {
  "HP-Z420" = callMachine ./HP-Z420 "x86_64-linux";
  "Dell-Optiplex-780" = callMachine ./Dell-Optiplex-780 "x86_64-linux";
  "ODROID-XU4" = callMachine ./ODROID-XU4 "armv7l-linux";
  "ragazza" = callMachine ./ragazza "armv6l-linux";
  "RasPi2" = callMachine ./RasPi2 "armv7l-linux";
  "Rock64" = callMachine ./Rock64 "aarch64-linux";
  "RockPro64" = callMachine ./RockPro64 "aarch64-linux";
  "Roomba" = callMachine ./Roomba "aarch64-linux";
  "octoprint" = callMachine ./octoprint "aarch64-linux";
  "KittyCop" = callMachine ./KittyCop "armv6l-linux";
  "AudioRecorder1" = callMachine ./AudioRecorder1 "armv6l-linux";
  "AudioRecorder2" = callMachine ./AudioRecorder2 "armv6l-linux";
  "AudioRecorder3" = callMachine ./AudioRecorder3 "armv6l-linux";
  "AudioRecorder4" = callMachine ./AudioRecorder4 "armv6l-linux";
  # 5-8 are not included because they would just waste time, since I rarely
  # update them and usually just generate an SD image
  "maine-pi" = callMachine ./maine-pi "armv6l-linux";
  "atomic-pi" = callMachine ./atomic-pi "x86_64-linux";
}
