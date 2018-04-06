{ localpkgs ? ../.., 
  nixpkgs ? <nixpkgs>,
  buildSystems ? [ "x86_64-linux" "armv7l-linux" "aarch64-linux" ],
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
        rm configuration.nix
        cp -r . $out
      '';
    };
  in pkgs.releaseTools.channel (args // { inherit src; });

  jobs = {
    inherit (pkgs) 
      dnsupdate
      aur-buildbot
      pacman
      muximux
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
    pacman = hostSystems;
    muximux = hostSystems;
    hacker-hats = hostSystems;
    tinyssh = hostSystems;
    tinyssh-convert = hostSystems;
    sanoid = hostSystems;
    
    perlPackages = {
      ConfigIniFiles = hostSystems;
    };

    linuxPackages_latest = {
      tmon = hostSystems;
    };
    
    linuxPackages = {
      tmon = hostSystems;
    };
   
  } /*// (lib.optionalAttrs (builtins.elem "armv7l-linux" hostSystems) ( {
    inherit (pkgs) linux_odroid_xu4;
    
    linuxPackages_odroid_xu4 = {
      inherit (pkgs.linuxPackages)
        tmon;
    };
  } // mapTestOnCross (lib.systems.examples.armv7l-hf-multiplatform // { platform = machines."ODROID-XU4".config.nixpkgs.config.platform; }) {
    linux_odroid_xu4 = [ "x86_64-linux" ];
    
    linuxPackages_odroid_xu4 = {
      tmon = [ "x86_64-linux" ];
    };
  }))*/;
in jobs // {
  channels = {
    machines = lib.mapAttrs (name: c: channelWithNixpkgs {
      inherit name;
      constituents = [ c.config.system.build.toplevel ];
      src = localpkgs;
    }) machines;
  };
}
