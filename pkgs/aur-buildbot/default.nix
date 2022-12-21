{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "aur-buildbot";
  version = "2022-12-09";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    rev = "6695417c21c95401ee4896ad2ec56953640a969b";
    hash = "sha256-l40JSdgsyYVQ+xGsJU04IYmP9D9ZevyV4ejogmVRJNE=";
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
