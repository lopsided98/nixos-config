{ localpkgs ? ../.,
  nixpkgs ? <nixpkgs>,
  hostSystems ? [ "x86_64-linux" "armv5tel-linux" "armv6l-linux" "armv7l-linux" "aarch64-linux" ],
  buildSystem ? null }:
with (import <nixpkgs/pkgs/top-level/release-lib.nix> { supportedSystems = hostSystems; });
let
  fullSystems = lib.intersectLists [ "x86_64-linux" "aarch64-linux" ] hostSystems;

  machines = import (localpkgs + "/machines") {
    inherit hostSystems buildSystem;
    modules = lib.singleton {
      system.nixos = lib.optionalAttrs (nixpkgs ? shortRev) (let
        revision = builtins.substring 0 7 nixpkgs.rev;
      in {
        inherit revision;
        versionSuffix = ".git.${revision}";
      });
    };
  };
in mapTestOn {
  # Fancy shortcut to generate one attribute per supported platform.
  dnsupdate = fullSystems;
  tinyssh = fullSystems;
  nixos-secrets = fullSystems;

  linuxPackages_latest.tmon = fullSystems;
  linuxPackages.tmon = fullSystems;
} // lib.optionalAttrs (lib.elem "armv7l-linux" hostSystems) {
  inherit (pkgs.pkgsCross.armv7l-hf-multiplatform)
    ubootRaspberryPi2
    ubootOdroidXU3;
} // lib.optionalAttrs (lib.elem "aarch64-linux" hostSystems) {
  inherit (pkgs.pkgsCross.aarch64-multiplatform)
    ubootOdroidC2
    ubootRaspberryPi3_64bit
    ubootRock64
    ubootRockPro64;
} // {
  machines = lib.mapAttrs (name: c: c.config.system.build.toplevel) machines;
}
