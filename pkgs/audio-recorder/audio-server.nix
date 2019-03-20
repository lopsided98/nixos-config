{ stdenv, callPackage, defaultCrateOverrides, grpc, alsaLib, perl, cmake, pkgconfig }:

((callPackage ./Cargo.nix {
  cratesIO = callPackage ./crates-io.nix {};
}).audio_server {}).override (old: {
  crateOverrides = defaultCrateOverrides // {
    alsa-sys = oldAttrs: {
      nativeBuildInputs = [ pkgconfig ];
      buildInputs = [ alsaLib ];
    };
    grpcio-sys = oldAttrs: {
      nativeBuildInputs = [ perl cmake ];
      buildInputs = [ grpc ];
    };
    audio_server = oldAttrs: {
      # Use fetchurlBoot to use netrc file for authentication
      src = stdenv.fetchurlBoot {
        name = "audio_server-${oldAttrs.version}.tar.gz";
        url = "https://hydra.benwolsieffer.com/job/audio-recorder/release/audio-server.tarball/latest/download/1";
        sha256 = "930f2d7f64e5a60932bed51a22c3f59762508d1cd0df393b43e5bae9dbf0ec75";
      };

      postInstall = ''
        # Results in a huge closure otherwise
        rm -rf $out/lib
      '';
    };
  };
})
