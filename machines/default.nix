{ lib
, hostSystems ? [ "x86_64-linux" "aarch64-linux" "armv7l-linux" "armv6l-linux" "armv5tel-linux" ]
, buildSystem ? null
, modules ? [] }:
let
  # Evaluate the configuration for a machine
  callMachine = path: system: if builtins.elem system hostSystems
    then lib.nixosSystem {
      modules = [ path ({
        local.system = {
          hostSystem.system = system;
          buildSystem = lib.mkIf (buildSystem != null) { system = buildSystem; };
        };
      }) ] ++ modules;
    }
    else null;

# Filter out machines with systems that are not supported
in lib.filterAttrs (m: c: c != null) {
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
  "AudioRecorder5" = callMachine ./AudioRecorder5 "armv6l-linux";
  "AudioRecorder6" = callMachine ./AudioRecorder6 "armv6l-linux";
  "AudioRecorder7" = callMachine ./AudioRecorder7 "armv6l-linux";
  "AudioRecorder8" = callMachine ./AudioRecorder8 "armv6l-linux";
  "maine-pi" = callMachine ./maine-pi "armv6l-linux";
  "atomic-pi" = callMachine ./atomic-pi "x86_64-linux";
  "omnitech" = callMachine ./omnitech "armv5tel-linux";
}
