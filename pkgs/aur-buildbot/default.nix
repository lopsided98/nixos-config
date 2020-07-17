{ stdenv, lib, fetchFromGitHub }: let
  rev = "254f24a653cefa7b674b4d5576cf6cb655cbbadd";
in stdenv.mkDerivation {
  name = "aur-buildbot-${lib.substring 0 7 rev}";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    inherit rev;
    sha256 = "09x82j0yzgrci4yia794sxb4z2c9kcfz7dxq096d0fl22iq0cg6z";
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
