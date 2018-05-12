{ stdenv, lib, fetchFromGitHub, bash }: let
  commit = "1fdcc5edc8b1c6f7bdafd8d7d04271696d486d34";
in stdenv.mkDerivation {
  name = "aur-buildbot-${lib.substring 0 7 commit}";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    rev = commit;
    sha256 = "1kgckk5l5mjchl7q30hg58bx79wlscdjqjgc9rzc4zcgpxd5p1vq";
  };
  
  installPhase = ''
    mkdir "$out"
    cp -a * "$out"
  '';
  
  postFixup = ''
    substituteInPlace "$out/worker/build-package" \
      --replace /bin/bash "${bash}/bin/bash" \
  '';
  
  # Don't patch the docker entrypoint script
  dontPatchShebangs = true;

  meta = with lib; {
    description = "Buildbot configuration for building Arch Linux AUR packages";
    homepage = https://github.com/lopsided98/aur-buildbot;
    license = licenses.gpl3;
  };
}
