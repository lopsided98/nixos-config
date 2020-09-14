{ stdenv, pkgs }:

(import ./Cargo.nix { inherit pkgs; }).rootCrate.build.overrideAttrs ({
  version, ...
}: {
  # Use fetchurlBoot to use netrc file for authentication
  src = stdenv.fetchurlBoot {
    url = "https://hydra.benwolsieffer.com/build/427916/download/1/freefb-${version}.tar.gz";
    sha256 = "080nq8abz48ay61al36g4622az0wwx4s5x57qxijdii10fw4by4n";
  };
})
