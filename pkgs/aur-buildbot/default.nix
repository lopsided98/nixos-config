{ stdenv, lib, fetchFromGitHub }: let
  commit = "98b6e2d89bc5323a3e0b391b0d594e22bd9a8325";
in stdenv.mkDerivation {
  name = "aur-buildbot-${lib.substring 0 7 commit}";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    rev = commit;
    sha256 = "03bqjxhx8pay3wwbsz7mjjmj68g36297g9hl3s89jn6d8p2awhl6";
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
    homepage = https://github.com/lopsided98/aur-buildbot;
    license = licenses.gpl3;
  };
}
