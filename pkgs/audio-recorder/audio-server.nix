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
        sha256 = "0beb08ff6bd861eeec324d07628a7c988997e87cae0a4ae114086f990f99993a";
      };
    };
  };
})
