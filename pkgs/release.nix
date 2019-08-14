{ localpkgs ? ../.,
  nixpkgs ? <nixpkgs>,
  hostSystems ? [ "x86_64-linux" "armv6l-linux" "armv7l-linux" "aarch64-linux" ],
  buildSystem ? null }:
with (import <nixpkgs/pkgs/top-level/release-lib.nix> { supportedSystems = hostSystems; });
let
  machines = import (builtins.toPath "${localpkgs}/machines") { inherit hostSystems buildSystem; };

  channelTarballWithNixpkgs = { src, ... }@args: let
    nixpkgsRevCount = nixpkgs.revCount or 12345;
    nixpkgsShortRev = nixpkgs.shortRev or "abcdefg";
    nixpkgsVersion = "pre${toString nixpkgsRevCount}.${nixpkgsShortRev}-localpkgs";
  in pkgs.stdenv.mkDerivation ({
      name = "nixexprs.tar.xz";

      phases = [ "installPhase" ];

      installPhase = ''
        mkdir tar
        cd tar

        cp -Tr --no-preserve=ownership "$src" .
        cp -r --no-preserve=ownership "${nixpkgs}/" nixpkgs
        chmod -R u+w .

        touch .update-on-nixos-rebuild

        if [ -e nixpkgs/.version-suffix ]; then
          echo "echo \"$(cat nixpkgs/.version-suffix)\"" > nixpkgs/nixos/modules/installer/tools/get-version-suffix
        else
          echo -n "${nixpkgsVersion}" > nixpkgs/.version-suffix
        fi
        if [ ! -e nixpkgs/.git-revision ]; then
          echo -n ${nixpkgs.rev or nixpkgsShortRev} > nixpkgs/.git-revision
        fi

        tar cJf "$out" \
          --owner=0 --group=0 --mtime="1970-01-01 00:00:00 UTC" \
          --transform='s!^\.!nixexprs!' .
      '';
    } // args);

  channel = { tarball, constituents ? [], meta ? {}, ... }@args:
    pkgs.stdenv.mkDerivation ({
      preferLocalBuild = true;
      _hydraAggregate = true;

      phases = [ "installPhase" ];

      installPhase = ''
        mkdir -p $out/{tarballs,nix-support}
        ln -s '${tarball}' "$out/tarballs/nixexprs.tar.xz"
        echo "channel - $out/tarballs/nixexprs.tar.xz" > "$out/nix-support/hydra-build-products"
        echo $constituents > "$out/nix-support/hydra-aggregate-constituents"
        # Propagate build failures.
        for i in $constituents; do
          if [ -e "$i/nix-support/failed" ]; then
            touch "$out/nix-support/failed"
          fi
        done
      '';

      meta = meta // {
        isHydraChannel = true;
      };
    } // removeAttrs args [ "meta" ]);

  localpkgsTarball = channelTarballWithNixpkgs {
      src = localpkgs;
  };

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
    channel = channel {
      inherit name;
      constituents = [ c.config.system.build.toplevel ];
      tarball = localpkgsTarball;
    };
  }) machines;
}
