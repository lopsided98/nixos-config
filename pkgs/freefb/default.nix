{ pkgs }:

(import ./Cargo.nix { inherit pkgs; }).rootCrate.build.overrideAttrs ({
  version, ...
}: {
  src = builtins.fetchurl "https://hydra.benwolsieffer.com/job/freefb/hydra/tarball/latest/download/1/freefb-${version}.tar.gz";
})
