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
in lib.filterAttrs (m: c: c != null) ({
  "atomic-pi" = callMachine ./atomic-pi "x86_64-linux";
  "bone" = callMachine ./bone "armv7l-linux";
  "bone-black" = callMachine ./bone-black "armv7l-linux";
  "HP-Z420" = callMachine ./HP-Z420 "x86_64-linux";
  "KittyCop" = callMachine ./KittyCop "armv6l-linux";
  "maine-pi" = callMachine ./maine-pi "armv6l-linux";
  "octoprint" = callMachine ./octoprint "aarch64-linux";
  "ODROID-XU4" = callMachine ./ODROID-XU4 "armv7l-linux";
  "omnitech" = callMachine ./omnitech "armv5tel-linux";
  "p-3400" = callMachine ./p-3400 "x86_64-linux";
  "ragazza" = callMachine ./ragazza "armv6l-linux";
  "RasPi2" = callMachine ./RasPi2 "armv7l-linux";
  "Rock64" = callMachine ./Rock64 "aarch64-linux";
  "RockPro64" = callMachine ./RockPro64 "aarch64-linux";
  "Roomba" = callMachine ./Roomba "aarch64-linux";
} //
lib.listToAttrs (map (device:
  lib.nameValuePair
    "AudioRecorder${toString device}"
    (callMachine (import ./AudioRecorder { inherit device; }) "armv6l-linux")
) (lib.genList (i: i + 1) 10)))
