{ stdenv, pkgs, pkgconfig, dbus, fetchFromGitHub }:

(import ./Cargo.nix { inherit pkgs; }).rootCrate.build.overrideAttrs ({
  preConfigure ? "", ...
}: {
  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "WaterLevelMonitor";
    rev = "9d900df4a8ae30a5bdb976e28a4bb870452832d2";
    sha256 = "1291wal7hqrqdpbyz493r3cnyycz8jqyp2ajqsb573srzc1a14i9";
  };

  preConfigure = ''
    cd base_station
  '' + preConfigure;
})
