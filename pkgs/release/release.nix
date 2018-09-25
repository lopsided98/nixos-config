{ localpkgs ? ../..,
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

in {
  inherit (pkgs)
    dnsupdate
    aur-buildbot
    hacker-hats
    tinyssh
    tinyssh-convert
    sanoid;

  perlPackages = {
    inherit (pkgs.perlPackages)
      ConfigIniFiles;
  };

  linuxPackages_latest = {
    inherit (pkgs.linuxPackages_latest)
      tmon;
  };

  linuxPackages = {
    inherit (pkgs.linuxPackages)
      tmon;
  };

} // mapTestOn {

  # Fancy shortcut to generate one attribute per supported platform.
  dnsupdate = hostSystems;
  aur-buildbot = hostSystems;
  hacker-hats = hostSystems;
  tinyssh = hostSystems;
  tinyssh-convert = hostSystems;
  sanoid = hostSystems;
  libcreate = hostSystems;

  perlPackages = {
    ConfigIniFiles = hostSystems;
  };

  python3Packages = {
    pyalpm = hostSystems;
    xcgf = hostSystems;
    memoizedb = hostSystems;
    xcpf = hostSystems;
    aur = hostSystems;
    pyalsaaudio = hostSystems;
  };

  linuxPackages_latest = {
    tmon = hostSystems;
  };

  linuxPackages = {
    tmon = hostSystems;
  };

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
