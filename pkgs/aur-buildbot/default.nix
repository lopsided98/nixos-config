{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "aur-buildbot";
  version = "2021-02-05";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    rev = "41af44508c3ea3364582716fd0c1030e76a08d28";
    sha256 = "1557pa8g6ymhcv25czh4hznfybnr0bqh3kkciay3x731q852mvvb";
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
