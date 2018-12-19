{ callPackage, defaultCrateOverrides, fetchurlBoot, grpc, alsaLib, perl, cmake, pkgconfig }:

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
      src = fetchurlBoot {
        name = "audio_server-${oldAttrs.version}.tar.gz";
        url = "https://hydra.benwolsieffer.com/job/audio-recorder/release/audio-server.tarball/latest/download/1";
        sha256 = "f12cf521298168442f2a94d334f9c31c127ddb4d6e7b9fbe94dd036b5ffdab17";
      };
      extraRustcOpts = [ "--edition=2018" ];
    };
  };
})
