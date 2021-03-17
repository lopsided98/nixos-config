{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "aur-buildbot";
  version = "2021-03-16";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    rev = "18bf17b65313d739bafe819445dd005d4d5a2b41";
    sha256 = "sha256-lKd+xUmxi1QXMG5ILURewpahafj/p6d9WRRBVm9Uq/4=";
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
