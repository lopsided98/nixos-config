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
        sha256 = "70e39caef8c8efcce402252e8ca630a446b615feef7c65b8f80eb2fc9f8e9d3b";
      };
      extraRustcOpts = [ "--edition=2018" ];

      postInstall = ''
        # Results in a huge closure otherwise
        rm -rf $out/lib
      '';
    };
  };
})
