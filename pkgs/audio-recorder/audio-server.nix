{ stdenv, pkgs, callPackage, defaultCrateOverrides, alsaLib, pkgconfig }:

((import ./Cargo.nix { inherit pkgs; }).rootCrate.build.overrideAttrs ({
  version, ...
}: {
  # Use fetchurlBoot to use netrc file for authentication
  src = stdenv.fetchurlBoot {
    name = "audio_server-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/audio-recorder/release/audio-server.tarball/latest/download/1";
    sha256 = "1ys02zykcf0g6d7l4djf0xrf8451ks30shb1l5fphp1zv96mwk4s";
  };
})).override (old: {
  crateOverrides = defaultCrateOverrides // {
    alsa-sys = oldAttrs: {
      nativeBuildInputs = [ pkgconfig ];
      buildInputs = [ alsaLib ];
    };
  };
})
