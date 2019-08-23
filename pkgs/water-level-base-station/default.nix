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
        rev = "98a3aaf5b9cafc32df1a5f181737329488b9a632";
        sha256 = "0bvmqkwpdwwdvgcn3bwpw8560ai9lk73s7wr43gly7kr45hh53lb";
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
