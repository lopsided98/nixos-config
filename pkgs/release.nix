{ localpkgs ? ../.,
  nixpkgs ? <nixpkgs>,
  buildSystems ? [ "x86_64-linux" "armv6l-linux" "armv7l-linux" "aarch64-linux" ],
  hostSystems ? [ "x86_64-linux" ] }:
with (import <nixpkgs/pkgs/top-level/release-lib.nix> { supportedSystems = buildSystems; });
let
  machines = import (builtins.toPath "${localpkgs}/machines") { inherit hostSystems; };

  channelWithNixpkgs = { name, src, ... }@args: let
    nixpkgsRevCount = nixpkgs.revCount or 12345;
    nixpkgsShortRev = nixpkgs.shortRev or "abcdefg";
    nixpkgsVersion = "pre${toString nixpkgsRevCount}.${nixpkgsShortRev}-localpkgs";

    src = pkgs.stdenv.mkDerivation {
      inherit (args) name src;
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        cp -r --no-preserve=ownership "${nixpkgs}/" nixpkgs
        # denote nixpkgs versioning
        chmod -R u+w nixpkgs
        if [ -e nixpkgs/.version-suffix ]; then
          echo "echo \"$(cat nixpkgs/.version-suffix)\"" > nixpkgs/nixos/modules/installer/tools/get-version-suffix
        else
          echo -n "${nixpkgsVersion}" > nixpkgs/.version-suffix
        fi
        if [ ! -e nixpkgs/.git-revision ]; then
          echo -n ${nixpkgs.rev or nixpkgsShortRev} > nixpkgs/.git-revision
        fi
        cp -r . $out
      '';
    };
  in pkgs.releaseTools.channel (args // { inherit src; });

in mapTestOn {
  # Fancy shortcut to generate one attribute per supported platform.
  dnsupdate = hostSystems;
  libcreate = hostSystems;
  sanoid = hostSystems;
  tinyssh = hostSystems;
  tinyssh-convert = hostSystems;

  python3Packages = {
    aur = hostSystems;
    memoizedb = hostSystems;
    pyalpm = hostSystems;
    pyalsaaudio = hostSystems;
    upnpclient = hostSystems;
    xcgf = hostSystems;
    xcpf = hostSystems;
  };
  
  linuxPackages_latest.tmon = hostSystems;
  linuxPackages.tmon = hostSystems;
} // lib.optionalAttrs (lib.elem "armv7l-linux" hostSystems) {
  inherit (pkgs.pkgsCross.armv7l-hf-multiplatform)
    ubootRaspberryPi2
    ubootOdroidXU3;
} // lib.optionalAttrs (lib.elem "aarch64-linux" hostSystems) {
  inherit (pkgs.pkgsCross.aarch64-multiplatform)
    ubootRaspberryPi3_64bit
    ubootRock64
    ubootRockPro64;
} // {
  machines = lib.mapAttrs (name: c: {
    channel = channelWithNixpkgs {
      inherit name;
      constituents = [ c.config.system.build.toplevel ];
      src = localpkgs;
    };
  } /*
   # We don't build SD images automatically because there are too many of them
   // lib.optionalAttrs (c.config.system.build ? sdImage) {
    inherit (c.config.system.build) sdImage;
  } */) machines;
}
