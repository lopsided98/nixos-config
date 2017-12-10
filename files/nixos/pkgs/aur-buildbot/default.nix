{ stdenv, lib, fetchFromGitHub, bash }:
let
commit = "b7f50c129100bb3db1adf22413410eb2118f52a6";

in stdenv.mkDerivation {
  name = "aur-buildbot-${lib.substring 0 7 commit}";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    rev = commit;
    sha256 = "04bmlqcq7xc2zi89ry6da3asgpgcxq295s9sdr0jnjzaf2c5hycw";
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
