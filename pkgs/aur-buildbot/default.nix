{ stdenv, lib, fetchFromGitHub, bash }: let
  commit = "594b475c7080b5c54ca0d27e9a21fe118d4831b0";
in stdenv.mkDerivation {
  name = "aur-buildbot-${lib.substring 0 7 commit}";

  src = fetchFromGitHub {
    owner = "lopsided98";
    repo = "aur-buildbot";
    rev = commit;
    sha256 = "0rpvc42fqh4jdh7ly15qhzy2w5s1vbhdafvivdml9csb9d60jwm9";
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
