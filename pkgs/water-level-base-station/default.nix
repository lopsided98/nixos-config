{ stdenv, callPackage, defaultCrateOverrides, fetchFromGitHub, dbus
, pkgconfig }:

((callPackage ./Cargo.nix {
  cratesIO = callPackage ./crates-io.nix {};
}).water_level_base_station {}).override (old: {
  crateOverrides = defaultCrateOverrides // {
    water_level_base_station = oldAttrs: {
      src = fetchFromGitHub {
        owner = "lopsided98";
        repo = "WaterLevelMonitor";
        rev = "9d900df4a8ae30a5bdb976e28a4bb870452832d2";
        sha256 = "1291wal7hqrqdpbyz493r3cnyycz8jqyp2ajqsb573srzc1a14i9";
      };

      preConfigure = ''
        cd base_station
      '';

      postInstall = ''
        # Results in a huge closure otherwise
        rm -rf $out/lib
      '';
    };
  };
})
