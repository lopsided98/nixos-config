{ stdenv, lib, fetchFromGitHub, bash }: let
  commit = "c65ee5262cf8681258b675ed05609ddf81820d81";
in stdenv.mkDerivation {
  name = "aur-buildbot-${lib.substring 0 7 commit}";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    rev = commit;
    sha256 = "0x6ga2ppmz7ygidvqi2sl4vadvsyv3na4609q5i02jgnvxhb8cwm";
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
