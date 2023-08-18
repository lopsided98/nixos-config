{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "aur-buildbot";
  version = "2022-12-09";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    rev = "b1385268c24551ceb509bb4ed21a0ff8dafd3560";
    hash = "sha256-mG2KJ4mKgEfxYXTZNIUvogdJJ6QmEwwk0ecXRtsvGS4=";
  };

  installPhase = ''
    mkdir "$out"
    cp -a * "$out"
  '';

  postFixup = ''
    substituteInPlace "$out/worker/build-package" \
      --replace /bin/bash "${stdenv.shell}" \
  '';

  # Don't patch the docker entrypoint script
  dontPatchShebangs = true;

  meta = with lib; {
    description = "Buildbot configuration for building Arch Linux AUR packages";
    homepage = "https://github.com/lopsided98/aur-buildbot";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lopsided98 ];
  };
}
